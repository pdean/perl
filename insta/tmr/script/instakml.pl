#!/usr/bin/perl
# vim: ft=perl:sts=4:sw=4:et:tw=78

my $dirtxt   = 'mp4dir.txt';

my $logfile  = "log.csv";
my $exiftool = 'exiftool64';

use v5.36;
use experimental qw(builtin);
use builtin      qw(trim);
use File::Spec::Functions;
use File::Basename;
use Time::Local qw{timelocal_posix timegm_posix};
use XML::Simple;

my @logs;    # mp4 details

say "reading $dirtxt";
open my $fh, '<', $dirtxt;
my $dir = trim <$fh>;
close $fh;

say "processing directory $dir", "\n";
foreach my $file ( glob catfile $dir, '*.mp4' ) {
    my ( $filename, $path, $suffix ) = fileparse( $file, '\.mp4' );
    my @log;
    push @log, $filename . '.mp4';
    say "processing $filename.mp4";

    say "extracting frame info with ffprobe ...";
    my $ffprobe
        = "ffprobe "
        . "-hide_banner "
        . "-v error "
        . "-select_streams v "
        . "-show_entries "
        . "stream=avg_frame_rate,duration,nb_frames:"
        . "stream_tags=creation_time "
        . "-of default=nk=1:nw=1 \"$file\"";
    my ( $framerate, $duration, $frames, $creation ) = split /\n/, `$ffprobe`;
    say
        "framerate=$framerate duration=$duration frames=$frames created $creation";
    my $rate = eval $framerate;
    push @log, $framerate, $duration, $frames, $creation;

    say "extracting gps info with $exiftool";
    say "be patient ...";
    open my $exif, '-|', $exiftool,
        '-p',
        '#[IF]$gpslatitude $gpslongitude',
        '-p',
        '#[BODY]$sampletime#,$gpsdatetime#,$gpslongitude#,$gpslatitude#',
        '-ee', '-m', '-api', 'largefilesupport', $file;
    chomp( my @input = <$exif> );
    close $exif;
    say scalar @input, " gps points read";

    my @lines;
    foreach my $line (@input) {
        push @lines, [ split /,/, $line ];
    }

    my @gps;
    for my $line (@lines) {
        my ( $sampletime, $gmtime, $lon, $lat ) = @$line;
        my ( $yyyy, $mm, $dd, $hr, $min, $sec )
            = ( $gmtime =~ m{(\d+):(\d+):(\d+).(\d+):(\d+):([^Z]+)} );
        my $time
            = timegm_posix( $sec, $min, $hr, $dd, $mm - 1, $yyyy - 1900 );
        push @gps, [ $sampletime, $time, $lon, $lat ];
    }

    my $start = $lines[0]->[1];
    my $end   = $lines[-1]->[1];
    my $first = $gps[0]->[1];
    my $last  = $gps[-1]->[1];
    my $span  = sprintf '%.1f', $last - $first;
    push @log, $start, $end, $first, $last, $span;
    say "start = $start end = $end => $span seconds";

    say "interpolating frame locations ...";
    my @frames;
    my $p = 0;

    for my $frame ( 0 .. $frames - 1 ) {
        my $x = $frame / $rate;

        while ( $x > $gps[ $p + 1 ]->[0] ) {
            last if ( $p == @gps - 2 );
            $p++;
        }

        my ( $x0, @r0 ) = @{ $gps[$p] };
        my ( $x1, @r1 ) = @{ $gps[ $p + 1 ] };
        my $w0 = ( $x1 - $x ) / ( $x1 - $x0 );
        my $w1 = 1.0 - $w0;

        my @r;
        for my $i ( 0 .. $#r0 ) {
            my $y0 = $r0[$i];
            my $y1 = $r1[$i];
            my $y  = $y0 * $w0 + $y1 * $w1;
            push @r, $y;
        }

        push @frames, [ $frame, $x, @r ];
    }

    say "writing csv ...";
    my $csvfile = $path . $filename . ".csv";
    open my $csv, '>', $csvfile;
    for my $frame (@frames) {
        say $csv join( ',', @$frame );
    }
    close $csv;

    say "creating kml ... ";
    my @kmlframes = map {
        (   sub {
                my ( $frame, $pts, $time, $lon, $lat ) = @{$_};
                return () if ( $frame % 5 );
                my ( $style, $desc );
                my $localtime = scalar localtime($time);
                my $name      = timestamp($pts);
                $style = 'bad';
                $desc  = sprintf( "%s", $localtime );
                return [ $name, $lon, $lat, 0, $style, $desc ];
            }
        )->($_);
    } @frames;

    say "writing kml ...";
    my $href = 'http://maps.google.com/mapfiles/kml/pal4/icon46.png';
    my @styles
        = ( [ 'good', 'ff00ff00', $href ], [ 'bad', 'ff7f00ff', $href ] );
    my $kmlfile = $path . $filename . ".kml";
    open my $kml, '>', $kmlfile;
    print $kml kmlout( $filename, \@styles, \@kmlframes );
    close $kml;

    push @logs, [@log];
    say "";
}

say "writing $logfile...";
open my $lh, '>', $logfile;
for my $log (@logs) {
    say $lh join ',', @$log;
}
close $lh;
say "finished";

# end

################################################

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

