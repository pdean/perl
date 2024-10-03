#!/usr/bin/perl
# vim:ft=perl:sts=4:sw=4:et:tw=78
#
use v5.36;

# globals

my $offset       = 20.0;
my $schema       = 'romastreet';
my $deliverytext = '../delivery.txt';
my $mp4dirstext  = '../mp4dirs.txt';
my $posdirtext   = '../posdir.txt';
my $postext      = 'pos.txt';
my $splitstext   = 'splits.txt';

my $stride  = 8;           # in pos file
my $tempdir = tempdir();

my $fh;                    # for file handles;

no warnings 'experimental::for_list';
use experimental qw(builtin);
use builtin      qw(trim true false);
use Cwd;
use DBI;
use File::Basename;
use File::Path qw(make_path);
use File::Spec;
use File::Temp      qw{tempdir};
use List::MoreUtils qw(bsearchidx);
use Math::Trig      qw(great_circle_distance deg2rad);
use POSIX           qw(floor round);
use Time::Local     qw( timelocal_posix timegm_posix );
use XML::Simple;

use Data::Dumper;

# create output folder with same name as current in delivery top

open $fh, '<', $deliverytext;
my $deliverytop = trim <$fh>;
close $fh;

my $abscwd = cwd();
my ( $vol, $dirs, $cwd ) = File::Spec->splitpath($abscwd);
my $delivery = File::Spec->catfile( $deliverytop, $cwd );
make_path($delivery);
say "outputting to $delivery";
my $cam    = ( split /-/, $cwd )[-1];
my $dir    = $cam ne "FRONT";
my $dirtxt = $dir ? "reverse" : "forward";
say "camera at $cam, dir $dirtxt";

# read mp4dirs, pos and posdirs and create mp4 path and pos path

my %mp4dir;
open $fh, '<', $mp4dirstext;
while (<$fh>) {
    chomp;
    my ( $tag, $dir ) = split /,/;
    $mp4dir{$tag} = $dir;
}
close $fh;

open $fh, '<', $postext;
my ( $tag, $mp4, $pos, $start, $end, $fudge ) = map { trim $_ } split /\t/,
    <$fh>;
close $fh;
my $mp4file = File::Spec->catfile( $mp4dir{$tag}, $mp4 );
say $mp4file;

open $fh, '<', $posdirtext;
my $posdir = trim <$fh>;
close $fh;
my $posfile = File::Spec->catfile( $posdir, $pos );
say $posfile;

# read splits

my @times;
open $fh, '<', $splitstext;
while (<$fh>) {
    chomp;
    next if m/^\s*$/;
    my ( $s, $m, $h ) = reverse split /:/, '0:0:' . $_;
    push @times, $s + 60 * ( $m + 60 * $h );
}
close $fh;
say "splits @times";

my $outfile = File::Spec->catfile( $delivery, $cwd . '.mp4' );
my $concats = File::Spec->catfile( $tempdir,  'concat.txt' );
open my $concat, '>', $concats;

my $part    = 0;
my @timetab = ();
for my ( $s, $e ) (@times) {

    # find previous keyframes
    my $cmd
        = 'ffprobe'
        . " -read_intervals $s%+#1"
        . ' -v error'
        . ' -skip_frame nokey'
        . ' -show_entries frame=pts_time'
        . ' -select_streams v'
        . ' -of csv=p=0'
        . " \"$mp4file\"";
    my $key  = `$cmd`;
    my $skey = ( split /,/, $key )[0] + 0;
    $cmd
        = 'ffprobe'
        . " -read_intervals $e%+#1"
        . ' -v error'
        . ' -skip_frame nokey'
        . ' -show_entries frame=pts_time'
        . ' -select_streams v'
        . ' -of csv=p=0'
        . " \"$mp4file\"";
    $key = `$cmd`;
    my $ekey = ( split /,/, $key )[0] + 0;
    while ( $ekey < $e ) {
        $ekey += 0.2;
    }
    my $t = $ekey - $skey;
    push @timetab, [ $skey, $ekey ];

    my $file = File::Spec->catfile( $tempdir, sprintf 'part%02d.mp4', $part );
    say {$concat} "file '$file'";

    # cut mpeg
    $cmd
        = 'ffmpeg' . ' -y'
        . " -ss $skey"
        . " -i \"$mp4file\""
        . " -t $t"
        . ' -c copy' . ' -an'
        . ' -strict unofficial'
        . " \"$file\"";
    say $cmd;

    #say "not run";
    my $result = system $cmd;

    $part++;
}
close $concat;

