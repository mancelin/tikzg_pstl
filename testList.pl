#!/usr/bin/perl -w

#use strict;
use Carp;
use ListDumper;
use Tie::IxHash; # pour afficher les hash dasn l' ordre d' insertion
my @list = qw(vre fh fjezh);
print $list[-1],"\n";
print scalar(@list),"\n------\n";
my @array = (1..13);
my ($a, $b, $c) = @array;
print $a,"\n";
print $b,"\n";
print $c,"\n";

my @reste = splice ( @array, 4,13-4);
print scalar(@reste),"\n";
my $i=0;
foreach(@reste){
	print " "x$i ,"$i : $_\n";
	$i++;
}

sub print_hash{
	local %hash = @_;
	foreach $k (keys %hash) {
		if(defined $hash{$k}){
			print "$k => $hash{$k}\n";
		} else {
			print "$k\n";
		}
	}
}

my %aHash=(
	circle => undef,
	double => undef,
	draw => undef,
	"->" => undef,
	"rigth of" => "n1");
	
&print_hash(%aHash);

print "------------\n";
tie %h, "Tie::IxHash"; 
$h{z}="v,ri";
$h{er}="gvrf";
$h{vgr}="kjv";
$h{a}="first?";
$h{vf}="vufrh";
$h{a}="last? nope, third !";
&print_hash(%h);

print "------------\n";


my $string_params="circle,double,draw,right of=n1";

sub hash_of_params{
	print $_[0],"\n";
	local @list_of_params=split /,/,$_[0];
	&listdump(@list_of_params);
	print "------------\n";
	local %res;
	tie %res, "Tie::IxHash"; # pour ordonner les élément du hachage selon l' ordre d' insertion
	foreach $elem(@list_of_params){
		local @param_value=split /=/,$elem;
		if(scalar(@param_value)==2){
			$res{$param_value[0]}=$param_value[1];
		} else {
			$res{$param_value[0]}=undef;
		}
		#print ">>>>>",	scalar(@param_value),"\n";
	}
	return %res;

}

my %hash_res = &hash_of_params($string_params);
&print_hash(%hash_res);
