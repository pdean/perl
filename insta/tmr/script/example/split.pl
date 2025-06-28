#!/usr/bin/perl
# vim:ft=perl:sts=4:sw=4:et:tw=78

my $mp4text      = 'mp4.txt';
my $splitstext   = 'splits.txt';
my $deliverytext = '../delivery.txt';
my $mp4dirtext   = '../mp4dir.txt';
my $logcsv       = '../log.csv';
my $schema       = 'tmr';

use v5.36;
no warnings 'experimental::for_list';
use experimental qw(builtin);
use builtin      qw(trim true false);
use Cwd;
use DBI;
use File::Basename;
use File::Path            qw(make_path);
use File::Spec::Functions qw(catfile splitpath);
use File::Temp            qw{tempdir};
use POSIX                 qw(floor round);
use Time::Local           qw( timelocal_posix timegm_posix );
use XML::Simple;

use Data::Dumper;

# are we fudging?
# won't reprocess mp4s if fudge is nonzero

my $fudge = 0;
$fudge = shift if (@ARGV);

my $fh;    # reuse file handle;

open $fh, '<', $mp4dirtext;
my $mp4dir = trim <$fh>;
close $fh;
say "mp4dir $mp4dir";

open $fh, '<', $mp4text;
my $mp4file = trim <$fh>;
close $fh;
say "mp4 $mp4file";

my $mp4 = catfile $mp4dir, $mp4file;
say "processing $mp4";

open $fh, '<', $deliverytext;
my $deliverydir = trim <$fh>;
close $fh;
my $abscwd = cwd;
my ( $vol, $dirs, $cwd ) = splitpath $abscwd;
my $delivery = catfile $deliverydir, $cwd;
make_path($delivery);
say "outputting to $delivery";

say "looking up $mp4file in  $logcsv";
my %logs;
open $fh, '<', $logcsv;
while (<$fh>) {
    chomp;
    my ( $key, @data ) = split /,/;
    $logs{$key} = [@data];
}
close $fh;
my @data = @{ $logs{$mp4file} };
say "$mp4file @data";
my $rate = eval $data[0];
my $dur  = dec1( 1 / $rate ) + 0;
say "framerate = $rate duration = $dur";

say "reading splits";
my @times;
open $fh, '<', $splitstext;
while (<$fh>) {
    chomp;
    next if m/^\s*$/;
    my ( $s, $m, $h ) = reverse split /:/, '0:0:' . $_;
    push @times, $s + 60 * ( $m + 60 * $h );
}
close $fh;
say "splitting times = @times";

my $tempdir = tempdir();
say "using tempdir $tempdir";

my $outfile = catfile $delivery, $cwd . '.mp4';
my $concats = catfile $tempdir,  'concat.txt';
open my $concat, '>', $concats;

my $result;
my $part = 0;
my @timetab;
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
        . " \"$mp4\"";
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
        . " \"$mp4\"";
    $key = `$cmd`;
    my $ekey = ( split /,/, $key )[0] + 0;

    while ( $ekey < $e ) {
        $ekey += $dur;
    }

    push @timetab, $skey, $ekey;

    my $file = catfile $tempdir, sprintf 'part%02d.mp4', $part;
    say $concat "file '$file'";

    # cut mpeg
    my $t = $ekey - $skey;
    $cmd
        = 'ffmpeg' . ' -y'
        . " -ss $skey"
        . " -i \"$mp4\""
        . " -t $t"
        . ' -c copy' . ' -an'
        . ' -strict unofficial'
        . " \"$file\"";
    say $cmd;

    unless ($fudge) {
        $result = system $cmd;
    }

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

unless ($fudge) {
    $result = system $cmd;
}

say "adjusted times @timetab";

my $ocsvfile = fileparse( $mp4file, "\.mp4" ) . '.csv';
say "loading $ocsvfile";
my $ocsv = catfile $mp4dir, $ocsvfile;
my @oframes;
open $fh, '<', $ocsv;
while (<$fh>) {
    chomp;
    my @line = split /,/;
    push @oframes, [@line];
}
close $fh;
say scalar @oframes, " frames read";

say "calculating new frames table";
my $frame = 0;
my @frames;