# join mpegs
my $cmd
    = 'ffmpeg' . ' -y'
    . ' -f concat'
    . ' -safe 0'
    . " -i \"$concats\""
    . ' -c copy' . ' -an'
    . ' -strict unofficial'
    . " \"$outfile\"";
say $cmd;

#say "not run";
my $result = system $cmd;

print Dumper( \@times );
say "adjusted times";
print Dumper( \@timetab );

# load part of posfile
#

my $padding = 60;

my $low = $timetab[0][0] - $padding;
my $hi  = $timetab[-1][1] + $padding;

say "loading pos file from $low to $hi";

my $poslow = weeksecs( $low + $start );
my $poshi  = weeksecs( $hi + $start );
say "weeksecs $poslow to $poshi";

my @posdata;
my ( $time, $lat, $lon );
my $secsinweek   = 7 * 24 * 60 * 60;
my $wrap         = 0;
my $sortrequired = 0;

open $fh, '<', $posfile;

while (true) {
    my $line = <$fh>;
    ( $time, $lat, $lon ) = split " ", $line;
    $time -= $secsinweek if $time >= $secsinweek;
    last                 if ( abs( $time - $poslow ) < 1 / 128 );
}
say "saving from $time";
while (true) {
    my $line = <$fh>;
    ( $time, $lat, $lon ) = split " ", $line;
    push @posdata, [ $time, $lat, $lon ];
    if ( $time >= $secsinweek ) {
        $time -= $secsinweek;
        push @posdata, [ $time, $lat, $lon ];    #duplicate!
        ++$sortrequired;
    }
    last if ( abs( $time - $poshi ) < 1 / 128 );
}
close $fh;
say "stopping at $time";

if ($sortrequired) {
    say "sorting pos data";
    @posdata = sort { $a->[0] <=> $b->[0] } @posdata;
    $wrap    = bsearchidx { extcmp( $_->[0], $secsinweek ) } @posdata;
}

# interpolating frame times

my $frame = 0;
my @frames;

for my $t (@timetab) {
    my ( $s, $e ) = @$t;
    my $nf = round( 5 * ( $e - $s ) );
    say "$s $e $nf";

    for my $f ( 0 .. $nf - 1 ) {
        my $t  = $f / 5 + $s;
        my $ut = $t + $start + $fudge;
        my $p  = weeksecs($ut);
        my ( $pt, $lat, $lon, $speed ) = calcpos($p);
        say "$frame\t$f\t$t\t$ut\t$p\t$pt\t$lat\t$lon\t$speed";

        my ( $ch, $os, $name ) = railloc( $lon, $lat );

        push @frames,
            [   $frame,    dec1( $frame / 5 ),
                dec1($ut), $lon,
                $lat,      $name,
                dec1($ch), dec1($os)
            ];

        $frame++;
    }
    print "\n";
}

my $outcsv = File::Spec->catfile( $delivery, $cwd . '.csv' );
say "writing $outcsv";
open $fh, '>', $outcsv;

foreach my $f (@frames) {
    say {$fh} join( ',', @$f );
}
close $fh;

my @kmlframes = map {
    (   sub {
            my ( $frame, $ts, $time, $lon, $lat, $control, $ch, $os )
                = @{$_};
            return () if ( $frame % 5 );
            my ( $style, $desc );
            my $localtime = scalar localtime($time);
            my $name      = timestamp($ts);
            if ( abs($os) > 25 ) {
                $style = 'bad';
                $desc  = "No chainage<br>$localtime";
            }
            else {
                $style = 'good';
                $desc  = sprintf( "%s<br>ch %.1f<br>os %.1f<br>%s",
                    $control, $ch, $os, $localtime );
            }
            return [ $name, $lon, $lat, 0, $style, $desc ];
        }
    )->($_);
} @frames;

my $outkml = File::Spec->catfile( $delivery, $cwd . '.kml' );
say "writing $outkml";
open $fh, '>', $outkml;
my $href   = 'http://maps.google.com/mapfiles/kml/pal4/icon46.png';
my $styles = [ [ 'good', 'ff00ff00', $href ], [ 'bad', 'ff7f00ff', $href ] ];
print {$fh} kmlout( $cwd, $styles, \@kmlframes );
close $fh;

