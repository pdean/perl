#!/usr/bin/perl
use v5.40;

# datum for database
my $to = 7844;    # gda2020

# need to create epsg.txt in each dir
# with datum of point data eg 7856 = zone 56 mga2020

# schema for database
my $schema = 'lithgow';

# database login
my $dbname = 'gis';
my $host   = 'localhost';

#my $host     = 'WS2301.northgroup.local';
my $username = 'gis';
my $password = 'gis';

# csv file details
# GC03 format
# skip 11 lines
# separator is ,
# field 1 is ch
# field 5 is easting
# field 6 is northing
my $skip  = 11;
my $sep   = ',';
my $ch    = 1;
my $east  = 5;
my $north = 6;

#  no more edits
#
#  load libraries
use File::Glob ':bsd_glob';
use File::Slurp qw(read_dir read_file write_file);
use DBI;
use XML::Simple;
use aliased 'Geo::Proj::CCT';

# create an array to contain all the control lines
my @lines;

# iterate over subdirectories
# use directory name as control line name
# parse csv and add array of ch,east,north to line

my $root = '.';
for my $dir ( sort ( grep { -d "$root/$_" } read_dir($root) ) ) {
    print "$dir\n";

    # get epsg
    my $from = ( split /\s/, ( read_file "$dir/epsg.txt" )[0] )[0];
    print "zone $from\n";

    # create coordinate system
    my $cs = CCT->crs2crs( "EPSG:$from", "EPSG:$to" )->norm;
    say $cs->definition;

    # locate csv, just use first
    my $csv = ( glob "$dir/*.csv" )[0];
    print "  $csv\n";

    # read whole file
    my @file = read_file $csv;
    print $file[$skip];
    print $file[$#file];
    print "\n";

    # initialise points arrray
    my @data;

    # loop over points
    for my $line ( @file[ $skip .. $#file ] ) {
        my ( $c, $e, $n ) = ( split /$sep/, $line )[ $ch, $east, $north ];
        my ( $lon, $lat ) = @{ $cs->fwd( [ $e, $n ] ) };

        #        print "$c\t$e\t$n\t$lon\t$lat\n";
        push @data, [ $c, $e, $n, $lon, $lat ];
    }
    push @lines, [ $dir, \@data ];
}

write_file( "$schema.kml", kmlout() );
say "wrote $schema.kml";

makedb();
say "created schema $schema in $host";

# end main
#
# subroutines just use globals!
#
sub kmlout {
    my $Doc    = [];
    my $Style  = [];
    my $Folder = [];

    push @$Doc,
        {   name   => [$schema],
            Style  => $Style,
            Folder => $Folder,
        };

    my $href
        = "http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png";
    push @$Style,
        {   id        => 'Info',
            IconStyle => [ { Icon => [ { href => [$href] } ], } ]
        };

    foreach my $line (@lines) {
        my ( $name, $data ) = @$line;

        my $Placemark = [];

        push @$Folder,
            {   name      => ["$name"],
                Placemark => $Placemark,
            };

        foreach my $point (@$data) {
            my ( $ch, $east, $north, $lon, $lat ) = @$point;
            my $desc
                = sprintf( "%.3f", $ch ) . '<br>'
                . $name . '<br>'
                . sprintf( "%.3f", $east ) . '<br>'
                . sprintf( "%.3f", $north ) . '<br>';

            push @$Placemark,
                {   name        => [ sprintf( "%.1f", $ch ) ],
                    styleUrl    => ["#Info"],
                    description => [$desc],
                    Point       => [ { coordinates => ["$lon,$lat,0.0"] } ],
                };
        }
    }

    my $root = { Document => $Doc };
    return XMLout( $root, Rootname => 'kml' );
}

sub makedb {
    my $sql;

    my $dbh = DBI->connect( "dbi:Pg:dbname=$dbname;host=$host",
        $username, $password, { RaiseError => 1 } );

    $sql = "DROP SCHEMA IF EXISTS $schema CASCADE";
    say $sql;
    $dbh->do($sql) or die $dbh->errstr;
    $sql = "CREATE SCHEMA $schema";
    say $sql;
    $dbh->do($sql) or die $dbh->errstr;
    $sql = qq{CREATE table $schema.points (
        id serial primary key, name text,
        tdist float, geog geography(point, $to))};
    say $sql;
    $dbh->do($sql) or die $dbh->errstr;
    $sql = qq{CREATE table $schema.segments (
        id serial primary key, name text,
        tstart float, tend float,
        geog geography(linestring, $to))};
    say $sql;
    $dbh->do($sql) or die $dbh->errstr;
    $sql = "CREATE INDEX idx_points_geog on $schema.points USING gist(geog)";
    say $sql;
    $dbh->do($sql) or die $dbh->errstr;
    $sql
        = "CREATE INDEX idx_segments_geog on $schema.segments USING gist(geog)";
    say $sql;
    $dbh->do($sql) or die $dbh->errstr;

    foreach my $line (@lines) {
        my ( $name, $data ) = @$line;
        my ( $sth, $sql );

        say "db add $name points ...";

        $sql = qq{INSERT INTO $schema.points (name, tdist, geog)
                VALUES (?, ?, ST_SetSRID(ST_Point(?, ?), $to)::geography )};
        $sth = $dbh->prepare($sql) or die $dbh->errstr;

        foreach my $point (@$data) {
            my ( $ch, $east, $north, $lon, $lat ) = @$point;
            $sth->execute( $name, $ch, $lon, $lat ) or die $sth->errstr;
        }

        say "db add $name segments ...";

        $sql = qq{INSERT INTO $schema.segments (name, tstart, tend,  geog)
                    VALUES(?, ?, ?, 
                       ST_SetSRID(ST_Makeline(ST_Point(?, ?), ST_Point(?, ?)), $to)::geography )};
        $sth = $dbh->prepare($sql) or die $dbh->errstr;

        my $start = shift @$data;

        foreach my $end (@$data) {
            my ( $ch1, $east1, $north1, $lon1, $lat1 ) = @$start;
            my ( $ch2, $east2, $north2, $lon2, $lat2 ) = @$end;

            $sth->execute( $name, $ch1, $ch2, $lon1, $lat1, $lon2, $lat2 )
                or die $sth->errstr;

            $start = $end;
        }
    }

    $dbh->disconnect;
}

