#!/usr/bin/perl
#$d="source";
#opendir(D, "$d") || die "Can't open directory $d: $!\n";
#@list = grep !/^\.\.?$/, readdir(D);
#print @list;

use 5.010;
use strict;
use warnings;

use File::Basename;

my @exts = qw(.NGN);

while (my $file = <DATA>) {
  chomp $file;
  my ($dir, $name, $ext) = fileparse($file, @exts);

  given ($ext) {
    when ('.NGN') {
      say "$file is a NGN file";
    }
     default {
      say "$file is an unknown file type";
    }
  }
}
