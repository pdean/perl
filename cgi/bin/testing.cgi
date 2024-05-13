#!/usr/bin/perl -wT
# vim:ft=perl:sts=4:sw=4:et

use v5.36;

use CGI qw(:standard);
use CGI::Carp;
use XML::Simple;

sub kmlout {
    my ($name, $styles, $points) = (shift,shift,shift);
    my ($Doc, $Style, $Placemark) = ([],[],[]);
    push @$Doc, {
        name => [$name],
        Style => $Style,
        Placemark => $Placemark,
    };
    for my $style (@$styles) {
        my ($id,$color,$href) = @$style;
        push @$Style, {
            id => $id,
            IconStyle => [
                {
                    Icon => [{ href => [$href]}],
                    color => [$color]
                }
            ]
        }
    }
    for my $point (@$points) {
        my ($name, $lon, $lat, $z, $style, $desc) = @$point;
        push @$Placemark, {
            name => [$name],
            description => [$desc],
            styleUrl => ["#$style"],
            Point => [{coordinates => ["$lon,$lat,$z"]}],
        };
    }
    my $root = {Document => $Doc};
    return XMLout($root, RootName => 'kml');
}

my $href = 'http://maps.google.com/mapfiles/kml/pal4/icon46.png';
my $styles = [
    ['house','ff00ff00',$href],
    ['ground','ff7f00ff',$href]];

my $points = [];

my ($lon1,$lat1,$lon2,$lat2) = split /,/,param('BBOX');
my $lon0 = ($lon2 - $lon1)/2 + $lon1;
my $lat0 = ($lat2 - $lat1)/2 + $lat1;

my $params = {};
for my $key (param()) {
    my $val = param($key);
    $key =~ s/^\s+//; # remove leading whitespace
    $key =~ s/\s+$//; # remove trailing whitespace
    $val =~ s/^\s+//; # remove leading whitespace
    $val =~ s/\s+$//; # remove trailing whitespace
    $params->{$key} = $val;
} 

my $desc= "";
for my $key (keys %$params) {
    my $val = $params->{$key};
    $desc .= "\"$key\" => \"$val\",";
}
my $name = "View Centre";
my $style = 'ground';
push @$points, [$name, $lon0, $lat0, 0, $style, $desc];

my $kml =  kmlout('testing', $styles, $points);

#print header( "text/plain" );
print header( "application/vnd.google-earth.kml+xml" );
print $kml;

