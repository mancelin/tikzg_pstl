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
	
}

1;
