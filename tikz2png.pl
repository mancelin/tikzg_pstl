#!/usr/bin/perl

use ColorId;

my ($filename,$density) = @ARGV;

my $entete_tikz= 
q (\documentclass{article}
\usepackage[graphics,tightpage,active]{preview}
\usepackage[utf8]{inputenc}  
\usepackage{xcolor}
\usepackage{tikz}
\PreviewEnvironment{tikzpicture}
\begin{document}
\begin{tikzpicture});
#my $distance_node=50;
#my $entete =$entete_tikz."[node distance=".$distance_node."pt]\n";

my $fin=
q(\end{tikzpicture}
\end{document}
);

unless (open FICTIKZ, "<tmp/$filename"){
	die "Impossible d'ouvrir '$filename' : $!";
}

=dans ColorId.pm
# pour generer l' image "ColorId" correspondate
my $rv=30; # red value
my $gv=30; # green value
my $bv=30; # blue value

sub gen_next_ColorId{
	if($rv==100 && $gv==100 && $bv==100){
		die "Trop d' éléments"; # S' il y a plus de 343000 éléments ...
	} else {
		if ($gv==100 && $bv==100){
			$rv++;
			$gv=30;
			$bv=30;
		} else {
			if ($bv==100){
				$gv++;
				$bv=30;
			} else {
				$bv++;
			}
		}
	}
	my $new_color="red!$rv!green!$gv!blue!$bv";
	return "$new_color,fill=$new_color";
}
=cut

my $tikz_code="";
my $tikz_code_colorID="";

while (my $ligne_colorID=<FICTIKZ>) {
	
	# recuperation du code tikz
	$tikz_code.=$ligne_colorID; 
	
	# creation d' un code tikz pour allouer une couleur differente a chaque objet
	$ligne_colorID=~ m{\A
						((\\)(node|draw|\S+))
						\[([^\]]*)\]
						(.*;\n)
					}x;
	my ($obj_tikz, $prop, $reste_ligne) = ($1,$4,$5);
	#printf "1 : %s, 4 : %s, 5 : %s\n", $1, $4, $5;
	if( $obj_tikz eq ""){
		$tikz_code_colorID.=$ligne_colorID;
		
	} else {
		if( $obj_tikz eq '\draw'){
			$tikz_code_colorID.=$obj_tikz."[line width=5pt,".&gen_next_ColorId()."]".$reste_ligne;
		} else {
			$tikz_code_colorID.=$obj_tikz."[".$prop.",".&gen_next_ColorId()."]".$reste_ligne;
		}
	}
}
close FICTIKZ;

my $contenu_fic_tex = $entete_tikz.$tikz_code.$fin;

my $nom_fic_tex = "tmp/".$filename.".tex";
unless(open FICTEXTMP, ">$nom_fic_tex"){
	die "Impossible d'ecrire sur  '$nom_fic_tex' : $!";
}

print FICTEXTMP $contenu_fic_tex;
close FICTEXTMP;

### detruit anciéne fenétre eog
system("pkill eog");

# generation pdf a partir de fichier tex
#system("pdflatex $nom_fic_tex");
system("pdflatex -halt-on-error $nom_fic_tex > /dev/null");

my $pdf_tmp=$filename.".pdf";

# pdfcrop sur pdf obtenu ( pour redimensionner pdf en fonction image)
#system("pdfcrop --hires  $pdf_tmp $pdf_tmp");


# transformation du pdf en png
$img=$filename.".png";
system("convert -density $density $pdf_tmp $img");

system("mv $pdf_tmp tmp/$pdf_tmp");
system("rm *.log *.aux");
system("mv $img tmp");



# generation tex,pdf, png pour l' image avec les colors ID
my $contenu_fic_tex_IDC = $entete_tikz.$tikz_code_colorID.$fin;
my $nom_fic_tex_IDC = "tmp/".$filename."_IDC.tex";
unless(open FICTEXTMP_IDC, ">$nom_fic_tex_IDC"){
	die "Impossible d'ecrire sur  '$nom_fic_tex_IDC' : $!";
}

print FICTEXTMP_IDC $contenu_fic_tex_IDC;
close FICTEXTMP_IDC;

# generation pdf a partir de fichier tex


#system("echo -------- $nom_fic_tex_IDC"); #
#sleep 2;
#system("pdflatex $nom_fic_tex_IDC"); 
system("pdflatex -halt-on-error $nom_fic_tex_IDC > /dev/null"); 


my $pdf_tmp_IDC=$filename."_IDC.pdf";
$img_IDC=$filename."_IDC.png";
system("convert -density $density $pdf_tmp_IDC $img_IDC");

# deplacement du pdf généré dans tmp
system("mv $pdf_tmp_IDC tmp/$pdf_tmp_IDC");
system("rm *.log *.aux");
system("mv $img_IDC tmp");

# nettoyage
#system("rm *tmp*");

#affichage IDC
#system("eog tmp/$img_IDC &");


=afficher_vars
print 	"filename : $filename\n",
		"nom_fic_tex : $nom_fic_tex\n",
		"pdf_tmp : $pdf_tmp\n",
		"img : $img\n";
=cut
