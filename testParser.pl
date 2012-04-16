#!/usr/bin/perl -w
use TikzParser;

my $un_code_tikz= 
q (\node[rectangle,draw] (n1) {un n{\oe}ud};
\node[circle,double,draw,right of=n1] (n2) {$\frac{\sqrt{x}}{x^y}$};
\draw[->] (n1) -- (n2);
\node[below of=n1,node distance=30pt] (n3) {below};
\draw[dashed] (n2) -- (n3);
\node[circle,draw,below right of=n2] (n4) {below right};
\draw[thin,dashed] (n3) -- (n4););

print "-"x80,"\n";
print $un_code_tikz, "\n";
print "-"x80,"\n";
&TikzParser::decoupe_lignes($un_code_tikz);
