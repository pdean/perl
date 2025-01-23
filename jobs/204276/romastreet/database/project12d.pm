
use v5.38;

# ----------------------------

package Project;
use File::BOM ':all';
use Geo::Proj::CCT;
use Math::Complex;
use XML::LibXML;
use DBI;
use Moo;

has name    => ( is => 'rw', default => 'project' );
has cs      => ( is => 'rw', default => sub { return undef } );
has strings => ( is => 'ro', default => sub { return [] } );

sub str_add {
    my ( $self, $string ) = @_;
    push @{ $self->strings }, $string;
    return $self;
}

sub set_cs {
    my ( $self, $from, $to ) = @_;
    my $cs = Geo::Proj::CCT->crs2crs( $from, $to )->norm;
    $self->cs($cs);
}

sub read12da {
    my ( $self, $file ) = @_;

    my ( $name, $seg, $chainage, $string );
    my %count;
    my $instring = 0;

    open my $fh, '<:via(File::BOM)', $file;
    while ( my $line = <$fh> ) {
        chomp $line;
        if ($instring) {
            if ( $line =~ /\}/ ) {
                $instring = 0;
                $seg      = ++$count{$name};
                $string->seg($seg);
                $self->str_add($string);
            }
            else {
                my ( $x, $y ) = ( split( ' ', $line ) )[ 0, 1 ];
                my $point = Point->new( x => $x, y => $y );
                $string->pt_add($point);
            }
        }
        else {
            if ( $line =~ /^\s+name/ ) {
                $name = ( split " ", $line )[1];
                $name =~ tr/"//d;
            }
            if ( $line =~ /chainage/ ) {
                $chainage = ( split " ", $line )[1];
            }
            if ( $line =~ /data_3d/ ) {
                $instring = 1;
                $string = String->new( name => $name, chainage => $chainage );
            }
        }
    }
    close $fh;
    $self->geog_add;
    $self->ch_add;
}

sub geog_add {
    my ($self) = @_;
    foreach my $s ( @{ $self->strings } ) {
        foreach my $p ( @{ $s->points } ) {
            my ( $lam, $phi ) = @{ $self->cs->fwd( [ $p->x, $p->y ] ) };
            $p->lam($lam);
            $p->phi($phi);
        }
    }

}

sub ch_add {
    my ($self) = @_;
    foreach my $s ( @{ $self->strings } ) {
        my $chainage = $s->chainage;
        my @points   = @{ $s->points };
        my $start    = shift @points;
        $start->ch($chainage);
        my $p0 = cplx( $start->x, $start->y );

        for my $end (@points) {
            my $p1 = cplx( $end->x, $end->y );
            $chainage += abs( $p1 - $p0 );
            $end->ch($chainage);
            $p0 = $p1;
        }
    }
}

sub dump {
    my ($self) = @_;

    foreach my $s ( @{ $self->strings } ) {
        my ( $name, $seg, $chainage ) = ( $s->name, $s->seg, $s->chainage );
        say "$name $seg $chainage";
        foreach my $p ( @{ $s->points } ) {
            my ( $x, $y, $ch, $lam, $phi )
                = ( $p->x, $p->y, $p->ch, $p->lam, $p->phi );
            say "  $x $y $ch $lam $phi";
        }
    }
}

sub tokml {
    my ( $self, $file ) = @_;
    my $dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $kml = $dom->createElement('kml');
    $kml->setAttribute( 'xmlns', 'http://earth.google.com/kml/2.1' );
    $dom->setDocumentElement($kml);
    my $document = $dom->createElement('Document');
    $kml->appendChild($document);

    my $name = $dom->createElement('name');
    $name->appendTextNode($file);
    $document->appendChild($name);

    foreach my $s ( @{ $self->strings } ) {
        my $folder = $dom->createElement('Folder');
        $document->appendChild($folder);

        my $name = $dom->createElement('name');
        $name->appendTextNode( $s->name . ' ' . $s->seg );
        $folder->appendChild($name);

        my @line;

        for my $p ( @{ $s->points } ) {
            my $placemark = $dom->createElement('Placemark');
            $folder->appendChild($placemark);

            my $name = $dom->createElement('name');
            $name->appendTextNode( sprintf( "%.0f", $p->ch ) );
            $placemark->appendChild($name);

            my $point = $dom->createElement('Point');
            $placemark->appendChild($point);

            my $coordinates = $dom->createElement('coordinates');
            my $coord       = $p->lam . ',' . $p->phi;
            push @line, $coord;
            $coordinates->appendTextNode($coord);
            $point->appendChild($coordinates);

            my $desc
                = sprintf( "%.3f", $p->ch ) . '<br>'
                . $s->name . '<br>'
                . $s->seg . '<br>'
                . sprintf( "%.3f", $p->x ) . '<br>'
                . sprintf( "%.3f", $p->y ) . '<br>';

            my $description = $dom->createElement('description');
            $description->appendTextNode($desc);
            $placemark->appendChild($description);

            my $style_url = $dom->createElement('styleUrl');
            $style_url->appendTextNode('#info');
            $placemark->appendChild($style_url);
        }
        my $placemark = $dom->createElement('Placemark');
        $folder->appendChild($placemark);

        my $linestring = $dom->createElement('LineString');
        $placemark->appendChild($linestring);

        my $coordinates = $dom->createElement('coordinates');
        $coordinates->appendTextNode( join " ", @line );
        $linestring->appendChild($coordinates);

        my $style_url = $dom->createElement('styleUrl');
        $style_url->appendTextNode('#info');
        $placemark->appendChild($style_url);
    }

    my $style = $dom->createElement('Style');
    $document->appendChild($style);
    $style->setAttribute( id => 'info' );

    my $iconstyle = $dom->createElement('IconStyle');
    $style->appendChild($iconstyle);

    my $icon = $dom->createElement('Icon');
    $iconstyle->appendChild($icon);

    my $png
        = "http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png";
    my $href = $dom->createElement('href');
    $href->appendTextNode($png);
    $icon->appendChild($href);

    my $linestyle = $dom->createElement('LineStyle');
    $style->appendChild($linestyle);

    my $width = $dom->createElement('width');
    $width->appendTextNode("4.0");
    $linestyle->appendChild($width);

    return $dom->toString(1);
}

