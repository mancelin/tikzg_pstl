package TikzParser;

use Exporter;
@EXPORT = qw(decoupe_lignes parse_liste_instructions listhash_of_params lists_kv_of_params);
@ISA = ('Exporter');
use Tie::IxHash; #
use TikzObjects;
use Data::Dumper; #
use ListDumper; #

sub decoupe_lignes {	# une ligne commence par \ et finit par ;
	local $_ = $_[0];
#	print "+"x80;
#	print $_,"\n";
#	print "+"x80;
	my @tab_lignes = split /;/, $_;
	foreach $elem (@tab_lignes){ # rajout d' un ";" a la fin de chaque instructuion
		$elem=$elem.";";
	}
	#&listdump(@tab_lignes);
	#print "-"x80, "\n";	
	
	# ok jusqu ici
	my @list_TikzObjs;
	my $is_instr_multiligne = 0;	
	my $i_objTikz=0;
	my $i_ligne=1;
	foreach $instruction (@tab_lignes){
		my @lignes = split /\n/, $instruction;
		shift @lignes;
#		print "["."="x79, "\n";
#		&listdump(@lignes);
#		print "="x79, "]\n";
		foreach $line (@lignes){
			if ($is_instr_multiligne == 0 && $line =~ /(^\s*\\.*;)/){  # instruction tikz sur une ligne
				$list_TikzObjs[$i_objTikz] = new TikzObjects(ligne => $i_ligne);
				$list_TikzObjs[$i_objTikz]->{code} = $line;
				$i_objTikz++;
				$i_ligne++;
#				print ">> une ligne : [$line]\n";
			} else {
				if ($is_instr_multiligne == 0 && $line =~ /(^\s*\\.*)/){  # debut instruction tikz multiligne
					$is_instr_multiligne = 1;
					$list_TikzObjs[$i_objTikz] = new TikzObjects(ligne => $i_ligne);
					$list_TikzObjs[$i_objTikz]->{code} = $line;
					$i_ligne++;
#					print ">> debut multiligne\n";
				} else { # suite instruction tikz multiligne, ligne vide ou commentaire
					if ($is_instr_multiligne == 1) {
						if ($line =~ /;/){ # fin instruction multiligne
							$list_TikzObjs[$i_objTikz]->{code} = "$list_TikzObjs[$i_objTikz]->{code}\n".$line."\n";
							$i_objTikz++;
							$i_ligne++;
							$is_instr_multiligne = 0;
# 							print ">> fin multiligne\n";
						} else { # suite instruction multiligne
							$list_TikzObjs[$i_objTikz]->{code} = "$list_TikzObjs[$i_objTikz]->{code}\n".$line;
							$i_ligne++;
#							print ">> suite multiligne\n";
						}
					} else { # ligne vide ou commentaire
						$list_TikzObjs[$i_objTikz] = new TikzObjects(ligne => $i_ligne);
						$list_TikzObjs[$i_objTikz]->{code} = $line;
						$list_TikzObjs[$i_objTikz]->{type} = "NoCode";
						$i_objTikz++;
						$i_ligne++;
#						print ">> ligne vide ou comment\n";
					}
				}
			}
		}
	}
	return @list_TikzObjs;
}


sub parse_liste_instructions{
	foreach $elem (@_){
	#	print "elem : ", Dumper($elem),"\n";
		$elem->parse_ligne_instruction();
	}
}

sub listhash_of_params{
	#print $_[0],"\n";
	local @list_of_params=split /,/,$_[0];
	local @listhash;
	#tie %res, "Tie::IxHash"; # pour ordonner les élément du hachage selon l' ordre d' insertion
	foreach $elem(@list_of_params){
		local @param_value=split /=/,$elem;
		if(scalar(@param_value)==2){
			push @listhash,($param_value[0],$param_value[1]);
		} else {
			push @listhash,($param_value[0],undef);
		}
		#print ">>>>>",	scalar(@param_value),"\n";
	}
	print ">>> listhash_of_params >>\n";
	&listdump(@listhash);
	print ">> listhash_of_params >>>\n";
	return @listhash;
}

sub lists_kv_of_params{ # rend couple liste clées, liste valeurs correspondant aux paramétres
	#print $_[0],"\n";
	local @list_of_params=split /,/,$_[0];
	local @list_keys;
	local @list_val;
	#tie %res, "Tie::IxHash"; # pour ordonner les élément du hachage selon l' ordre d' insertion
	foreach $elem(@list_of_params){
		local @param_value=split /=/,$elem;
		if(scalar(@param_value)==2){
			push @list_keys ,($param_value[0]);
			push @list_val ,($param_value[1]);
		} else {
			push @list_keys ,($param_value[0]);
			push @list_val ,(undef);
		}
		#print ">>>>>",	scalar(@param_value),"\n";
	}
	return ([[@list_keys], [@list_val]]);
}

# sert surement a rien
sub hash_of_instruction{
	my $i=1;
	my @list_of_hash;
	foreach(@_){
		local $ligne = $_;
		tie %hash_line, "Tie::IxHash";
		$hash_ligne{ligne} = $i;
		$hash_ligne{code} = $ligne;
		push @list_of_hash, { %hash_ligne}; # ref a un hash
		$i++;
	}
	return @list_of_hash;
}

1;
