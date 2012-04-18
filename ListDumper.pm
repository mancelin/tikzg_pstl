package ListDumper;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(listdump print_IxHash print_Hash print_list_of_hashes);
use Tie::IxHash;

sub listdump {
	my $i=1;
	foreach(@_){
		print $i," ",$_,"\n";
		$i++;
	}
}

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

sub print_Hash{
	local %hash = @_;
	while (( $key, $val) = each %hash) {
		if(defined $val){
			print "$key => $val\n";
		} else {
			print "$key\n";
		}
	}
}

sub print_list_of_hashes {
	local @loh = @_; # list of hash
	local $i=0;
	foreach $ref_hash (@loh){
		print "-- $i\n";
		local %hash=%$ref_hash;
		&print_IxHash(%hash);
		$i++;
	}
}

1;
