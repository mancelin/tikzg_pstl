#!/usr/bin/perl -w
use TikzParser;
use ListDumper;
use TikzObjects;
use Data::Dumper;

my $un_code_tikz= 
q (	
\node[circle,double,draw,right of=n1] (n2) {$\frac{\sqrt{x}}{x^y}$};
\draw[->] (n1) -- (n2);
\node[below of=n1,node distance=30pt] (n3) {below};
\draw[dashed] (n2) -- (n3);
\node[circle,draw,below right of=n2] (n4) {below right};

\draw[thin,dashed] (n3) -- (n4););


my $un_code_tikz2= 
q (


);

my $un_code_tikz_compli= 
q(
\node (tree) {\begin{tabular}{c}
				tree \\ $n$
             \end{tabular}};
\node[above of=tree,node distance=30pt] (tree_a) {};
\nod[below of=tree,node distance=20pt] (tree_b) {};
\node[left of=tree_b,node distance=30pt] (tree_l) {};
\node[right of=tree_b,node distance=30pt] (tree_r) {};
\draw (tree_a.center) -- (tree_r.center);

\draw (tree_r.center) -- (tree_l.center);
\draw  (tree_l.center) -- (tree_a.center););


my @list_instructions = &TikzParser::decoupe_lignes($un_code_tikz);

#&listdump(@list_instructions);
=old
print Dumper(@list_instructions);
print "List length : ".scalar(@list_instructions)."\n";
print "="x80,"\n";
#print Dumper(@list_instructions);
#print "List length : ".scalar(@list_instructions)."\n";
$list_instructions[6]->printChamp("ligne");
$list_instructions[6]->printChamp("lreg");
$list_instructions[6]->printChamp("type");
=cut

sub list_of_nodes{
	my @liste_obj_tikz = @_;
	my @listenoeuds;
	foreach $elem (@liste_obj_tikz){
		if($elem->{type} eq "node") {
			print $elem->{type}, "\n";
			push (@listenoeuds, $elem->{nom});
		}
	}
	return @listenoeuds;
}

=gtlrik
sub list_of_draw{
	my @liste_obj_tikz = @_;
	my @listearretes;
	foreach $elem (@liste_obj_tikz){
		if($elem->{type} eq "draw") {
			print $elem->{type}, "\n";
			push (@listenoeuds, $elem->{nom});
		}
	}
	return @listenoeuds;
}
=cut

parse_liste_instructions(@list_instructions);
#print "_"x80,"\n";
#print Dumper($list_instructions[0]);
print Dumper(@list_instructions);

print "_"x80;
my @listnodes = &list_of_nodes(@list_instructions);
print Dumper(@listnodes);
