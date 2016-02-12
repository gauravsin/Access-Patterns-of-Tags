#use strict;
use warnings;                     #for displaying warnings
use Date::Parse;                  #for converting date format
use String::Util 'trim';          #for removing trailing and leading spaces
use Data::PowerSet 'powerset';    #for generating subsets of pattern
use Algorithm::Combinatorics qw(combinations); #for generating combinations
use Storable;                                  #for storing hash values to files

####################################################################
#initializing all required variables

my $tempfile         = "temp.txt";
my $infofile         = "info.txt";
my $processeddata    = "data.csv";
my $outputfile       = "output.txt";
my $outputfile2      = "size.txt";
my @resultarray      = ();            #for storing the values
my @auxref           = ();            #for storing the temporary values
my %frequency        = ();            #for calculating the frequency for Apriori
my %hashtable        = ();            #for hashing in Apriori
my %reversehashtable = ();            #for unhashing in Apriori
my @inputarray       = ();            #array for Apriori Algorithm

my ( $i, $j, $k ) = 0;                #for iteration
my $n         = 0;                    #for number of elements in the $inputlog
my $hashValue = 0;                    #hash values for %hashtable as a counter
my ( $hi, $lo ) = 0;                  #for mergeSort bounds
my $temp             = '';         #for url inputs
my $formattemp       = '';         #for url formatting
my $deletetemp       = '';         #holder for deleting entries in hash tables
my $ip_value         = 0;          #for IP address without . character
my $stored_IP        = 0;          #for sessionizing using IP
my $stored_TS        = 0;          #for sessionizing using Timestamp
my $sessionline      = '';         #for concatenating entries of a session
my $hashfilename     = '';         #for hash file names
my $oldsessionval    = 0;          #for creating rows for Apriori
my $counter          = 0;          #Session Counter
my $TS_dif           = 10 * 60;    #Session window (10 minutes)
my $currenthashValue = 0;          #store temporary hash value
my $windowsize       = 0;          #information on number of sessions
my $difference       = 0;          #difference between current and $windowsize

####################################################################

####################################################################
#sub parseLog starts here
sub parseLog {

	my $inputlog  = $_[0];
	my $linecount = 0;
	open( INPUTFILE, '<', $inputlog )
	  or die "Could not open $inputlog\n";

	#Parsing input into a table
	while ( my $log_line = <INPUTFILE> ) {
		chomp $log_line;

		#Getting File Path and protocol only for GET
		if ( $log_line =~ /GET (.+?) 200 (.+?) / ) {
			$temp = $formattemp = $&;
			$formattemp =~ s/GET \/| HTTP(.+?)* 200 (.+?)*//g;
			if ( $formattemp eq "" ) {
				next;    #storing only statements which have an address
			}

			$resultarray[$i][2] = $temp;
			$linecount++;
		}
		else {
			$linecount--;
			next;        #storing only the GET statements
		}

		#Getting IP address
		if ( $log_line =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/ ) {
			$ip_value = $&;
			$ip_value =~ s/\.//g;
			$resultarray[$i][0] = $ip_value;
		}
		else {
			$linecount--;
			next;
		}

		#Getting Timestamp
		if ( $log_line =~ /\d{2}(.){5}\d{4}:\d{2}:\d{2}:\d{2}/ ) {
			$resultarray[$i][1] = str2time($&);
		}
		else {
			$linecount--;
			next;
		}
		$i++
		  ; #incrementing to next element location only if all the data was successfull retrieved
	}
	$n = scalar @resultarray;
	if (   !defined $resultarray[ $n - 1 ][0]
		|| !defined $resultarray[ $n - 1 ][1]
		|| !defined $resultarray[ $n - 1 ][2] )
	{
		print "Last element undef\n";
		splice @resultarray, $n - 1, 1;
	}
	$n = scalar @resultarray;    #number of elements in resultarray
	print "Number of lines in the log : $n\n";
}    # sub parseLog ends
####################################################################

