my $rv=30; # red value
my $gv=29; # green value

# color id sur 2 couleurs : red , green
sub gen_next_ColorId{	
  if($rv>=100 && $gv==100){
    die "Trop d'éléments"; # S' il y a plus de 5041 éléments
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
