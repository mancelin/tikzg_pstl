package TikzObjects;

use Carp;
use Data::Dumper; #
use TikzParser;
#use Tie::IxHash; 
use ListDumper; #
use ColorId;

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

sub code {	
	my $self = shift;
	return @_ ? ($self->{code} = shift) : $self->{code};
}



sub printChamp{
	my ($self, $champ) = @_;
	if ( defined $self->{$champ} ){
		print "$champ : $self->{$champ}", "\n";
	} else {
		carp "$champ : Champ non présent";
	}
}



# met un hash paramétre/valeur dans le champ "params" 
#  et l' ordre des paramétre dans "param_keys"
sub hash_of_params{	
	my ($self) = @_;
	# print $_[1],"\n";
	local @list_of_params=split /,/,$_[1];
	local @params_keys;
	local %res;
	foreach $elem(@list_of_params){
		local @param_value=split /=/,$elem;
		push @params_keys, ($param_value[0]);
		if(scalar(@param_value)==2){
			$self->{params}{"$param_value[0]"}="$param_value[1]";
		} else {
			$self->{params}{"$param_value[0]"}=undef;
		}
	}
	$self->{params_keys}=[@params_keys];
}	
	
sub parse_ligne_instruction{ # une ligne commence par \ et finit par ;
	my ($self) = @_;
	unless (defined $self->{type} && $self->{type} eq "NoCode"){ # si ligne d' instruction
		local $code=$self->{code};
		if( $code =~ /(?:\\)([a-z]*)(.*)/){
			$code=$2;
			if($1 eq "node"){
				$self->{type}=$1;
				#$self->{params}=undef;
				if ( $code =~ m{\[([^\]]*)\](.*)} ){
					
					$self->hash_of_params($1);
					$code=$2;
#					print " 1 : $1 \n 2 : $2 \n";
				}
				if(  $code =~ m{\(([^\)]*)\)(.*)} ){
					$self->{nom}=$1;
					$code=$2;
					#print " 1 : $1 \n 2 : $2 \n";
				}
				if( $code =~ /{(.*)};/){
					$self->{text}=$1;
					#print ">> 1 : $1 \n ";
					$self->{colorId}=&gen_next_ColorId();
				} else {
					$self->{error}="Champ {} manquant a la fin de la ligne";
				}
#				print "node !\n";
			} else {
				if($1 eq "draw"){
					$self->{type}=$1;					
					if ( $code =~ m{\[([^\]]*)\](.*)} ){
						
						$self->hash_of_params($1);
						#$self->color
#						print " 1 : $1 \n 2 : $2 \n";
						$code=$2;
					}
					if(  $code =~ m{\(([^\)]*)\)(.*)\(([^\)]*)\)} ){
					#	print " 1 : $1 \n 2 : $2 \n 3 : $3 \n";
						$self->{origine}=$1;
						$self->{code_segment}=$2;
						$self->{but}=$3;
						if( $self->{code_segment} =~ /--/ ){
							$self->{colorId}=&gen_next_ColorId();
						} else {
							$self->{error}="Ce n'est pas un segment";
						}
					}

#					print "draw !\n";
				} else {
					$self->{type}="unknown";
#					print "unknown !\n";
				}	
			}
		#	print "code restant : $code\n";
			#print " 1 : $1 \n 2 : $2 \n";
		}
		#				\[([^\]]*)\]
		#				(.*;\n)
		#			}x;
	#	print $self->{ligne},"\n";
	}	
}
	
1;
