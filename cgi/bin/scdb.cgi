#!/usr/bin/env perl
# vim:ft=perl:sts=4:sw=4:et

use strict;
use warnings;
use v5.36;
use DBI;
use XML::LibXML;
use CGI qw(:standard);
use Net::Domain  qw(hostfqdn);

my $configfile = './scdb.pl';
do $configfile;
our %configs;

my @box = split /,/, param('BBOX');
#my @box = ( 153.015, -27.445, 153.035, -27.425 );
my ( $lon1, $lat1, $lon2, $lat2 ) = @box;

my $type   = param('type');
#my $type   = 'good';
my $params = $configs{$type};

my $site     = hostfqdn();
my $host     = 'localhost';
my $dbname   = 'gis';
my $username = 'gis';
my $password = 'gis';

my $schema = 'qspatial';
my $tab    = 'survey_control_data_qld';
my $table  = "$schema.$tab";
my $geom   = 'shape';
my $idx    = 'objectid';

my $dbh = DBI->connect( "dbi:Pg:dbname=$dbname;host=$host",
    $username, $password,
    { AutoCommit => 0, RaiseError => 1, PrintError => 0 } );

my $where = ' ';
if ( exists $params->{where} ) {
    $where = " and $params->{where} ";
}
my $query = <<"END";
select st_askml(st_force3dz($geom)) as kml, mrk_id, code 
  from $table where $geom && 
  st_setsrid(st_makebox2d(st_point($lon1,$lat1),st_point($lon2,$lat2)),4283) 
  $where  limit 1000 
END

my $rows = $dbh->selectall_arrayref($query);
my $kml  = tokml($rows);

print header('application/vnd.google-earth.kml+xml');
print $kml;

sub tokml {
    my $dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $kml = $dom->createElement('kml');
    $kml->setAttribute( 'xmlns', 'http://earth.google.com/kml/2.1' );
    $dom->setDocumentElement($kml);

    my $document = element( $dom, $kml => 'Document' );
    text( $dom, $document, name => $tab );

    my $png   = 'PMCode';
    my @codes = qw(
        2   6  10  14  18  22  26  30  38  46  54  62  82  86  90  94 118 126
        130 134 138 142 146 150 154 158 166 174 182 190 210 214 218 222 246 254
    );

    for my $code (@codes) {
        my $file  = "http://$site/pmsymbols/$png$code.png";
        my $style = attribute( $dom, $document, 'Style', id => "$png$code" );
        my $iconstyle = element( $dom, $style     => 'IconStyle' );
        my $icon      = element( $dom, $iconstyle => 'Icon' );
        text( $dom, $iconstyle, scale => '2' );
        text( $dom, $icon,      href  => $file );
    }

    my $folder = element( $dom, $document => 'Folder' );
    text( $dom, $folder, name => 'SCDB' );

    for my $row ( @{$rows} ) {
        my ( $kml, $mark, $code ) = @$row;
        my $pdf  = sprintf "SCR%06d.pdf", $mark;
        my $link = "http://qspatial.information.qld.gov.au/SurveyReport/$pdf";
        my $desc = "<a href=\"$link\"> Survey Report </a>";
        my $style = "#PMCode$code";

        my $placemark = element( $dom, $folder => 'Placemark' );
        text( $dom, $placemark, name        => $mark );
        text( $dom, $placemark, description => $desc );
        text( $dom, $placemark, styleUrl    => $style );

        $placemark->appendWellBalancedChunk($kml);
    }

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
