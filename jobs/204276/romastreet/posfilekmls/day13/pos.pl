#!/usr/bin/perl
#
# vim: ft=perl:sts=4:sw=4:et:tw=78

use v5.36;
use experimental qw(builtin);
use builtin      qw(trim);
use File::Basename;

use Time::Local qw( timelocal_posix timegm_posix );
use POSIX;

use XML::Simple;

my $posdir
    = 'Y:\204000JOBS\204276_TMR_LGC_Fast_Rail_MLS\Insta360\MLS Rail\Roma Street Pos Files for Peter D';
my $postxt = 'pos.txt';

my $inc = 1.0;

my $secsinweek = 7 * 24 * 60 * 60;

open my $fh, '<', $postxt;

while (<$fh>) {

    my ( $mp4, $pos, $start, $end ) = map { trim $_ } split /,/;

    say "$mp4  $pos  $start  $end";

    my $basename = basename( $mp4, ".mp4" );
    my $kmlfile  = $basename . "-POS.kml";
    my $csvfile  = $basename . ".csv";
    my $posfile  = $posdir . '\\' . $pos;

    my ( $time, $lat, $lon, $gtime );
    my $mp4time = 0;
    my @data    = ();

    open my $posfh, '<', $posfile;
    for ( my $utime = $start; $utime <= $end; $utime += $inc ) {
        $gtime = unix2weeksecs($utime);

        #say "  $utime  $gtime";

        while (1) {
            my $line = <$posfh>;
            ( $time, $lat, $lon ) = split " ", $line;
            $time -= $secsinweek if $time >= $secsinweek;
            last                 if ( abs( $time - $gtime ) < 1 / 128 );
        }

        push @data, [ $mp4time, $utime, $lon, $lat ];
        say "$mp4time,$utime,$gtime,$time,$lat,$lon";
        $mp4time += $inc;
    }
    close $posfh;

    my @kmlframes = map {
        (   sub {
                my ( $pts, $time, $lon, $lat ) = @{$_};
                my ( $style, $desc );
                my $localtime = scalar localtime($time);
                my $name      = timestamp($pts);
                $style = 'good';
                $desc  = sprintf( "%s", $localtime );
                return [ $name, $lon, $lat, 0, $style, $desc ];
            }
        )->($_);
    } @data;

    my $href = 'http://maps.google.com/mapfiles/kml/shapes/rail.png';
    my $styles
        = [ [ 'good', 'ffaa00ff', $href ], [ 'bad', 'ff7f00ff', $href ] ];
    open OUT, '>', $kmlfile;
    print OUT kmlout( $basename . '-POS', $styles, \@kmlframes );
    close OUT;

}
close $fh;

######  end main/start subs

sub unix2weeksecs {
    my $unixtime = shift;

    state $gpsoffset  = timegm_posix( 0, 0, 0, 6, 0, 80 );
    state $leapsecs   = 18;
    state $secsinweek = 7 * 24 * 60 * 60;

    my $gpstime  = $unixtime - $gpsoffset + $leapsecs;
    my $gpsweek  = POSIX::floor( $gpstime / $secsinweek );
    my $weeksecs = $gpstime - $gpsweek * $secsinweek;
    return $weeksecs;
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

