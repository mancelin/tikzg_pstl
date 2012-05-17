#!/usr/bin/perl -w

use warnings;
use strict;
use Image::Magick;

my ($filename) = @ARGV;

my $im = Image::Magick->new();
my $rc = $im->Read($filename);
die $rc if $rc;
my ($w, $h) = $im->Get('width', 'height');
printf "width : %d, height : %d\n", $w, $h;

for(my $y=0;$y<$h;$y++){
	for(my $x=0;$x<$w;$x++){
		my ($r,$g,$b,$alpha) = split /,/,$im->Get("pixel[$x,$y]");
		print "[$x,$y] => r : $r, g : $g, b : $b\n";
	}
}
=r
$im->Set('pixel[0,0]'=>"0,0,0,0");
$im->Set('pixel[1,1]'=>"0,0,0,0");
$im->Set('pixel[2,2]'=>"0,0,0,0");
$im->Write(filename=>'i3.png');
=cut
=r
next if $clr eq "0,0,0,0";
my $blue = (split /,/, $clr)[2];
$blues{$blue}++;
}
}
my $max = 0;
$_ > $max and $max = $_ for values %blues;
for my $val (sort {$a <=> $b} keys %blues)
{
printf "%3d %s\n", $val, '#' x (72 * $blues{$val}/$max);
}
=cut
