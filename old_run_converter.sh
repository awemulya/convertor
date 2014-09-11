#/usr/bin/perl -w;
@files = <*NGN>; # read all files with extension .NGN within this current directory;
print "\n Enter Output Path \n ";
$out_path = <STDIN>;
foreach $file (@files) {
	($filename_without_extension = $file) =~ s/\.[^.]+$//; # removed file extension .NGN from file name
	$filename = $filename_without_extension.'.csv';
	$cmd = "cat $file | ./cdr2text_v2.pl >> "."con1"."/".$filename ;
	system($cmd);

} 
