#!/usr/bin/env perl
#!c:/strawberry/perl/bin/perl
# vim:ft=perl:sts=4:sw=4:et
# kml.cgi

use v5.36;
use DBI;
use XML::LibXML;
use CGI qw(:standard);
use YAML::Tiny 'LoadFile';

my $file   = './kml.yaml';
my $config = LoadFile($file);
my @box    = split /,/, param('BBOX');
my ( $lon1, $lat1, $lon2, $lat2 ) = @box;
my $type   = param('type');
my $params = $config->{$type};

my $schema = $params->{schema};
my $table  = $params->{table};
my $idx    = $params->{index};
my $geom   = $params->{geom};
my $epsg   = $params->{epsg};
my $limit  = $params->{limit} // 5000;
my $where  = ' ';
if ( exists $params->{where} ) {
    $where = " and $params->{where}";
}

my $schematable = "$schema.$table";
my $host        = 'localhost';
my $dbname      = 'gis';
my $username    = 'gis';
my $password    = 'gis';

my $dbh = DBI->connect( "dbi:Pg:dbname=$dbname;host=$host",
    $username, $password,
    { AutoCommit => 0, RaiseError => 1, PrintError => 0 } );

my $colquery = <<END;
select column_name from information_schema.columns 
where table_name='$table' and table_schema='$schema' 
order by ordinal_position
END

my ( $rows, @columns );
$rows = $dbh->selectall_arrayref($colquery);
for my $row (@$rows) {
    my ($column) = @$row;
    next if ( $column eq $idx );
    next if ( $column eq $geom );
    push @columns, $column;
}
my $cols = join( ',', @columns );

my $query = <<END;
select st_askml($geom) as kml, $cols from $schematable  where $geom && 
st_transform(st_setsrid(st_makebox2d(st_point($lon1,$lat1),st_point($lon2,$lat2)),7844),$epsg) 
$where limit $limit
END

$rows = $dbh->selectall_arrayref($query);
my $kml = tokml( \@columns, $rows, $params, $schematable );
print header('application/vnd.google-earth.kml+xml');
print $kml;

# end main
##############################
# subs

use subs qw/element attribute text/;

sub tokml {
    my ( $columns, $rows, $params, $subtitle ) = @_;

    my $dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $kml = $dom->createElement('kml');
    $kml->setAttribute( 'xmlns', 'http://earth.google.com/kml/2.1' );
    $dom->setDocumentElement($kml);

    my $document = element $dom, $kml => 'Document';
    text $dom, $document, name => $params->{title};

    my $folder = element $dom, $document => 'Folder';
    text $dom, $folder, name => $subtitle;

    for my $row (@$rows) {

        my $kml = shift @$row;
        my %values;
        for my $column (@$columns) {
            my $val = shift @$row // 'NULL';
            $values{$column} = $val;
        }

        my $name;
        if ( $values{ $params->{name} } ne 'NULL' ) {
            $name = "$values{$params->{name}}";
        }
        elsif ( $values{ $params->{altname} } ne 'NULL' ) {
            $name = "$values{$params->{altname}}";
        }
        else {
            $name = "$values{$params->{altname2}}";
        }

        my $placemark = element $dom, $folder => 'Placemark';
        text $dom, $placemark, name     => $name;
        text $dom, $placemark, styleUrl => '#NORMAL';

        my $extended = element $dom, $placemark => 'ExtendedData';
        for my $column (@$columns) {
            my $data = attribute $dom, $extended, Data => ( name => $column );
            text $dom, $data, value => $values{$column};
        }

        $placemark->appendWellBalancedChunk($kml);
    }

    my $scale = $params->{scale} // '1.25';
    my $href  = $params->{icon}
        // "http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png";
    my $width   = $params->{width}   // '2';
    my $color   = $params->{color}   // 'ffffffff';
    my $fill    = $params->{fill}    // '0';
    my $outline = $params->{outline} // '1';

    my $style = attribute $dom, $document, Style => ( id => 'NORMAL' );

    my $iconstyle = element $dom, $style     => 'IconStyle';
    my $icon      = element $dom, $iconstyle => 'Icon';
    text $dom, $iconstyle, scale => $scale;
    text $dom, $icon,      href  => $href;
    text $dom, $iconstyle, color => $color;

    my $linestyle = element $dom, $style => 'LineStyle';
    text $dom, $linestyle, width => $width;
    text $dom, $linestyle, color => $color;

    my $polystyle = element $dom, $style => 'PolyStyle';
    text $dom, $polystyle, fill    => $fill;
    text $dom, $polystyle, outline => $outline;
    text $dom, $polystyle, color   => $color;

    return $dom->toString(1);
}

sub text {
    my ( $dom, $parent, $name, $text ) = @_;
    my $node = $dom->createElement($name);
    $node->appendTextNode($text);
    $parent->appendChild($node);
    return $node;
}

sub element {
    my ( $dom, $parent, $name ) = @_;
    my $node = $dom->createElement($name);
    $parent->appendChild($node);
    return $node;
}

sub attribute {
    my ( $dom, $parent, $name, $id, $value ) = @_;
    my $node = $dom->createElement($name);
    $parent->appendChild($node);
    $node->setAttribute( $id => $value );
    return $node;
}
