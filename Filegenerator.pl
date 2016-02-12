use File::Path qw(make_path remove_tree);

my @filenames = ( "a" .. "z" );
my @charset   = ( "a" ... "z", "A" ... "Z", "0" ... "9", " " );
my $counter   = 0;

#inpute pattern file (only size part)
open( INPUTFILE, "<newsize.txt" );

while ( my $inputline = <INPUTFILE> ) {
	make_path("patterns/$counter");
	@files = split( " ", $inputline );
	open( FILE2, ">patterns/$counter/composite.txt" )
	  or die "Can't open file for writing\n";
	for ( $line = 0 ; $line < scalar @files - 1 ; $line++ ) {
		open( FILE1, ">patterns/$counter/$filenames[$line].txt" )
		  or die "Can't open file for writing\n";

		for ( $i = 0 ; $i < $files[$line] ; $i++ ) {
			print FILE1 $charset[ rand( scalar @charset ) ];
			print FILE2 $charset[ rand( scalar @charset ) ];
		}

		close(FILE1);
	}
	close(FILE2);
	$counter++;
}

