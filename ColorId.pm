package ColorId;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(gen_next_ColorId reset_ColorId);

my $rv=30; # red value
my $gv=29; # green value
#my $bv=30; # blue value

sub gen_next_ColorId{	# color id désormais codé sur 2 couleurs : red , green
	if($rv>=100 && $gv==100){
		die "Trop d' éléments"; # S' il y a plus de 5041 éléments ...
	} else {
		if ($gv==100){
			$rv++;
			$gv=30;
		} else {
			$gv++;
		}
	}
	my $new_color="red!$rv!green!$gv";
	return "$new_color,fill=$new_color";
}

sub reset_ColorId{
	$rv=30; # red value
	$gv=29; # green value
}

1;
