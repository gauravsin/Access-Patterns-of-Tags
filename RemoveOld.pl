#Remove old files before starting
use strict;
use warnings;

my $i        = 0;
my $filename = "";

if ( -e "data.csv" ) {
	unlink "data.csv";
}

if ( -e "temp.txt" ) {
	unlink "temp.txt";
}

if ( -e "output.txt" ) {
	unlink "output.txt";
}

if ( -e "info.txt" ) {
	unlink "info.txt";
}

if ( -e "line.txt" ) {
	unlink "line.txt";
}

if ( -e "size.txt" ) {
	unlink "size.txt";
}

if ( -e "hashtable" ) {
	unlink "hashtable";
}

if ( -e "reversehashtable" ) {
	unlink "reversehashtable";
}

for ( $i = 1 ; $i <= 100 ; $i++ ) {
	$filename = "hashlevel" . $i;
	if ( -e "$filename" ) {
		unlink "$filename";
	}
}
