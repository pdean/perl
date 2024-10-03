#!/usr/bin/perl -w
# vim:ft=perl:sts=4:sw=4:et

use v5.10;
use Time::Local qw{timelocal_posix timegm_posix};
use File::Basename;
use XML::Simple;

####################
# read configuration
#
use Config::Std;
my $rcfile = glob('~/.instarc');
my %config;
my $dir = glob('~/');

#my $fudge = 43201.0;
if ( !-e $rcfile ) {
    $config{prep}{dir} = $dir;

    #   $config{prep}{fudge} = $fudge;
    write_config %config => $rcfile;
}

# Read in the config file...
read_config $rcfile => %config;
$dir = $config{prep}{dir};

#$fudge = $config{prep}{fudge};

#################
# create interface
#
use Tk;
require Tk::ROText;

my $mw = MainWindow->new;
$mw->title('Preprocess mp4 files to kml');

my $top  = $mw->Frame->pack( -fill => 'x' );
my $info = $top->Label(
    -anchor     => 'w',
    -background => 'bisque',
    -relief     => 'groove',
    -font       => "courier 12 bold",
    -text       => 'Select directory then press run'
);
$info->pack( -side => 'left', -ipadx => 5, -padx => 10, -pady => 10 );

my $mid  = $mw->Frame->pack( -fill => 'x' );
my $dbtn = $mid->Button(
    -relief  => 'raised',
    -text    => 'Select Directory',
    -font    => "courier 12 bold",
    -command => sub {
        $dir = $mw->chooseDirectory(
            -initialdir => $dir,
            -title      => 'Choose a directory'
        );
        msg($dir);
    }
);
my $dntry = $mid->Entry(
    -textvariable => \$dir,
    -relief       => 'sunken',
    -background   => 'bisque',
    -width        => 100,
    -font         => "courier 12 bold"
);
Tk::grid( $dbtn, $dntry, -sticky => 'ew', -padx => 3, -pady => 3 );

my $bot  = $mw->Frame->pack;
my $quit = $bot->Button(
    -text    => 'Quit',
    -relief  => 'raised',
    -font    => "courier 12 bold",
    -command => \&quit
);
my $run = $bot->Button(
    -text    => 'Run',
    -relief  => 'raised',
    -font    => "courier 12 bold",
    -command => \&run
);
Tk::pack(
    $quit, $run,
    -side  => 'left',
    -ipadx => 5,
    -padx  => 10,
    -pady  => 10
);

my $x    = $mw->Frame->pack( -fill => 'both', -expand => 1 );
my $text = $x->Scrolled( "ROText", -wrap => 'none' );
$text->pack( -expand => 1, -fill => 'both' );

MainLoop;

#############################
# subroutines
#

# quit, saving some variables

sub quit {
    $config{prep}{dir} = $dir;

    #    $config{prep}{fudge} = $fudge;
    write_config %config => $rcfile;
    exit;
}

# log messages to text window