####################################################################
#sub mergeSort starts here
sub mergeSort {

	my ($aref)   = $_[0];
	my ($auxref) = $_[1];
	my $lo       = $_[2];
	my $hi       = $_[3];

	if ( $hi <= $lo ) { return; }
	my $mid = 0;
	$mid = int( $lo + ( $hi - $lo ) / 2 );
	mergeSort( $aref, $auxref, $lo,      $mid );
	mergeSort( $aref, $auxref, $mid + 1, $hi );
	merge( $aref, $auxref, $lo, $mid, $hi );

}    #sub mergeSort ends
####################################################################

####################################################################
#sub merge of mergeSort begins
sub merge {

	my ($aref)   = $_[0];
	my ($auxref) = $_[1];
	my $lo       = $_[2];
	my $mid      = $_[3];
	my $hi       = $_[4];

	for ( $i = $lo ; $i <= $hi ; $i++ ) {
		$auxref->[$i][0] = $aref->[$i][0];
		$auxref->[$i][1] = $aref->[$i][1];
		$auxref->[$i][2] = $aref->[$i][2];
	}
	$i = $lo;
	$j = $mid + 1;

	for ( $k = $lo ; $k <= $hi ; $k++ ) {
		if ( $i > $mid ) {
			$aref->[$k][0] = $auxref->[$j][0];
			$aref->[$k][1] = $auxref->[$j][1];
			$aref->[$k][2] = $auxref->[$j][2];
			$j++;
		}
		elsif ( $j > $hi ) {
			$aref->[$k][0] = $auxref->[$i][0];
			$aref->[$k][1] = $auxref->[$i][1];
			$aref->[$k][2] = $auxref->[$i][2];
			$i++;
		}
		elsif ( $auxref->[$i][0] <= $auxref->[$j][0] ) {
			$aref->[$k][0] = $auxref->[$i][0];
			$aref->[$k][1] = $auxref->[$i][1];
			$aref->[$k][2] = $auxref->[$i][2];
			$i++;
		}
		else {
			$aref->[$k][0] = $auxref->[$j][0];
			$aref->[$k][1] = $auxref->[$j][1];
			$aref->[$k][2] = $auxref->[$j][2];
			$j++;
		}
	}

}    #sub merge ends
####################################################################

####################################################################
#sub createSession starts here
sub createSession {

	#creating sessions here
	$stored_IP         = $resultarray[0][0];
	$stored_TS         = $resultarray[0][1];
	$resultarray[0][3] = 0;

	for ( $i = 1 ; $i < $n ; $i++ ) {
		if ( $resultarray[$i][0] != $stored_IP ) {
			$counter++;
			$stored_IP          = $resultarray[$i][0];
			$stored_TS          = $resultarray[$i][1];
			$resultarray[$i][3] = $counter;
		}
		elsif ( ( $resultarray[$i][1] - $stored_TS ) > $TS_dif ) {
			$counter++;
			$stored_IP          = $resultarray[$i][0];
			$stored_TS          = $resultarray[$i][1];
			$resultarray[$i][3] = $counter;
		}
		else {
			$resultarray[$i][3] = $counter;
		}

	}

}    #sub createSession ends

####################################################################

####################################################################
#sub printToFile starts here
sub printToFile {
	open( DATAFILE, '>', $processeddata )
	  or die "Could not open $processeddata\n";
	print DATAFILE "The number of rows processed was $n\n";
	print DATAFILE "IP ADDRESS,TIMESTAMP,FILE,SESSION NUMBER\n";

	#print output of phase 1 in data.csv file
	for ( $i = 0 ; $i < $n ; $i++ ) {
		print DATAFILE
"$resultarray[$i][0],$resultarray[$i][1],$resultarray[$i][2],$resultarray[$i][3]\n";
	}

}    #sub printToFile ends
####################################################################

