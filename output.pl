use String::Util 'trim';
@files = <E:\\College\\Projects\\ZLearnPerl\\csv\\*>;

open( O, '>', 'result.csv' );
my @line = ();
foreach (@files) {
	open( INPUTFILE, '<', $_ ) or die "Could not open file\n";
	$i = 1;
	while ( my $temp = <INPUTFILE> ) {
		push( @line, $i++  );
		@templine = split( ",", $temp );

		push( @line, @templine );
	}
	
	foreach(@line){
		$_=trim($_);
		$_=$_.',';
	}

	if ( scalar @line == 14 ) {
		print O "@line";
		print O "\n";
	}
	

	@line = ();

	close INPUTFILE;
}
