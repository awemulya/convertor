#!/usr/bin/perl
#converts .NGN files from source directory to .csv in destination directory
    use strict;
    use warnings;
    use diagnostics;
#    print "Enter Source Directory Name \n";
 #   my $dir = <STDIN>;
     my $dir = 'source';
 #   print "Enter Destination / Output Directory \n";
  #  my $destination = <STDIN>;
    my $destination = 'destination';
#    print $dir." => ".$destination ."\n" ;
    opendir(DIR, $dir) or die $!;

    while (my $file = readdir(DIR)) {

        # We only want files
        next unless (-f "$dir/$file");

        # Use a regular expression to find files ending in .NGN
        next unless ($file =~ m/\.NGN$/);

        print "$file\n";
	(my $filename_without_extension = $file) =~ s/\.[^.]+$//; # removed file extension .NGN from file name
	my $filename = $filename_without_extension.'.csv';
	
	if (-e "$destination/$filename") {
	 	print "File $destination/$filename already exists.\n";
	}else{
		my $cmd = "cat $dir/$file | ./cdr2text_v2.pl >> $destination/$filename" ;
		system($cmd);
	}#end of else
    }# end of while

    closedir(DIR);
    exit 0;
