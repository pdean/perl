#!/usr/bin/env perl
# vim:ft=perl:sts=4:sw=4:et

use strict;
use warnings;
use v5.36;
use DBI;
use XML::Simple;
use CGI qw(:standard);

sub poly {
    my $params = shift;
    my ($lon1,$lat1,$lon2,$lat2) = split /,/, $params->{BBOX};

    my $schema      = $params->{schema};
    my $table       = $params->{table};
    my $idx         = $params->{index};
    my $geom        = $params->{geom};
    my $epsg        = $params->{epsg};
    my $schematable = "${schema}.${table}";

    my $host        = 'localhost';
    #my $host        = 'droid2.local';
    my $dbname      = 'gis';
    my $username    = 'gis';
    my $password    = 'gis';

    my $dbh = DBI->connect(
        "dbi:Pg:dbname=$dbname;host=$host",
         $username, $password,
         {AutoCommit => 0, RaiseError => 1, PrintError => 0}
    );
    
    my $colquery = "select column_name "
                  ."from information_schema.columns " 
                  ."where table_name='$table' and table_schema='$schema' "
                  ."order by ordinal_position";
    my @columns;
    for my $row (@{$dbh->selectall_arrayref($colquery)}) {   
        my ($column) = @$row;
        next if ($column eq $idx);
        next if ($column eq $geom);
        push @columns, $column;
    }

    my ($Doc, $Style, $Folder) = ([],[],[]);
    push @$Doc, {
        name => [$params->{title}],
        Style => $Style,
        Folder => $Folder,
    };

    push @$Style, {
        id => 'NORMAL',
        LineStyle => [
            {
                color => [$params->{color}],
                width => [$params->{width}]
            }
        ],
        PolyStyle => [
            {
                fill => ['0'],
                outline => ['1']
            }
        ]
    };

    my $Placemark = [];
    push @$Folder, {
        name => [$schematable],
        Placemark => $Placemark
    };
    
    my $query; 
    $query .= " select st_askml($geom) as kml, ";
    $query .= join(',', @columns) ;
    $query .= " from $schematable  where $geom && ";
    $query .= " st_setsrid(st_makebox2d(st_point($lon1,$lat1),st_point($lon2,$lat2)),$epsg) ";
    if (exists $params->{where}) {
        $query .= " and $params->{where}";
    }   
    $query .= " limit 5000 ";

    for my $row (@{$dbh->selectall_arrayref($query)}) {   

        my $kml = shift @$row;
        my ($type, $geom) = %{XMLin($kml, keepRoot => 1, forceArray => 1)};

        my %values;
        for my $column (@columns) {
            my $val = shift @$row // 'NULL';
            $values{$column} = $val;
        }

        my $name;
        if ($values{$params->{name}} ne 'NULL') {
            $name = "$values{$params->{name}}";
        }
        elsif ($values{$params->{altname}} ne 'NULL') {
            $name = "$values{$params->{altname}}";
        }
        else {
            $name = "$values{$params->{altname2}}";
        }

        my ($ExtendedData, $Data) = ([],[]);
        for my $column (@columns) {
            push @$Data, {
                name => $column,
                value => [$values{$column}]
            }
        }
        push @$ExtendedData, {
            Data => $Data
        };

        push @$Placemark, {
            name => [$name],
            styleUrl => ['#NORMAL'],
            ExtendedData => $ExtendedData,
            $type => $geom
        };
    }

    my $root = {Document => $Doc};
    return XMLout($root, RootName => 'kml');
}

my $params = {};
for my $key (param()) {
    my $val = param($key);
    $key =~ s/^\s+//; # remove leading whitespace
    $key =~ s/\s+$//; # remove trailing whitespace
    $val =~ s/^\s+//; # remove leading whitespace
    $val =~ s/\s+$//; # remove trailing whitespace
    $params->{$key} = $val;
} 


my $kml = poly($params) ;
print header('application/vnd.google-earth.kml+xml');
print $kml;

