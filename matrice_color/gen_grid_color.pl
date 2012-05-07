#!/usr/bin/perl

use ColorId;

#my ($filename,$distance_node,$density) = @ARGV;

my $entete_tikz= 
q (\documentclass{article}
\usepackage[graphics,tightpage,active]{preview}
\usepackage[utf8]{inputenc}  
\usepackage{xcolor}
\usepackage{tikz}
\PreviewEnvironment{tikzpicture}
\begin{document}
\begin{tikzpicture});
my $distance_node=1;
my $entete =$entete_tikz."[node distance=".$distance_node."pt]\n";

my $fin=
q(\end{tikzpicture}
\end{document}
);

my $tikz_code_colorID="";

my $below_node="";
for(my $y=30;$y<100;$y++){
	my $x=30;
	$tikz_code_colorID.="\\node[rectangle,draw,".&gen_next_ColorId().$below_node."]"."(n".$x."_".$y.") {u};\n";
	for($x=31;$x<=100;$x++){
		$tikz_code_colorID.="\\node[rectangle,draw,".&gen_next_ColorId().",right of=n".($x-1)."_".$y."]"."(n".$x."_".$y.") {u};\n";
		print "x : $x , y : $y\n";
	}
	$below_node=",below of=n30_".$y;
}

my $contenu_fic_tex = $entete.$tikz_code_colorID.$fin;

unless(open FICTEXTMP, ">generated_grid.tex"){
	die "Impossible d'ecrire sur  'generated_grid.tex' : $!";
}

print FICTEXTMP $contenu_fic_tex;
close FICTEXTMP;

# generation pdf a partir de fichier tex
system("pdflatex generated_grid.tex");

system("convert generated_grid.pdf generated_grid.png");
