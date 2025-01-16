#!/usr/bin/env perl
# vim:ft=perl:sts=4:sw=4:et

use strict;
use warnings;
use v5.36;
use DBI;
use XML::Simple;
use CGI          qw(:standard);
use experimental qw(builtin);
use builtin      qw(trim);
use Net::Domain  qw(hostfqdn);

sub scdb {
    my $params = shift;
    my ( $lon1, $lat1, $lon2, $lat2 ) = split /,/, $params->{BBOX};

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

    my ( $Doc, $Style, $Folder, $Placemark ) = ( [], [], [], [] );
    push @$Doc,
        {   name   => [$tab],
            Style  => $Style,
            Folder => $Folder,
        };

    my $png = 'PMCode';
    my @codes
        = qw(  2   6  10  14  18  22  26  30  38  46  54  62  82  86  90  94 118 126
        130 134 138 142 146 150 154 158 166 174 182 190 210 214 218 222 246 254);

    for my $code (@codes) {
        my $file = "http://$site/pmsymbols/$png$code.png";
        push @$Style,
            {   id        => "$png$code",
                IconStyle => [
                    {   scale => ['2'],
                        Icon  => [ { href => [$file] } ]
                    }
                ]
            };
    }

    push @$Folder,
        {   name      => ['SCDB'],
            Placemark => $Placemark,
        };

    my $query;
    $query .= " select st_askml(st_force3dz($geom)) as kml,mrk_id,code ";
    $query .= " from $table where $geom && ";
    $query
        .= "  st_setsrid(st_makebox2d(st_point($lon1,$lat1),st_point($lon2,$lat2)),4283) ";
    if ( exists $params->{where} ) {
        $query .= " and $params->{where}";
    }
    $query .= " limit 1000 ";

    for my $row ( @{ $dbh->selectall_arrayref($query) } ) {
        my ( $kml, $mark, $code ) = @$row;
        my $pdf  = sprintf "SCR%06d.pdf", $mark;
        my $link = "http://qspatial.information.qld.gov.au/SurveyReport/$pdf";
        my $desc = "<a href=\"$link\"> Survey Report </a>";
        my $style = "#PMCode$code";
        my ( $type, $geom )
            = %{ XMLin( $kml, keepRoot => 1, forceArray => 1 ) };

        push @$Placemark,
            {   name        => [$mark],
                description => [$desc],
                styleUrl    => [$style],
                $type       => $geom,
            };
    }

    my $root = { Document => $Doc };
    return XMLout( $root, RootName => 'kml' );
}

my $params;
for my $key ( param() ) {
    $params->{ trim($key) } = trim( param($key) );
}

print header('application/vnd.google-earth.kml+xml');
print scdb($params);

