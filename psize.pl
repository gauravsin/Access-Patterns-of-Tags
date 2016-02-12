open( INPUTFILE, '<', 'input.txt' ) or die "Could not open file\n";
open( DATAFILE, '>', "output.csv" );

while (<INPUTFILE>) {

	if ( $_ =~ /Number of Distinct Elements : / ) {
		if ( $_ =~ /\d{1,10}/ ) {
			if ( $& != '0' ) {
				$temp = $& . ",";
			}
		}
	}

	if ( $_ =~ /LEVEL/ ) {
		$nt = $_;
		chomp($nt);
		$temp = $temp . $nt . ",";
	}

	if ( $_ =~ /Number of Combinations is / ) {
		$_ =~ s/Number of Combinations is //g;
		$temp = $temp . $_;
		print DATAFILE "$temp";
		$temp = '';
	}

}