my $outsrt = File::Spec->catfile( $delivery, $cwd . '.srt' );
say "writing $outsrt";
open $fh, '>', $outsrt;
my $n = 0;
for my $f (@frames) {
    my ( $frame, $pts, $time, $lon, $lat, $control, $ch, $os ) = @$f;

    if ( abs($os) < 25 ) {
        my $ts = timestamp($pts);
        my $te = timestamp( $pts + 0.2 );    # 5 fps!
        print $fh ++$n,          "\n";
        print $fh "$ts --> $te", "\n";
        print $fh "$control ";
        print $fh sprintf( "%.3f km", $ch / 1000 ), "\n";
        print $fh "\n";
    }
}
close $fh;

say 'finished.';

# end #

# subs
#

sub dec1 {
    sprintf "%.1f", shift;
}

sub calcpos {
    my ( $t1,   $lat1, $lon1 );
    my ( $t2,   $lat2, $lon2 );
    my ( $dist, $speed );

    my $t = shift;
    my $i = bsearchidx { extcmp( $_->[0], $t ) } @posdata;
    ( $t1, $lat1, $lon1 ) = @{ $posdata[$i] };
    my @p1 = ( deg2rad($lon1), deg2rad( 90 - $lat1 ) );
    say "calcing $t @ $i = $t1 $lat1 $lon1";

    my $iters = 0;
    my $step  = $dir ? -$stride : $stride;
    my $j     = $i;
    while (true) {
        $j += $step;
        if ( $j < 0 ) {
            $j += $wrap;
        }
        ( $t2, $lat2, $lon2 ) = @{ $posdata[$j] };
        my @p2 = ( deg2rad($lon2), deg2rad( 90 - $lat2 ) );
        $dist = great_circle_distance( @p1, @p2, 6372000 );
        last if ( $dist > $offset );
        ++$iters;
    }

    printf "%i %.2f %.2f %i -> ", $step, $t2 - $t1, $dist, $iters;
    print "\n";

    $speed = $dist / ( $t2 - $t1 );
    return ( $t2, $lat2, $lon2, $speed );
}

sub extcmp {
    state $eps = 1 / 250;
          ( $_[0] - $_[1] ) > $eps ? 1
        : ( $_[1] - $_[0] ) > $eps ? -1
        :                            0;
}

sub weeksecs {
    my $unixtime = shift;

    state $gpsoffset  = timegm_posix( 0, 0, 0, 6, 0, 80 );
    state $leapsecs   = 18;
    state $secsinweek = 7 * 24 * 60 * 60;

    my $gpstime = $unixtime - $gpsoffset + $leapsecs;
    my $week    = floor( $gpstime / $secsinweek );
    my $secs    = $gpstime - $week * $secsinweek;
    return $secs;
}
#
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

# railloc

sub railloc {

    # db connection parameters
    state $dbname   = 'gis';
    state $host     = 'ws1806.northgroup.local';
    state $username = 'gis';
    state $password = 'gis';

    # database handle
    state $dbh = DBI->connect( "dbi:Pg:dbname=$dbname;host=$host",
        $username, $password,
        { AutoCommit => 0, RaiseError => 1, PrintError => 0 } );

    # query string
    # NOTE $schema is global
    #
    state $query = "
          SELECT (d1 * cos(b1-b0) + tstart) AS ch,
                 (d1 * sin(b1-b0)) AS os,
                 name
          FROM
            (SELECT name,
                    tstart,
                    st_distance(st_startpoint(s.geog::geometry)::geography,
                                st_endpoint(s.geog::geometry)::geography) AS d0,
                    st_azimuth(st_startpoint(s.geog::geometry)::geography,
                               st_endpoint(s.geog::geometry)::geography) AS b0,
                    st_distance(st_startpoint(s.geog::geometry)::geography, p.geog) AS d1,
                    st_azimuth(st_startpoint(s.geog::geometry)::geography, p.geog) AS b1
                FROM $schema.segments AS s,
                  (SELECT st_setsrid(st_point(?,?),7844)::geography AS geog) AS p
                ORDER BY s.geog <-> p.geog LIMIT 1) AS foo
        ";

    # handle to prepared statement
    state $sth = $dbh->prepare($query);

    # execute query
    $sth->execute(@_);
    return $sth->fetchrow_array;
}