for my ( $s, $e ) (@timetab) {
    my $sf  = round( $rate * $s );
    my $ef  = round( $rate * $e );
    my $ofs = round( $rate * $fudge );

    for my $f ( $sf .. $ef - 1 ) {
        my ( $on, $ot, $ut,  $lon,  $lat )  = @{ $oframes[ $f + $ofs ] };
        my ( $ch, $os, $sec, $code, $desc ) = roadloc( $lon, $lat );
        push @frames,
            [   $frame,    dec1( $frame / $rate ),
                dec1($ut), $lon,  $lat, dec1($ch), dec1($os),
                $sec,      $code, $desc
            ];
        $frame++;
    }
    print "\n";
}

say "creating kml ...";
my @kmlframes = map {
    (   sub {
            my ($frame, $pts, $time, $lon,
                $lat,   $ch,  $os,   $section,
                $code,  $description
            ) = @{$_};
            return () if ( $frame % 5 );
            my ( $style, $desc );
            my $localtime = scalar localtime($time);
            my $name      = timestamp($pts);
            if ( abs($os) > 25 ) {
                $style = 'bad';
                $desc  = "No chainage<br>$localtime";
            }
            else {
                $style = 'good';
                $desc  = sprintf( "%s<br>ch %.3f<br>os %.0f<br>%s",
                    $description, $ch / 1000, $os, $localtime );
            }
            return [ $name, $lon, $lat, 0, $style, $desc ];
        }
    )->($_);
} @frames;

say "writing kml ...";
my $href    = 'http://maps.google.com/mapfiles/kml/pal4/icon46.png';
my $styles  = [ [ 'good', 'ff00ff00', $href ], [ 'bad', 'ff7f00ff', $href ] ];
my $kmlfile = catfile $delivery, $cwd . '.kml';
open $fh, '>', $kmlfile;
print $fh kmlout( $cwd, $styles, \@kmlframes );
close $fh;

say "writing csv ...";
my $csvfile = catfile $delivery, $cwd . '.csv';
open $fh, '>', $csvfile;
for my $frame (@frames) {
    say $fh join( ',', @$frame );
}
close $fh;

print "writing srt ...\n";
my $srtfile = catfile $delivery, $cwd . '.srt';
open $fh, '>', $srtfile;
my $n;
for my $f (@frames) {
    my ($frame, $pts, $time,    $lon,  $lat,
        $ch,    $os,  $section, $code, $description
    ) = @$f;

    if ( abs($os) < 25 ) {
        my $ts = timestamp($pts);
        my $te = timestamp( $pts + $dur );
        say $fh ++$n;
        say $fh "$ts --> $te";
        say $fh "$description";

        #say $fh "${section}_$code";
        say $fh sprintf( "%.3f km", $ch / 1000 );
        say $fh "";
    }
}
close $fh;

say "finished.";

# end

sub dec1 {
    sprintf "%.1f", shift;
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

#
# roadloc
#
# covert lon,lat to chainage etc
# use postgis database
#

sub roadloc {

    # db connection parameters
    state $dbname   = 'gis';
    state $host     = 'ws1806';
    state $username = 'gis';
    state $password = 'gis';

    # database handle
    state $dbh = DBI->connect( "dbi:Pg:dbname=$dbname;host=$host",
        $username, $password,
        { AutoCommit => 0, RaiseError => 1, PrintError => 0 } );

    # query string
    state $query = "
          select (d1 * cos(b1-b0) + tstart * 1000) as ch,
                 (d1 * sin(b1-b0)) as os,
                 section,
                 code,
                 description
          from
            (select section,
                    code,
                    description,
                    tstart,
                    tend,
                    st_distance(st_startpoint(s.geog::geometry)::geography,
                                st_endpoint(s.geog::geometry)::geography) as d0,
                    st_azimuth(st_startpoint(s.geog::geometry)::geography,
                               st_endpoint(s.geog::geometry)::geography) as b0,
                    st_distance(st_startpoint(s.geog::geometry)::geography, p.geog) as d1,
                    st_azimuth(st_startpoint(s.geog::geometry)::geography, p.geog) as b1
                from $schema.segs as s,
                  (select st_setsrid(st_point(?,?),4283)::geography as geog) as p
                where left(code,1) = any(string_to_array('123AKQ', NULL))
                order by s.geog <-> p.geog limit 1) as foo
        ";

    # handle to prepared statement
    state $sth = $dbh->prepare($query);

    # execute query
    $sth->execute(@_);
    return $sth->fetchrow_array;
}

