#!/usr/bin/env perl
# vim:ft=perl:sts=4:sw=4:et

use v5.36;
use aliased 'Geo::Proj::CCT';
use POSIX qw(copysign);

my $cs1 = CCT->crs2crs( "EPSG:7856", "EPSG:7844" )->norm;

my $S
    = " +proj=pipeline +zone=56 +south +ellps=GRS80"
    . " +step +inv +proj=utm"
    . " +step +proj=vgridshift +grids=au_ga_AGQG_20201120.tif"
    . " +step +proj=utm";
my $cs2 = CCT->create($S);

my $lat1 = minutes( -23, 27 );
my $lon1 = minutes( 149, 54 );
my $lat2 = minutes( -22, 30 );
my $lon2 = minutes( 150, 51 );

for ( my $latm = $lat1; $latm <= $lat2; $latm++ ) {
    for ( my $lonm = $lon1; $lonm <= $lon2; $lonm++ ) {
        my $lat  = $latm / 60.0;
        my $lon  = $lonm / 60.0;
        my $posd = [ $lon, $lat, 0.0 ];
        my $posm = $cs1->inv($posd);
        my $posa = $cs2->fwd($posm);
        printf "%.3f,%.3f,%.3f\n", @$posa;
    }
}

sub minutes {
    my ( $deg, $min ) = @_;
    $min = copysign( $min, $deg );
    return $deg * 60 + $min;
}

