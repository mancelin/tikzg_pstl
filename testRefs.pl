#!/usr/bin/perl -w

use ListDumper;

my @l;
my $reflist = \@l;
listdump @l;
print "-"x80;
push @l, "er";
listdump @l;
print "="x80;
listdump @{$reflist};
#push ${$reflist}, " 
print "_"x80;
@l=();
listdump @l;

