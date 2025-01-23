#!/usr/bin/perl
use v5.38;

use lib '.';
require 'project12d.pm';

my $project = Project->new();
$project->set_cs( "EPSG:28356", "EPSG:4283" );
$project->read12da( glob '*.12da' );

#$project->dump;

open my $fh, '>', 'romast.kml';
say $fh $project->tokml('roma st');

my $schema   = 'romastreet';
my $dbname   = 'gis';
my $host     = 'spiro.local';
my $username = 'gis';
my $password = 'gis';

$project->makedb(
    {   schema   => $schema,
        dbname   => $dbname,
        host     => $host,
        username => $username,
        password => $password
    }
);