####################################################################
#sub createList starts here
sub createList {

	$oldsessionval = -1;    #to make zero also a session
	$counter       = 0;     #Used to eliminate sessions with one entry
	     #appending to the temp file storing the previous information.
	open( TEMPWRITER, '>>', $tempfile ) or die "Could not open $tempfile\n";

	$hashfilename = 'hashtable';
	if ( -e $hashfilename ) {

		#Information from previous Apriories
		%hashtable = %{ retrieve($hashfilename) };
	}

	$hashfilename = 'reversehashtable';
	if ( -e $hashfilename ) {

		#Information from previous Apriories
		%reversehashtable = %{ retrieve($hashfilename) };
	}

	if ( -e $infofile ) {
		open( SAVEDINFO, '<', $infofile ) or die "Could not open $infofile\n";
		$hashValue = <SAVEDINFO>;
		close SAVEDINFO;
	}

	print "Starting Hash Value is " . $hashValue . "\n";

	for ( $i = 0 ; $i < $n ; $i++ ) {
		if ( $oldsessionval < $resultarray[$i][3] ) {

			#new session so terminating the line
			$sessionline .= " \n";
			if ( $counter > 1 ) {

				#only writing if there are more than one entry in a session
				print TEMPWRITER $sessionline;
			}
			$sessionline   = '';
			$counter       = 0;
			$oldsessionval = $resultarray[$i][3];
		}

		$sessionline .= " ";

		$resultarray[$i][2] = trim( $resultarray[$i][2] );

		if ( exists $hashtable{ $resultarray[$i][2] } ) {
			$currenthashValue = $hashtable{ $resultarray[$i][2] };
			$sessionline .= $currenthashValue;
			$counter++;
		}
		else {
			$hashtable{ $resultarray[$i][2] } = $hashValue;
			$reversehashtable{$hashValue} = $resultarray[$i][2];
			$sessionline .= $hashValue;
			$hashValue++;
			$counter++;
		}

		#clearing the row which has been processed
		$resultarray[$i][0] = undef;
		$resultarray[$i][1] = undef;
		$resultarray[$i][2] = undef;
		$resultarray[$i][3] = undef;

	}

	#Storing Straight Hash Value table for the current level
	$hashfilename = 'hashtable';
	store \%hashtable, $hashfilename;

	#Storing Reverse Hash Value table for the current level
	$hashfilename = 'reversehashtable';
	store \%reversehashtable, $hashfilename;

	# emptying the resultarray releasing memory
	open( SAVEDINFO, '>', $infofile ) or die "Could not open $infofile\n";
	print SAVEDINFO $hashValue;
	close SAVEDINFO;
	@resultarray = ();
	close TEMPWRITER;

}    #sub createList ends here
####################################################################

####################################################################
#sub formatLevels starts here
sub formatLevels {
	$windowsize = $_[0];

	#taking input of sessions from file and removing lines out of session range
	open( WRITER, '<', $tempfile ) or die "Could not open $tempfile\n";
	$i = 0;
	while (<WRITER>) {
		chomp;
		$inputarray[ $i++ ] = $_;
	}
	close WRITER;
	print "Original number of sessions in file :", scalar @inputarray, "\n";
	$difference = ( scalar @inputarray ) - $windowsize;
	print "Number of Sessions Exceeding Window Size : $difference\n";

	if ( $difference > 0 ) {

		#removing old lines from the file
		splice @inputarray, 0, $difference;
		open( WRITER, '>', $tempfile ) or die "Could not open $tempfile\n";
		foreach (@inputarray) {
			print WRITER "$_\n";
		}
		close WRITER;

		#removing useless elements from hashlevels higher than 1

		for ( $l = 1 ; $l <= 10 ; $l++ ) {
			$hashfilename = 'hashlevel' . $l;
			if ( -e $hashfilename ) {
				%counts = %{ retrieve($hashfilename) };

			 #removing all the lines which no longer exist in the session window
				foreach ( keys %counts ) {
					for ( $i = scalar @{ $counts{$_} } - 1 ; $i >= 0 ; $i-- ) {
						if ( ${ $counts{$_} }[$i] < $difference ) {
							splice @{ $counts{$_} }, $i, 1;
						}
						else {
							${ $counts{$_} }[$i] =
							  ${ $counts{$_} }[$i] - $difference;
						}
					}
				}

				#removing hash keys with null values;
				foreach ( keys %counts ) {
					if ( scalar @{ $counts{$_} } <= 0 ) {
						delete $counts{$_};
					}
				}

				#Storing Hash Value table for the current level
				store \%counts, $hashfilename;
				%counts = ();
			}
		}

	}
	else {
		print "Inside window size so not eliminating anything\n";
	}

}    #sub formatLevels ends here
####################################################################