sub msg {
    my $msg = shift;
    $text->insert( 'end', $msg . "\n" );
    $text->see('end');
    $mw->update;
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

#####################
# run - main processing loop
#
sub run {
    $text->delete( '1.0', 'end' );
    msg "dir $dir";

    my @files = glob(qq("${dir}/*.mp4"));
    if ( !@files ) {
        msg "No mp4 files!";
        return;
    }
    msg "@files";

    #msg "fudge = $fudge";
    for my $file (@files) {
        msg "processing $file\n";
        my ( $filename, $dirs, $suffix ) = fileparse( $file, '\..*' );

        msg "ffprobe $file";
        my $cmd
            = "ffprobe "
            . "-hide_banner "
            . "-v error "
            . "-select_streams v "
            . "-show_entries "
            . "stream=avg_frame_rate,duration,nb_frames:"
            . "stream_tags=creation_time "
            . "-of default=nk=1:nw=1 \"$file\"";
        my ( $framerate, $duration, $frames, $creation ) = `$cmd`;
        chomp $framerate;
        chomp $frames;
        chomp $duration;
        chomp $creation;
        my ( $numer, $denom ) = ( split( "/", $framerate ) );
        my $rate = $numer / $denom;
        msg "$rate frames/sec";
        msg "$duration secs";
        msg "$frames frames";
        msg "created $creation localtime";
        my ( $yyyy, $mm, $dd, $hr, $min, $sec )
            = ( $creation =~ m{(\d+)-(\d+)-(\d+).(\d+):(\d+):([^Z]+)} );
        my $start
            = timelocal_posix( $sec, $min, $hr, $dd, $mm - 1, $yyyy - 1900 );
        my $end = $start + $duration;
        msg "$start - $end unixtime";

        msg "\nexiftool $file";
        msg "this could take quite a while ......";
        msg "start - " . localtime;
        open(
            $cmd,
            '-|',
            'exiftool64',
            '-p',
            '#[IF]$gpslatitude $gpslongitude',
            '-p',
            '#[BODY]$sampletime#,$gpsdatetime#,$gpslongitude#,$gpslatitude#',
            '-ee',
            '-m',
            '-api',
            'largefilesupport',
            $file
        );
        chomp( my @lines = <$cmd> );
        close $cmd;
        msg "end - " . localtime;
        my @gps;

        for my $line (@lines) {

            # my (undef, $gmtime, $lon, $lat) = split(/,/,$line);
            my ( $sampletime, $gmtime, $lon, $lat ) = split( /,/, $line );
            my ( $yyyy, $mm, $dd, $hr, $min, $sec )
                = ( $gmtime =~ m{(\d+):(\d+):(\d+).(\d+):(\d+):([^Z]+)} );
            my $time
                = timegm_posix( $sec, $min, $hr, $dd, $mm - 1, $yyyy - 1900 );

            #push @gps, [$time, $lon, $lat];
            push @gps, [ $sampletime, $time, $lon, $lat ];
        }
        my $first = $gps[0]->[1];
        my $last  = $gps[-1]->[1];
        my $span  = $last - $first;
        msg "$first - $last unixtime = $span secs";

        msg "\ninterpolating frame locations ...";
        my @frames;
        my $p = 0;

        for my $frame ( 0 .. $frames - 1 ) {
            my $ts = $frame / $rate;

            # my $x = $ts + $start + $fudge;
            my $x = $ts;
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

            #push @frames, [$frame, $ts, $x, @r];
            push @frames, [ $frame, $x, @r ];
        }

        msg "writing csv ...";
        my $csvfile = $dirs . $filename . ".csv";
        open OUT, '>', $csvfile;
        for my $frame (@frames) {
            print OUT join( ',', @$frame ), "\n";
        }
        close OUT;

        msg "creating kml of frames ... ";
        my @kmlframes = map {
            (   sub {
                    my ( $frame, $pts, $time, $lon, $lat ) = @{$_};
                    return () if ( $frame % 5 );
                    my ( $style, $desc );
                    my $localtime = scalar localtime($time);
                    my $name      = timestamp($pts);
                    $style = 'good';
                    $desc  = sprintf( "%s", $localtime );
                    return [ $name, $lon, $lat, 0, $style, $desc ];
                }
            )->($_);
        } @frames;

        msg "writing kml ...";
        my $href = 'http://maps.google.com/mapfiles/kml/pal4/icon46.png';
        my $styles
            = [ [ 'good', 'ff00ff00', $href ], [ 'bad', 'ff7f00ff', $href ] ];
        my $kmlfile = $dirs . $filename . ".kml";
        open OUT, '>', $kmlfile;
        print OUT kmlout( $filename, $styles, \@kmlframes );
        close OUT;

        msg "\nfinished $file\n";
    }

    my $logfile = $dir . "/log.txt";
    open OUT, '>', $logfile;
    print OUT $text->get( '1.0', 'end' );
    close OUT;

    msg "done";
}

