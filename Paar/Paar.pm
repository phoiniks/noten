sub paar {
    my ( $anfang, $ende ) = @_;

    my @liste = $anfang..$ende;

    \@liste;
}

sub intervalle {
    my $liste = shift;

    my @paarung;
    my $count = 0;

    for my $element ( @$liste ){
	if ( $element == 0 ){
	    push @paarung, [ $element, $liste->[++$count] ];
	} elsif ( $element != $liste->[scalar @$liste - 1]) {
	    $element++;
	    push @paarung, [ $element, $liste->[++$count] ];
	} else {
	    last;
	}
    }


    my %paarung = map { $_->[0] => $_->[1] } @paarung;

    \%paarung;
}

1