sub makedb {
    my ( $self, $arg_ref ) = @_;

    my $schema   = $arg_ref->{schema};
    my $dbname   = $arg_ref->{dbname};
    my $host     = $arg_ref->{host};
    my $username = $arg_ref->{username};
    my $password = $arg_ref->{password};

    my $dbh = DBI->connect( "dbi:Pg:dbname=$dbname;host=$host",
        $username, $password, { RaiseError => 1 } );

    my @sqls = (
        "DROP SCHEMA IF EXISTS $schema CASCADE",
        "CREATE SCHEMA $schema",
        "CREATE table $schema.points ( id serial primary key, name text, seg text, tdist float, geog geography(point, 7844))",
        "CREATE table $schema.segments ( id serial primary key, name text, seg text, tstart float, tend float, geog geography(linestring, 7844))",
        "CREATE INDEX idx_points_geog on $schema.points USING gist(geog)",
        "CREATE INDEX idx_segments_geog on $schema.segments USING gist(geog)"
    );

    for my $sql (@sqls) {
        say $sql;
        $dbh->do($sql) or die $dbh->errstr;
    }

    my $sqlpt
        = "INSERT INTO $schema.points (name, seg, tdist, geog) VALUES (?, ?, ?, ST_SetSRID(ST_Point(?, ?), 7844)::geography )";
    say "preparing statement";
    say $sqlpt;
    my $sthpt = $dbh->prepare($sqlpt) or die $dbh->errstr;

    my $sqlseg
        = "INSERT INTO $schema.segments (name, seg, tstart, tend,  geog) VALUES(?, ?, ?, ?, ST_SetSRID(ST_Makeline(ST_Point(?, ?), ST_Point(?, ?)), 7844)::geography )";
    say "preparing statement";
    say $sqlseg;
    my $sthseg = $dbh->prepare($sqlseg) or die $dbh->errstr;

    foreach my $s ( @{ $self->strings } ) {
        my ( $name, $seg, $chainage ) = ( $s->name, $s->seg, $s->chainage );
        say "db add $name $seg points ...";

        foreach my $p ( @{ $s->points } ) {
            my ( $x, $y, $ch, $lam, $phi )
                = ( $p->x, $p->y, $p->ch, $p->lam, $p->phi );
            $sthpt->execute( $name, $seg, $ch, $lam, $phi )
                or die $sthpt->errstr;
        }

        say "db add $name $seg segments ...";

        my @points = @{ $s->points };
        my $start  = shift @points;
        my ( $ch0, $lam0, $phi0 ) = ( $start->ch, $start->lam, $start->phi );

        for my $end (@points) {
            my ( $ch1, $lam1, $phi1 ) = ( $end->ch, $end->lam, $end->phi );
            $sthseg->execute( $name, $seg, $ch0, $ch1, $lam0, $phi0, $lam1,
                $phi1 )
                or die $sthseg->errstr;

            ( $ch0, $lam0, $phi0 ) = ( $ch1, $lam1, $phi1 );
        }
    }

    $dbh->disconnect;
}

# -------------------------------------------

package String;
use Moo;

has [qw(name chainage )] => ( is => 'ro', required => 1 );
has seg                  => ( is => 'rw', default  => 1 );
has points               => ( is => 'rw', default  => sub { return [] } );

sub pt_add {
    my ( $self, $point ) = @_;
    push @{ $self->points }, $point;
    return $self;
}

# ------------------------------------------

package Point;
use Moo;

has [qw( x y ch lam phi)] => ( is => 'rw', default => 0 );
