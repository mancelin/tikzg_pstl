#!/usr/bin/perl -w

for (my $i=0;$i<200;$i=$i+25){
 print "convert -density $i tmp_tikz_tmp.pdf tmp_tikz_tmp_d$i.png\n";
 system("convert -density $i tmp_tikz_tmp.pdf tmp_tikz_tmp_d$i.png");
}
