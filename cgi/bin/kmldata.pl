
our %configs;

$configs{lots} = {
    schema   => 'qspatial',
    table    => 'qld_cadastre_dcdb',
    index    => 'objectid',
    geom     => 'o_shape',
    epsg     => '7844',
    title    => 'dcdb 2020',
    name     => 'lotplan',
    altname  => 'feat_name',
    altname2 => 'alias_name',
    color    => 'ffffffff',
    width    => '2',
    where    => q(parcel_typ ~ '^Lot')
};

$configs{roadcorridors} = {
    schema   => 'qspatial',
    table    => 'qld_cadastre_dcdb',
    index    => 'objectid',
    geom     => 'o_shape',
    epsg     => '7844',
    title    => 'dcdb_2020',
    name     => 'lotplan',
    altname  => 'feat_name',
    altname2 => 'alias_name',
    color    => 'ffffffff',
    width    => '2',
    where    => q(parcel_typ ~ '^Road|^Unlinked')
};

$configs{everything} = {
    schema   => 'qspatial',
    table    => 'qld_cadastre_dcdb',
    index    => 'objectid',
    geom     => 'o_shape',
    epsg     => '7844',
    title    => 'dcdb_2020',
    name     => 'lotplan',
    altname  => 'feat_name',
    altname2 => 'alias_name',
    color    => 'ffffffff',
    width    => '2',
};

$configs{locality} = {
    schema  => 'qspatial',
    table   => 'locality_boundaries',
    index   => 'objectid',
    geom    => 'shape',
    epsg    => '7844',
    title   => 'Locality',
    name    => 'locality',
    altname => 'locality',
    color   => 'ff00afff',
    width   => '3',
};