####################################################################
#sub apriori starts here
sub apriori {
	my ( $i, $j, $k, $l, $p ) = 0;
	my $flag   = 1;    #for testing wheter all subparts matched
	my %counts = ();   #hash table storing the elements and their distinct count
	my %newcounts = ()
	  ; #hash table storing the elements for finding distinct elements iteratively
	my @tempiparray      = ();    # Level 1 temp array
	my @distinctelements = ();    #holds all the disting elements
	my @apriorirow = (); #consists of rows of apriori table generated using glob
	my @rowelements =
	  ();    #consists of individual elements of apriori row for comparing
	my @countvalues =
	  ();    # contains values which are used for elimination of elements
	my @res            = ();       #for results of permutation of subsets
	my $temp           = '';       #temp string for string operations
	my $iptemp         = '';       #temp string for string operations
	my $support        = $_[0];    #minimum support
	my $nooflines      = 0;        #total number of input lines
	my $currentval     = 0;        #value of current element
	my $noofiterations = $_[1];    #set number of Apriori Levels
	my $distinctelementstring = ''; #string of distinct elements for permutation
	my $nameofArray           = ''; #for element arrays
	my $pattern               = ''; #for patterns in removal
	my $formattemp1           = ''; #for outputting required URL
	my $formattemp2           = ''; #for outputting required URL size

	open( OWRITER,  '>', $outputfile )  or die "Could not open $outputfile\n";
	open( OWRITER2, '>', $outputfile2 ) or die "Could not open $outputfile2\n";
	print "Number of sessions created : ", scalar @inputarray, "\n";

	#Loading hash values from previous files
	$hashfilename = 'hashlevel1';
	if ( -e $hashfilename ) {

		#Information from previous Apriories
		%counts = %{ retrieve($hashfilename) };
	}

	#Single element count by inserting the line number in the array
	for ( $i = 0 ; $i < scalar @inputarray ; $i++ ) {
		@tempiparray = split( " ", $inputarray[$i] );
		foreach (@tempiparray) {
			if ( exists $counts{$_} ) {
				push( $counts{$_}, $i );
			}
			else {
				$nameofArray = '@arrayvalue' . "$_";
				$counts{$_} = \@$nameofArray;
				push( $counts{$_}, $i );
			}
		}
	}

	$nooflines = scalar @inputarray;

	#writing elements to the file only above the support;
	print OWRITER "================================================\n";
	print OWRITER "LEVEL 1 STARTS\n";
	print OWRITER2 "================================================\n";
	print OWRITER2 "LEVEL 1 STARTS\n";

	foreach ( keys %counts ) {

		$currentval = scalar @{ $counts{$_} };
		my $currentSupport = $currentval / $nooflines;
		if ( $currentSupport >= $support ) {
			$formattemp1 = $reversehashtable{$_};
			$formattemp2 = $reversehashtable{$_};
			$formattemp1 =~ s/GET \/| HTTP(.+?)*//g;
			$formattemp2 =~ s/(.+?) (.+?) (.+?) (.+?) //g;
			print OWRITER "$formattemp1 => ",
			  scalar @{ $counts{$_} },
			  "	    HAS SUPPORT  ",
			  $currentSupport,
			  "\n";

			print OWRITER2 "$formattemp2 $currentSupport\n";
		}
		$currentSupport = 0;
		$currentval     = 0;
	}

	print OWRITER "================================================\n";
	print OWRITER2 "================================================\n";
	my @tempdistinctelements = keys %counts;

	$i = 0;
	foreach (@tempdistinctelements) {
		$currentval = scalar @{ $counts{$_} };
		my $currentSupport = $currentval / $nooflines;
		if ( $currentSupport >= $support / 2 ) {
			$distinctelements[ $i++ ] = $_;
		}
	}

	print "Number of Distinct Elements : ", scalar @distinctelements,
	  "\n",
	  "Distinct Elements :   @distinctelements \n";

	foreach (@distinctelements) {
		$_ .= "A";
	}

	$distinctelementstring = [@distinctelements];

	#Storing Hash Value table for the current level
	$hashfilename = 'hashlevel1';
	store \%counts, $hashfilename;

	#Single element phase complete
	%counts      = ();
	@tempiparray = ();
	$currentval  = 0;

	for ( $i = 2 ; $i <= $noofiterations ; $i++ ) {
		print "LEVEL $i STARTS\n";

		#generating new patterns depending on old ones

		if ( scalar @distinctelements < $i ) {
			print $i,
			  " <- less elements than level of iteration so stopping \n";
			last;
		}

		$k = 0;
		if ( $i > 2 ) {
			my $iter = combinations( $distinctelementstring, $i );
			while ( my $c = $iter->next ) {
				@rowelements = split( "A", "@$c" );
				foreach (@rowelements) {
					$_ = trim($_) . "A";
				}

				#As a patern of level $n will have subsets of size $n-1
				my $powerset =
				  powerset( { min => $i - 1, max => $i - 1 }, @rowelements );
				for my $p (@$powerset) {
					$pattern = trim("@$p");
					if ( exists $counts{$pattern} ) {
						$currentval = scalar @{ $counts{$pattern} };
						my $currentSupport = $currentval / $nooflines;
						if ( $currentSupport >= $support / 2 ) {

							#The divide by 2 ensures 50% leniency for old lines
							$apriorirow[ $k++ ] = "@$c";
							last;
						}
					}
				}
			}
		}
		else {
			my $iter = combinations( $distinctelementstring, $i );
			while ( my $c = $iter->next ) {
				$apriorirow[ $k++ ] = "@$c";
			}
		}

		print "Number of Combinations is " . scalar @apriorirow . "\n";
		%counts = ();

		#Loading hash values from previous files
		$hashfilename = 'hashlevel' . $i;
		if ( -e $hashfilename ) {

			#Information from previous Apriories
			%counts = %{ retrieve($hashfilename) };
		}

		for ( $l = 0 ; $l < scalar @apriorirow ; $l++ ) {

		 #Turning a apriorirow into individual elements and removing delimiter A
			@rowelements = split( "A", $apriorirow[$l] );
			foreach (@rowelements) {
				$_ =~ s/A//g;
				$_ = trim($_);
			}

		   #testing whether all the elements of rowelements are present in input
			for ( $j = 0 ; $j < scalar @inputarray ; $j++ ) {
				$iptemp = $inputarray[$j];

				for ( $k = 0 ; $k < scalar @rowelements ; $k++ ) {
					$temp = $rowelements[$k];

					if ( ( $iptemp =~ / $temp / ) != 1 ) {

						#match not found
						$flag = 0;
						last;
					}
					else {
						$iptemp =~ s/ $temp / ~ /g;
					}
					$temp = '';
				}    #rowelement for end
				$iptemp = '';

				if ( $flag == 1 ) {
					if ( exists $counts{ $apriorirow[$l] } ) {
						push( $counts{ $apriorirow[$l] }, $j );
					}
					else {
						$nameofArray = '@arrayvalue' . "$apriorirow[$l]";
						$counts{ $apriorirow[$l] } = \@$nameofArray;
						push( $counts{ $apriorirow[$l] }, $j );
					}
				}

				$flag = 1;

			}    #inputarray for end

		}    #apriorirow for end

		#writing elements to the file only above the support;
		print OWRITER "================================================\n";
		print OWRITER "LEVEL $i STARTS\n";
		print OWRITER2 "================================================\n";
		print OWRITER2 "LEVEL $i STARTS\n";
		foreach ( keys %counts ) {
			$currentval = scalar @{ $counts{$_} };
			my $currentSupport = $currentval / $nooflines;
			if ( $currentSupport >= $support ) {

				#separating the elemts using delimiter A and unhashing
				@rowelements = split( "A", $_ );
				foreach (@rowelements) {
					$_ =~ s/A//g;
					$_ = trim($_);
					$newcounts{$_}++;
					$formattemp1 = $reversehashtable{$_};
					$formattemp2 = $reversehashtable{$_};
					$formattemp1 =~ s/GET \/| HTTP(.+?)*//g;
					$formattemp2 =~ s/(.+?) (.+?) (.+?) (.+?) //g;
					print OWRITER "$formattemp1  ||  ";
					print OWRITER2 "$formattemp2 ";
				}

				print OWRITER "=> ", scalar @{ $counts{$_} },
				  "	    HAS SUPPORT  ",
				  $currentSupport, "\n";

				print OWRITER2 "$currentSupport\n";
			}
		}

		print OWRITER "================================================\n";
		print OWRITER2 "================================================\n";

		#generating distinct elements for each iteration

		@distinctelements = keys %newcounts;

		print "Number of Distinct Elements : ",
		  scalar @distinctelements,
		  "\n", "Distinct Elements :   @distinctelements \n";

		foreach (@distinctelements) {
			$_ .= "A";
		}

		$distinctelementstring = [@distinctelements];

		#Storing Hash Value table for the current level
		$hashfilename = 'hashlevel' . $i;
		store \%counts, $hashfilename;

		# element phase complete
		%newcounts  = ();
		@apriorirow = ();
	}    # for of Levels end

	close OWRITER;
}    #sub apriori ends here
####################################################################

