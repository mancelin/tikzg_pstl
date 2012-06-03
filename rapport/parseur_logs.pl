sub parse_log {
  my $fichier = "tmp_tikz.log";
  my $line_number_error;
  my $log_error="";
  my $print_next_line = 0;
  open(LOG, $fichier) 
    || die "Impossible de lire le fichier %s:\n%s", $fichier, $!;
 
  while(<LOG>){
    if($print_next_line){
      $print_next_line=0;
      $log_error.=$_;
      next;
    }
    if($_ =~ /\QRunaway argument?\E/) {
      $print_next_line=1;
      $log_error.=$_;
    }
    if($_ =~ /\Q! Package pgfkeys Error\E/){
      $print_next_line=1;
      $log_error.=$_;
    } elsif($_ =~ /! Package.*Error:/){
      $log_error.=$_;
    }
    if($_ =~ /! Undefined control sequence./){
      $log_error.=$_;
    }
    if($_ =~ /^(l\.)(\d+)(.*)/){
      $print_next_line=1;
      $line_number_error = $2-7;   # l' entête fait 7 lignes;
      $log_error.=$1.$line_number_error.$3;
    }
    if($_ =~ /\Q!  ==> Fatal error occurred, no output PDF file produced!\E/){
      print $_;
    }
  }
  system("rm *.log"); # suppresion des fichiers log
  utf8::decode($log_error); 
  $mainWindow->{labelError}->setText($log_error); # affichage du log dans IHM 
}
