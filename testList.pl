#!/usr/bin/perl -w

#use strict;
use Carp;
use ListDumper;
use Tie::IxHash; # pour afficher les hash dasn l' ordre d' insertion

=tested
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

=cut
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
	
#&print_hash(%aHash);


print "¨"x80;
tie %h, "Tie::IxHash"; 
$h{z}="v,ri";
$h{BGFz}="ri";
$h{er}="gvrf";
$h{vgr}="kjv";
$h{a}="first?";
$h{vf}="vufrh";
$h{a}="last? nope, third !";
&print_hash(%h);
print "¨"x80;
#print "------------\n";


my $string_params="circle,double,draw,right of=n1";

=old
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
=cut

sub listhash_of_params{
	print $_[0],"\n";
	local @list_of_params=split /,/,$_[0];
	&listdump(@list_of_params);
	print "------------\n";
	local @res;
	#tie %res, "Tie::IxHash"; # pour ordonner les élément du hachage selon l' ordre d' insertion
	foreach $elem(@list_of_params){
		local @param_value=split /=/,$elem;
		if(scalar(@param_value)==2){
			push @res,($param_value[0],$param_value[1]);
		} else {
			push @res,($param_value[0],undef);
		}
		#print ">>>>>",	scalar(@param_value),"\n";
	}
	return @res;

}

#my %hash = map { split("=",$_) } split(",",$string_params);



my @hash_res = &listhash_of_params($string_params);
tie(%hash, Tie::IxHash, @hash_res);
&print_IxHash(%hash);
print "="x80;
$hash{"vtr"}="virj";
$hash{"draw"}="true";
#my %hash = map { $_ => 1 } @hash_res;
print_Hash(%hash);
#&print_IxHash(%hash_res);
=vfr
print "x"x80;
tie %hah, "Tie::IxHash";
my %hah = ("circle"=>undef , "double"=>undef,"draw"=>undef,"right of"=>"n1");
&print_IxHash(%hash_res);
=cut
