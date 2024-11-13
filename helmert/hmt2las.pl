#!/usr/bin/perl

use v5.36;
use POSIX      qw(hypot atan2);
use Math::Trig qw(rad2deg);

@ARGV == 1 or die "usage: $0 hmtfile";

open my $fh, '<', $ARGV[0];
my ( $a, $b, $xm, $ym, $XM, $YM ) = split /,/, <$fh>;
my $x = $XM - $a * $xm + $b * $ym;
my $y = $YM - $b * $xm - $a * $ym;
my $s = hypot $a, $b;
my $t = -3600 * rad2deg atan2 $b, $a;

#say "+proj=helmert +convention=coordinate_frame +x=$x +y=$y +s=$s +theta=$t";

say "-transform_affine \\";
printf "%.16f,%.16f,%.5f,%.5f \\\n", $s, $t, $x, $y;

# vim: ft=perl:sts=4:sw=4:et
