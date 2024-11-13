#!/usr/bin/perl

use v5.36;
use List::Util      qw(zip sum);
use List::SomeUtils qw(pairwise);
use Math::Trig      qw(rad2deg);
use POSIX           qw(hypot atan2);

@ARGV == 2 or die "usage: $0 fromfile tofile\n";

my ( @x, @y );
open my $f1, '<', $ARGV[0];
while (<$f1>) {
    chomp;
    my ( $x, $y ) = split;
    push @x, $x;
    push @y, $y;
}
my ( @X, @Y );
open my $f2, '<', $ARGV[1];
while (<$f2>) {
    chomp;
    my ( $x, $y ) = split;
    push @X, $x;
    push @Y, $y;
}

# means
my $xs = ( sum @x ) / @x;
my $ys = ( sum @y ) / @y;
my $Xs = ( sum @X ) / @X;
my $Ys = ( sum @Y ) / @Y;

# centroid coords
my @xb = map { $_ - $xs } @x;
my @yb = map { $_ - $ys } @y;
my @Xb = map { $_ - $Xs } @X;
my @Yb = map { $_ - $Ys } @Y;

# summations
my $xx = sum pairwise { $a * $b } @xb, @xb;
my $xX = sum pairwise { $a * $b } @xb, @Xb;
my $xY = sum pairwise { $a * $b } @xb, @Yb;
my $yy = sum pairwise { $a * $b } @yb, @yb;
my $yX = sum pairwise { $a * $b } @yb, @Xb;
my $yY = sum pairwise { $a * $b } @yb, @Yb;

# helmert parameters
my $a  = ( $xX + $yY ) / ( $xx + $yy );
my $b  = ( $xY - $yX ) / ( $xx + $yy );
my $x0 = $Xs - $a * $xs + $b * $ys;
my $y0 = $Ys - $b * $xs - $a * $ys;

# residuals
foreach ( zip \@x, \@y, \@X, \@Y ) {
    my ( $x, $y, $X, $Y ) = @$_;
    my $Xn = $x0 + $a * $x - $b * $y;
    my $Yn = $y0 + $b * $x + $a * $y;
    printf "%12.3f %12.3f %+8.3f %+8.3f\n", $Xn, $Yn, $Xn - $X, $Yn - $Y;
}

# scale and rotation;
my $s = hypot $a, $b;
my $t = -3600 * rad2deg atan2 $b, $a;

say "\na,b,x,y,X,Y";
say "$a,$b,$xs,$ys,$Xs,$Ys\n";

print "+proj=helmert +convention=coordinate_frame ";
printf "+x=%.5f +y=%.5f +s=%.16g +theta=%.16g\n\n", $x0, $y0, $s, $t;

say "-transform_affine \\";
printf "%.16g,%.16g,%.5f,%.5f \\\n\n", $s, $t, $x0, $y0;

say "-transform_matrix \\";
printf
    "%.16g,%.16g,0 \\\n%.16g,%.16g,0 \\\n0,0,1 \\\n%.5f,%.5f,0 \\\n\n",
    $a, -$b, $b, $a, $x0, $y0;

# vim: ft=perl:sts=4:sw=4:et
