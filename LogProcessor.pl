use strict;
use warnings;

my $logfile         = "access_log";     #Input log file
my $linefile        = "line.txt";    #Temporary log file
my $linecounter     = 1;             # For counting number of lines
my $prevlinecounter = 1;             # For storing previos line counter
my $maxlines        = 10000;         #Number of lines taken from log
my $windowsize      = 1000;          #Number of sessions to be divided into
my $support         = 0.02;          #Apriori support level
my $noofiterations  = 100;             #Apriori iterations
my $start           = time;          #For timing

#delete old information
system("perl RemoveOld.pl");

open( INPUTFILE,  '<', $logfile )  or die "Could not open $logfile\n";
open( OUTPUTFILE, '>', $linefile ) or die "Could not open $linefile\n";
while ( my $logline = <INPUTFILE> ) {
	if ( $linecounter % $maxlines == 0 || eof ) {
		close OUTPUTFILE;
		print "Processing lines from : $prevlinecounter to $linecounter \n";
		system("perl sessionMS.pl $linefile $windowsize $support $noofiterations");
		print "\n";
		$prevlinecounter = $linecounter + 1;
		open( OUTPUTFILE, '>', $linefile ) or die "Could not open $linefile\n";
	}
	$linecounter++;
	print OUTPUTFILE $logline;
}

close INPUTFILE;
close OUTPUTFILE;
print "Time taken for complete process is ", -( $start - time ), "\n";
print "Log Processor Completed\n";
