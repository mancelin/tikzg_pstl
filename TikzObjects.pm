package TikzObjects;


sub new{
	my $classe= shift;
	my $self = { @_ };
	return bless($self, $classe);		  #lie la référence à la classe
}

# get/set sur ligne
# !!! pas besoin en fait !!!
sub ligne {	
	my $self = shift;
	return @_ ? ($self->{ligne} = shift) : $self->{ligne};
}




1;