####################################################################
#sub formatHash starts here
sub formatHash {

	$hashfilename = 'hashtable';
	if ( -e $hashfilename ) {

		#Information from current Apriori
		%hashtable = %{ retrieve($hashfilename) };
	}

	$hashfilename = 'reversehashtable';

	#Information from current Apriori
	%reversehashtable = %{ retrieve($hashfilename) };

	$hashfilename = 'hashlevel1';
	%counts       = %{ retrieve($hashfilename) };

	foreach ( keys %counts ) {
		if ( scalar @{ $counts{$_} } <= 0 ) {

			$deletetemp = $reversehashtable{$_};
			delete $hashtable{$deletetemp};
			delete $reversehashtable{$_};
			delete $counts{$_};
		}
	}

	#Storing Straight Hash Value table for the current level
	$hashfilename = 'hashtable';
	store \%hashtable, $hashfilename;

	#Storing Reverse Hash Value table for the current level
	$hashfilename = 'reversehashtable';
	store \%reversehashtable, $hashfilename;

}    #sub formatHash ends here
####################################################################

####################################################################
# Program calls here
sub main {
	my $start = time;
	my $dif   = 0;

	parseLog( $_[0] );    #sub for fetching data from the log
	$dif = -( $start - time );
	print "Parse Log ended at : $dif seconds", "\n";

	mergeSort( \@resultarray, \@auxref, 0, $n - 1 )
	  ;                   #sub for sorting data on the basis of IP address
	$dif = -( $start - time );
	print "Merge Sort ended at : $dif seconds", "\n";

	createSession();      #sub for creating url dataset
	$dif = -( $start - time );
	print "Create Session ended at : $dif seconds", "\n";

	printToFile();        #sub for printing the sessions
	$dif = -( $start - time );
	print "Print to file ended at : $dif seconds", "\n";

	createList();   #sub for creating sessions based on IP address and Timestamp
	$dif = -( $start - time );
	print "Create List ended at : $dif seconds", "\n";

	formatLevels( $_[1] )
	  ;             #sub for removing out of window elements from level tables
	$dif = -( $start - time );
	print "Format Levels ended at : $dif seconds", "\n";

	apriori( $_[2], $_[3] );    #sub for running apriori on the list
	print "Number of lines processed is $n \n";

	$dif = -( $start - time );
	print "Apriori ended at : $dif seconds", "\n";
	formatHash();    #sub for removing zeroes elements from hash tables
	$dif = -( $start - time );
	print "Format Data ended at : $dif seconds", "\n";
	$dif = -( $start - time );
	print "Iteration ended at : $dif seconds \n";
}    #sub main ends here
####################################################################

main( $ARGV[0], $ARGV[1], $ARGV[2], $ARGV[3] );

