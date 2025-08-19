#!/usr/bin/env perl
# vim:ft=perl:sts=4:sw=4:et

use v5.36;
use aliased 'Geo::Proj::CCT';
use POSIX qw(copysign);

my $mga = CCT->crs2crs( "EPSG:7856", "EPSG:7844" )->norm;

my $S
    = " +proj=pipeline +zone=56 +south +ellps=GRS80"
    . " +step +inv +proj=utm"
    . " +step +proj=vgridshift +grids=au_ga_AGQG_20201120.tif"
    . " +step +proj=utm";
my $avws = CCT->create($S);

my $lat1 = minutes( -23, 27 );
my $lat2 = minutes( -22, 30 );
my $lon1 = minutes( 149, 54 );
my $lon2 = minutes( 150, 51 );

for ( my $lat = $lat1; $lat <= $lat2; $lat++ ) {
    for ( my $lon = $lon1; $lon <= $lon2; $lon++ ) {
        my $pos
            = $avws->fwd( $mga->inv( [ $lon / 60.0, $lat / 60.0, 0.0 ] ) );
        printf "%.3f,%.3f,%.3f\n", @$pos;
    }
}

sub minutes {
    my ( $deg, $min ) = @_;
    $min = copysign( $min, $deg );
    return $deg * 60 + $min;
}

