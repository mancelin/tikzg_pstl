package TikzParser;

use Exporter;
@ISA = ('Exporter');

sub decoupe_lignes {	# une ligne commence par \ et finit par ;
	#my $code_tikz_restant = $_[0];
	my $_ = $_[0];
	my @tab_lignes;
	while(m{(\\.*;)}g){
		push(@tab_lignes, $1);
	}
	return @tab_lignes;
}

sub hash_of_instruction{
	my $i=1;
	my @list_of_hash;
	foreach(@_){
		push @list_of_hash, { ligne => $i, code => $_}; # ref a un hash
		$i++;
	}
	return @list_of_hash;
}
=cut	
	print "vujfh\n";
}


=fre
	my $i=1;
	foreach(@_){
		print $i," ",$_,"\n";
		$i++;
	}
=cut

1;
