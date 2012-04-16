#!/usr/bin/perl

use Tie::IxHash; 
use ListDumper;

sub print_hash{
	local %hash = @_;
	#tie %hash, "Tie::IxHash"; 
	foreach $k (keys %hash) {
		if(defined $hash{$k}){
			print "$k => $hash{$k}\n";
		} else {
			print "$k\n";
		}
	}
}

=now in ListDumper.pm
sub print_IxHash{
	tie(%hash, Tie::IxHash, @_);
	#local %hash = @_;
	while (( $key, $val) = each %hash) {
		if(defined $val){
			print "$key => $val\n";
		} else {
			print "$key\n";
		}
	}
}

=cut


print "------------\n";
tie %ham, "Tie::IxHash"; 
$ham{e}="frgrt";
$ham{er}="gvrf";
$ham{v}="kv";
$ham{vhfu}=undef;
$ham{e}="first ?";
$ham{vf}="ufrh";
$ham{der}="_bjtr_";
$ham{1}=undef;

#print "@{[ %ham ]}\n";
#$h{a}="last? nope, third !";
&ListDumper::print_IxHash(%ham);
