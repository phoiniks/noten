sub range {
    my ( $beginn, $ende, $schritt ) = @_;

    if ( $beginn == 0 ){
	$beginn = '0';
    }
    
    my $akkumulator = $beginn;
    my $anzahl = $ende / $schritt;
    my $merker = 1;
    
    return sub {
	if ( $merker == 1 && $beginn =~ m/\d+\.\d+/g ){
	    $merker++;
	    return sprintf "%f", $beginn;
	} elsif ( $merker == 1 && $beginn =~ m/\d+/g ){
	    $merker++;
	    return sprintf "%d", $beginn;
	}
	
	$ende -= $schritt;
	
	if ( $ende < 0 ) {
	    return undef;
	} elsif ( $ende > $beginn ) {
	    $anzahl--;
	    $akkumulator += $schritt;
	    return $akkumulator;
	}
    }
}

1

