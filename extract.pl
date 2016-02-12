open( INPUTFILE, '<', 'input.txt' ) or die "Could not open file\n";
open( DATAFILE, '>', "output.csv" );

$count = 0;
while (<INPUTFILE>) {

	if ( $_ =~ /end/ ) {
		if ( $_ =~ /\d{1,10}/ ) {
			$line[ $count ] = $line[ $count ].$&;
			$count++;
		}

		if ( $_ =~ /Iter/ ) {
			foreach (@line) {
				$_ = $_ . ",";
			}
			$count=0;
		}
	}
}

foreach (@line) {
	print DATAFILE "$_\n";
}
