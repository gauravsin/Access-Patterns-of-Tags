


$filename = ".csv";


for($i=0;$i<=114;$i++){
	open( DATAFILE, '<', $i.$filename );
	
	while(my $temp = <DATAFILE>){
		print $temp;
	}
	
	close DATAFILE;
}
