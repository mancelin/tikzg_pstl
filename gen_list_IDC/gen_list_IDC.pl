#!/usr/bin/perl

use ColorId;
use Image::Magick;

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
my $entete =$entete_tikz;#."[node distance=".$distance_node."pt]\n";

my $fin=
q(\end{tikzpicture}
\end{document}
);

my $tikz_code_colorID="";


unless(open LIST_IDC, ">list_IDC"){
	die "Impossible d'ecrire sur  'list_IDC' : $!";
}

my ($r,$g,$b,$alpha,$rgba);
for(my $y=30;$y<=100;$y++){
	for($x=30;$x<=100;$x++){
		$tikz_code_colorID="\\node[rectangle,draw,".&gen_next_ColorId()."]"."(n1) {u};\n";
		print $tikz_code_colorID;
		my $contenu_fic_tex = $entete.$tikz_code_colorID.$fin;
		unless(open FICTEXTMP, ">tmp_node.tex"){
			die "Impossible d'ecrire sur  'tmp_node.tex' : $!";
		}

		print FICTEXTMP $contenu_fic_tex;
		close FICTEXTMP;
		
		# génération pdf a partir de fichier tex
		system("pdflatex tmp_node.tex> /dev/null"); # redirection vers /dev/null pour accelerer la génération du pdf
		system("convert -density 72 tmp_node.pdf tmp_node.png");
		
		my $im = Image::Magick->new();
		my $rc = $im->Read("tmp_node.png");
		die $rc if $rc;
		
		# récupération de la couleur du pixel en (2,2) pour éviter les couleurs légérement modifiés sur les bord de l' image
		($r,$g,$b,$alpha) = split /,/,$im->Get("pixel[5,5]");
	#	$rgba = $im->Get("pixel[5,5]");
		
		# netoyage
	#	system("rm tmp_node.*");
	
	#	print LIST_IDC "red!$y,green!$x => $r $g $b $rgba\n";
		print LIST_IDC "red!$y,green!$x => $r $g $b\n";
	}
} 
close LIST_IDC;


