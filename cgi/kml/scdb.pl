
our %configs;

$configs{good} = { where => q(mrkcnd_de='GOOD') };

$configs{gda2020datum}
    = { where => q(mrkcnd_de='GOOD' and gda2020lineage_de='Datum') };

$configs{ahddatum}
    = { where => q(mrkcnd_de='GOOD' and ahdlineage_de='Datum') };

