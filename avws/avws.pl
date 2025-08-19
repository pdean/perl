#!/usr/bin/env perl
# vim:ft=perl:sts=4:sw=4:et

use v5.36;
use aliased 'Geo::Proj::CCT';
use POSIX qw(copysign);

# EDITS

my $zone = 56;
my $lat1 = degmin( -23, 27 );
my $lat2 = degmin( -22, 30 );
my $lon1 = degmin( 149, 54 );
my $lon2 = degmin( 150, 51 );
my $tiff = "au_ga_AGQG_20201120.tif";

# coord system mga to lonlat
my $mga = CCT->crs2crs( "EPSG:78" . $zone, "EPSG:7844" )->norm;

# coord system mga eht to mga avws
my $avws
    = CCT->create( "+proj=pipeline +zone=$zone +south +ellps=GRS80"
        . " +step +inv +proj=utm"
        . " +step +proj=vgridshift +grids=$tiff"
        . " +step +proj=utm" );

# loops step by minute
for ( my $lat = $lat1; $lat <= $lat2; $lat++ ) {
    for ( my $lon = $lon1; $lon <= $lon2; $lon++ ) {

        # convert lonlat minutes to degrees to mga to avws
        my $pos
            = $avws->fwd( $mga->inv( [ $lon / 60.0, $lat / 60.0, 0.0 ] ) );
        printf "%.3f,%.3f,%.3f\n", @$pos;
    }
}

sub degmin {
    my ( $deg, $min ) = @_;
    return $deg * 60 + copysign( $min, $deg );
}

