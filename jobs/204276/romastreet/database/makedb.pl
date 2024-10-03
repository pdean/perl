# makedb from 12da
# vim:ft=perl:sts=4:sw=4:et:tw=78
use v5.36;
#

my $cln    = "Roma Street GDA2020 Alignments.utf8.12da";
my $schema = 'romastreet';
my $zone   = 56;

# no more edits
#
use File::Basename;
use DBI;
use XML::Simple;
use Math::Complex;

use aliased 'Geo::Proj::CCT';
my $cs = CCT->crs2crs( "EPSG:283" . $zone, "EPSG:4283" );
$cs = $cs->norm;

my %counts;
my @lines = ();
my @data  = ();
my @point;
my ( $acc, $seg, $name, $chainage, $data );

open( my $fh, "<", $cln ) or die "Can't open < $cln: $!";
$acc = 0;
while ( my $line = <$fh> ) {
    chomp $line;
    if ($acc) {
        if ( $line =~ /\}/ ) {
            $acc = 0;
            $seg = ++$counts{$name};
            say "read $name $seg ...";
            $data = addchainage( \@data, $chainage );
            push @lines, [ $name, $seg, $chainage, $data ];
        }
        else {
            @point = ( split( ' ', $line ) )[ 0, 1 ];
            push @data, [@point];
        }
    }
    else {
        if ( $line =~ /^\s+name/ ) {
            $name = ( split " ", $line, 2 )[1];
            $name =~ tr/"//d;
            say $name;
        }
        if ( $line =~ /chainage/ ) {
            $chainage = ( split " ", $line, 2 )[1];
            say $chainage;
        }
        if ( $line =~ /data_3d/ ) {
            $acc  = 1;
            @data = ();
        }
    }
}
close $fh;

#dmp(\@lines);

my ( $filename, $dirs, $suffix ) = fileparse( $cln, '\..*' );
my $kmlfile = $dirs . $filename . ".kml";
my $kml     = kmlout( \@lines, $filename );
open( $fh, ">", $kmlfile );
print $fh $kml;
close $fh;
say "wrote $kmlfile";

makedb( \@lines, $schema );
say "created schema $schema";

exit;

# end

# subroutines

sub makedb {
    my ( $ref, $schema ) = @_;
    my @lines = @$ref;

    my $dbname   = 'gis';
    my $host     = 'ws1806.northgroup.local';
    my $username = 'gis';
    my $password = 'gis';
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
        id serial primary key, name text, seg text,
        tdist float, geog geography(point, 7844))};
    say $sql;
    $dbh->do($sql) or die $dbh->errstr;
    $sql = qq{CREATE table $schema.segments (
        id serial primary key, name text, seg text,
        tstart float, tend float,
        geog geography(linestring, 7844))};
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
        my ( $name, $seg, $chainage, $data ) = @$line;
        my ( $sth, $sql );
        my @data = @$data;

        say "db add $name $seg points ...";

        $sql = qq{INSERT INTO $schema.points (name, seg, tdist, geog)
                VALUES (?, ?, ?, ST_SetSRID(ST_Point(?, ?), 7844)::geography )};
        $sth = $dbh->prepare($sql) or die $dbh->errstr;

        foreach my $point (@data) {
            my ( $ch, $geog, $mga ) = @$point;
            my ( $lon, $lat ) = @$geog;

            $sth->execute( $name, $seg, $ch, $lon, $lat ) or die $sth->errstr;
        }

        say "db add $name $seg segments ...";

        $sql
            = qq{INSERT INTO $schema.segments (name, seg, tstart, tend,  geog)
                    VALUES(?, ?, ?, ?, 
                       ST_SetSRID(ST_Makeline(ST_Point(?, ?), ST_Point(?, ?)), 7844)::geography )};
        $sth = $dbh->prepare($sql) or die $dbh->errstr;

        my $start = shift @data;

        foreach my $end (@data) {
            my ( $sch, $sgeog, $smga ) = @$start;
            my ( $slon, $slat ) = @$sgeog;

            my ( $ech, $egeog, $emga ) = @$end;
            my ( $elon, $elat ) = @$egeog;

            $sth->execute( $name, $seg, $sch, $ech, $slon, $slat, $elon,
                $elat )
                or die $sth->errstr;

            $start = $end;
        }
    }

    $dbh->disconnect;
}

sub kmlout {
    my ( $ref, $name ) = @_;

    my $Doc    = [];
    my $Style  = [];
    my $Folder = [];

    push @$Doc,
        {   name   => [$name],
            Style  => $Style,
            Folder => $Folder,
        };

    my $href
        = "http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png";
    push @$Style,
        {   id        => 'Info',
            IconStyle => [ { Icon => [ { href => [$href] } ], } ]
        };

    my @lines = @$ref;
    foreach my $line (@lines) {
        my ( $name, $seg, $chainage, $data ) = @$line;

        my $Placemark = [];

        push @$Folder,
            {   name      => ["$name $seg"],
                Placemark => $Placemark,
            };

        foreach my $point (@$data) {
            my ( $ch, $geog, $mga ) = @$point;
            my ( $lon,  $lat )   = @$geog;
            my ( $east, $north ) = @$mga;
            my $desc
                = sprintf( "%.3f", $ch ) . '<br>'
                . $name . '<br>'
                . $seg . '<br>'
                . sprintf( "%.3f", $east ) . '<br>'
                . sprintf( "%.3f", $north ) . '<br>';

            push @$Placemark,
                {   name        => [ sprintf( "%.0f", $ch ) ],
                    styleUrl    => ["#Info"],
                    description => [$desc],
                    Point       => [ { coordinates => ["$lon,$lat,0.0"] } ],
                };
        }
    }

    my $root = { Document => $Doc };
    return XMLout( $root, Rootname => 'kml' );
}

sub dmp {
    my $ref   = shift;
    my @lines = @$ref;

    say "DUMP";

    foreach my $line (@lines) {
        my ( $name, $seg, $chainage, $data ) = @$line;
        say "$name $seg $chainage";
        foreach my $point (@$data) {
            my ( $ch, $geog, $mga ) = @$point;
            say "  $ch @$geog @$mga";
        }
    }
}

sub addchainage {
    my ( $list, $chainage ) = @_;
    my @list  = @$list;
    my @clist = ();
    my ( $start, $end, $geog, $new );

    $start = shift @list;
    $geog  = $cs->fwd($start);
    $new   = [ $chainage, $geog, $start ];
    push @clist, $new;

    foreach $end (@list) {
        $chainage += abs( cplx(@$end) - cplx(@$start) );
        $geog = $cs->fwd($end);
        $new  = [ $chainage, $geog, $end ];
        push @clist, $new;
        $start = $end;
    }
    return \@clist;
}

