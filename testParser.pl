#!/usr/bin/perl -w
use TikzParser;
use ListDumper;
#use Data::Dumper;

my $un_code_tikz= 
q (	
\node[circle,double,draw,right of=n1] (n2) {$\frac{\sqrt{x}}{x^y}$};
\draw[->] (n1) -- (n2);
\node[below of=n1,node distance=30pt] (n3) {below};
\draw[dashed] (n2) -- (n3);
\node[circle,draw,below right of=n2] (n4) {below right};
\draw[thin,dashed] (n3) -- (n4););

=test_ok
	print "-"x80,"\n";
	print $un_code_tikz, "\n";
	print "-"x80,"\n";
=cut

my @list_instructions = &TikzParser::decoupe_lignes($un_code_tikz);

&listdump(@list_instructions);

print "="x80,"\n";

my @list_instructions_of_hash = &TikzParser::hash_of_instruction(@list_instructions);
#print Dumper(@list_instructions_of_hash);
my $ref_un_hash=@list_instructions_of_hash[1];
my %un_hash=%$ref_un_hash;
&print_Hash(%un_hash);
print "+"x80,"\n";
&print_list_of_hashes(@list_instructions_of_hash);
print "o"x80,"\n";
tie %tmp_hash, "Tie::IxHash";
%tmp_hash = {$list_instructions_of_hash[3]};
$tmp_hash{hvurh}="gargl garhlll";
$list_instructions_of_hash[3]=\%tmp_hash;
&print_list_of_hashes(@list_instructions_of_hash);


