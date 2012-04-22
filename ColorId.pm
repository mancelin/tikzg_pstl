package ColorId;

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(gen_next_ColorId);

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

1;
