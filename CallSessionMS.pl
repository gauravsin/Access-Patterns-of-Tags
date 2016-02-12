use strict;
use warnings;
my @filenames = ();

#delete old information
system("perl RemoveOld.pl");

@filenames =
  qw (E:\\College\\Projects\\ZLearnPerl\\Small\\log00 E:\\College\\Projects\\ZLearnPerl\\Small\\log01 E:\\College\\Projects\\ZLearnPerl\\Small\\log02 E:\\College\\Projects\\ZLearnPerl\\Small\\log03 E:\\College\\Projects\\ZLearnPerl\\Small\\log04);

foreach (@filenames) {
	print "New file : $_ \n";
	system("perl SessionMS.pl $_");
	print " \n\n\n\n";
}

