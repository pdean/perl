#!/usr/bin/perl

my $deliverytext = '../delivery.txt';
my $filter       = 10;
my $exiftool     = 'exiftool';

use v5.36;
use experimental          qw(builtin);
use builtin               qw(trim);
use File::Path            qw(make_path remove_tree);
use File::Spec::Functions qw(catfile splitpath);
use POSIX                 qw(floor round);
use List::MoreUtils       qw(slideatatime);
use Cwd;
use XML::Simple;
use aliased 'Geo::Proj::CCT';

my $fh;    # file handles;

my ( $vol, $path, $cwd ) = splitpath getcwd;
open $fh, '<', $deliverytext;
my $deliverydir = trim <$fh>;
my $mp4file     = catfile $deliverydir, $cwd, $cwd . '.mp4';
my $csvfile     = catfile $deliverydir, $cwd, $cwd . '.csv';
my $jpegdir     = catfile $deliverydir, $cwd, 'jpeg';
remove_tree $jpegdir;
make_path $jpegdir;

# num,ts,ut,lon,lat,ch,os,seg,code,desc
my @frames;
open $fh, '<', $csvfile;
while (<$fh>) {
    chomp;
    push @frames, [ split /,/ ];
}

my $proj = CCT->create('+proj=longlat +ellps=GRS80');

my @tdist;
my $tdist = 0;
my $last;

my $it = slideatatime 1, 2, @frames;
while ( my @vals = $it->() ) {
    last if @vals != 2;
    my ( $n0,   $lon0, $lat0 ) = @{ $vals[0] }[ 0, 3, 4 ];
    my ( $n1,   $lon1, $lat1 ) = @{ $vals[1] }[ 0, 3, 4 ];
    my ( $dist, $fwd,  $rev )
        = @{ $proj->geod( [ $lon0, $lat0 ], [ $lon1, $lat1 ] ) };
    push @tdist, [ $n0, $tdist, mod( $fwd, 360 ) ];
    $tdist += $dist;
    $last = [ $n1, $tdist, mod( $rev, 360 ) ];
}
push @tdist, $last;

my %filter;
foreach (@tdist) {
    my ( $num, $tdist, $hdg ) = @{$_};
    my $closest = $filter * round( $tdist / $filter );
    my $x       = abs( $closest - $tdist );
    push @{ $filter{$closest} }, [ $x, $_ ];
}

my @filtered;
foreach ( sort { $a <=> $b } keys %filter ) {
    my @diff = @{ $filter{$_} };
    my $min  = ( sort { $a->[0] <=> $b->[0] } @diff )[0];
    my ( $num, $tdist, $hdg ) = @{ $min->[1] };
    my @frame = @{ $frames[$num] };
    push @frame, sprintf '%.0f', $hdg;
    push @filtered, [@frame];
}

say 'creating kml ...';
my @kmlframes = map {
    (   sub {
            my ($num,  $pts,         $time, $lon,
                $lat,  $ch,          $os,   $section,
                $code, $description, $hdg
            ) = @{$_};
            my ( $style, $desc );
            my $localtime = scalar localtime( round($time) );
            my $name      = timestamp($pts);
            $desc = sprintf 'frame %d', $num;
            if ( abs($os) > 25 ) {
                $style = 'bad';
                $desc .= sprintf '<br>%s', "No chainage";
            }
            else {
                $style = 'good';
                $desc .= sprintf '<br>%s<br>ch %.3f km<br>os %.0f',
                    $description, $ch / 1000, $os;
            }
            $desc .= sprintf '<br>%s<br>%s', $localtime, $time;
            $desc .= sprintf '<br><img src="frame-%04d.jpeg"/>', $num;
            return [ $name, $lon, $lat, 0, $style, $desc ];
        }
    )->($_);
} @filtered;

say 'writing kml ...';
my $href    = 'http://maps.google.com/mapfiles/kml/pal4/icon46.png';
my $styles  = [ [ 'good', 'ff00ff00', $href ], [ 'bad', 'ff7f00ff', $href ] ];
my $kmlfile = catfile $jpegdir, '00frames.kml';
open $fh, '>', $kmlfile;
print $fh kmlout( $cwd, $styles, \@kmlframes );

say 'writing jpegs ...';
foreach my $frame (@filtered) {
    my ( $num, $ts, $ut, $lon, $lat, $ch, $os, $seg, $code, $desc, $hdg )
        = @{$frame};
    my $file = catfile $jpegdir, sprintf 'frame-%04d.jpeg', $num;
    my $cmd;
    $cmd = 'ffmpeg';
    $cmd .= ' -y';
    $cmd .= " -ss $ts";
    $cmd .= " -i \"$mp4file\"";
    $cmd .= ' -frames:v 1';
    $cmd .= ' -update 1';
    $cmd .= ' -q:v 2';
    $cmd .= " \"$file\"";
    say $cmd;
    my $result = system $cmd;
    say "";

    $cmd = $exiftool;
    $cmd .= " -exif:GPSLatitude=$lat";
    $cmd .= " -exif:GPSLongitude=$lon";
    $cmd .= " -exif:GPSLatitudeRef=S";
    $cmd .= " -exif:GPSLongitudeRef=E";
    $cmd .= " -exif:GPSTrackRef=T";
    $cmd .= " -exif:GPSTrack=$hdg";
    $cmd .= " -exif:GPSHPositioningError=6.0";
    $cmd .= " -overwrite_original";
    $cmd .= " \"$file\"";
    say $cmd;
    $result = system $cmd;
    say "";
}

# end main
#
# subs

sub mod {
    my ( $x, $y ) = @_;
    return $x - floor( $x / $y ) * $y;
}

# timestamp
# seconds to hh:mm::ss.ss
# retains fraction
#

sub timestamp {
    my $secs = sprintf( "%0.2f", shift );
    my ( $int, $frac ) = split( '\.', $secs );
    return sprintf( "%02d:%02d:%02d.%s", ( gmtime($int) )[ 2, 1, 0 ], $frac );
}

# kmlout
#
# parameters:
#
# name of document
# list of styles
#     id, colour, url of icon
# list of points
#     id, lon, lat, rl, style, description

sub kmlout {
    my ( $name, $styles, $points )    = @_;
    my ( $Doc,  $Style,  $Placemark ) = ( [], [], [] );
    push @$Doc,
        {   name      => [$name],
            Style     => $Style,
            Placemark => $Placemark,
        };
    for my $style (@$styles) {
        my ( $id, $color, $href ) = @$style;
        push @$Style,
            {   id        => $id,
                IconStyle => [
                    {   Icon  => [ { href => [$href] } ],
                        color => [$color]
                    }
                ]
            };
    }
    for my $point (@$points) {
        my ( $name, $lon, $lat, $z, $style, $desc ) = @$point;
        push @$Placemark,
            {   name        => [$name],
                description => [$desc],
                styleUrl    => ["#$style"],
                Point       => [ { coordinates => ["$lon,$lat,$z"] } ],
            };
    }
    my $root = { Document => $Doc };
    return XMLout( $root, RootName => 'kml' );
}

# vim:ft=perl:sts=4:sw=4:et:tw=78
