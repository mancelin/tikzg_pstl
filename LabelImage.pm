package LabelImage;

use strict;
use warnings;
use QtCore4;
use QtGui4;
#use QtCore4::isa qw( Qt::GraphicsItem );
use QtCore4::isa qw( Qt::Label );
use Data::Dumper; #
use MainWindow;
use Image::Magick;

#my $fic="tmp/tmp_tikz_IDC.png";

#my $zoomFactorImg;

sub NEW {
    my ($class,$dock,$ref_density,$ref_zoom_factor_image) = @_;
    $class->SUPER::NEW($dock);
    this->setMouseTracking(1);
=old    
    this->{zoomFactorImg}=int((${$ref_density} / 18) *25); # ?  
    this->{zoomFactorImg}= \$zoomFactorImg;
=cut
	this->{zoomFactorImg}=${$ref_zoom_factor_image};
    this->{density}= ${$ref_density};
    #this->setToolTip(sprintf "Qt::Color(%d, %d, %d)\n%s",
     #         this->{color}->red(), this->{color}->green(), this->{color}->blue(),
      #        'Click and drag this color onto the robot!');
 #   this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
}

=ij
sub setZoomFactorImg {
	my ($new_zoom) = @_;
	printf "new zoom : %d \n", $new_zoom;
	$zoomFactorImg = $new_zoom;
	this->{density} = int(($zoomFactorImg/25) * 18);
}
=cut	


sub getPixelColorAt {
	my ($x, $y) = @_;

=over	
	# tmp, to test
	my ($x, $y,$file) = @_;

	print $_[1];
	my $x = $_[0];
	my $y = $_[1];
	printf "  x : %d, y : %d\n", $x, $y;
=cut
	my $im = Image::Magick->new();
	my $rc = $im->Read("./tmp/tmp_tikz_IDC.png");
	#my $rc = $im->Read($file); # tmp test
	
	die $rc if $rc;
	my ($r,$g,$b,$alpha) = split /,/,$im->Get("pixel[$x,$y]");
	print " [$x,$y] => r : $r, g : $g, b : $b\n";
	printf "IDC : %s\n", &IDC_of_RGB($r,$g,$b);
	return &IDC_of_RGB($r,$g,$b);
}
	
sub IDC_of_RGB {
	my ($red, $green, $blue) = @_;
	print "RGB : $red $green $blue\n";
	my $nb_IDC = MainWindow::nb_IDC();
	print "   nb_IDC : $nb_IDC\n";
	
	unless(open LIST_IDC, "list_IDC"){
		die "Impossible d'ouvrir 'list_IDC' : $!";
	}
	
	LECT_FIC:
	while(<LIST_IDC>){ # && ($nb_IDC > 0)){
		my $line = $_;
		chomp $line;
		#print $line; #dbg
		$nb_IDC--;
		last LECT_FIC if ($nb_IDC < 0);
		my ($idc, $sep, $r, $g, $b) = split / /,$line;
		if (($r == $red) && ($g == $green) && ($b == $blue)){
			close LIST_IDC;
			return $idc;
		}
	}
	close LIST_IDC;
	return "none";
}

sub mouseMoveEvent {
    my ($event) = @_;
   # printf "heiht : %d, width : %d\n", this->size()->height(), this->size()->width();
   # print " x : ",$event->x," , y : ",$event->y,"\n";
=depla
    my $hauteur_label = this->size()->height();
    my $hauteur_image = this->pixmap()->height();
    my $largeur_image = this->pixmap()->width();
   # print " hauteur image : ",$hauteur_image," largeur image : ",$largeur_image,"\n";
    my $x = $event->x;
	my $y = int($event->y - ($hauteur_label/2 - $hauteur_image/2));
	if(($x <= $largeur_image) && ($y >= 0) && ($y < $hauteur_image)) {
#		print "\n{Image} => x : ",$x," , y : ",$y,"\n";
#		print "nb_IDC : ", MainWindow::nb_IDC();
         getPixelColorAt($x,$y);
        # getPixelColorAt($x,$y,$fic);# tmp test
    }
=cut    
   # this->setCursor(Qt::Cursor(Qt::WaitCursor()));
 #	system("echo Mouse move event - `date +%H:%M:%S::%N`");


	
#	print "density : ", this->{density}, "\n";	
#	print "zoom factor => ", this->{zoomFactorImg}, "\n";

}

sub mousePressEvent
{
    my ($event) = @_;
    if ($event->button() == Qt::LeftButton()) {
		print "mousePressEvent : leftButton\n";
		
		my $hauteur_label = this->size()->height();
		my $hauteur_image = this->pixmap()->height();
		my $largeur_image = this->pixmap()->width();
	   # print " hauteur image : ",$hauteur_image," largeur image : ",$largeur_image,"\n";
		my $x = $event->x;
		my $y = int($event->y - ($hauteur_label/2 - $hauteur_image/2));
			if(($x <= $largeur_image) && ($y >= 0) && ($y < $hauteur_image)) {
	#		print "\n{Image} => x : ",$x," , y : ",$y,"\n";
	#		print "nb_IDC : ", MainWindow::nb_IDC();
			my $idcClicked = getPixelColorAt($x,$y);
			my $objTikz = MainWindow::object_ofIDC($idcClicked);
			print Dumper($objTikz);
		}	
	#	$fic= "tmp/tmp_tikz_IDC.png";
	#	this->setPixmap(Qt::Pixmap("tmp/tmp_tikz"));	
    }
    
    if ($event->button() == Qt::RightButton()) {
		print "mousePressEvent : RightButton\n";
	#	$fic = "tmp/IDC1.png";
	#	this->setPixmap(Qt::Pixmap("gen_list_IDC/IDC55.png"));
    }
    
    
=old   
   # this->setPixmap(Qt::Pixmap("tmp/tmp_tikz_IDC.png"));
    my $rgb = Qt::Color->fromRgb(Qt::Image::pixel( $event->x, $event->y) );
#		print "RGB : $rgb\n";
	my $r = $rgb->red();
	my $g = $rgb->green();
	my $b = $rgb->blue();
	#this->setPixmap(Qt::Pixmap("tmp/tmp_tikz.bmp"));
	print "color (R,G,B)  : ($r,$g,$b)\n";
		print " x : ",$event->x," , y : ",$event->y,"\n";
	#this->setPixmap(Qt::Pixmap("tmp/tmp_tikz.png"));

  #  this->setCursor(Qt::Cursor(Qt::ClosedHandCursor()));
	print "mousePressEvent\n";
	#print "hasPixmap ? ", this->pixmap(), "\n";
	#print "is Valid ? : " , $rgb->Qt::Color->isValid();

=cut
	
}



sub mouseReleaseEvent
{
 #   this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
	
	
#	
    print "mouseReleaseEvent\n";
}


sub wheelEvent
{
	my ($event) = @_;
	my $delta = $event->delta();
	print "wheelEvent, delta : $delta - ";
	if($delta > 0){
		print "up\n";
		#MainWindow->augmentDensity();
		this->{density}=this->{density}+18;
#		MainWindow::augmentDensity();
#		if($event->keyPressed() ){ #== Qt::ControlModifier
	#	if( Qt::Control.ModifierKeys == Keys.Ctrl ){
	#		print "ctrl pressed\n";
	#	}
	} else {
		print "down\n";
		if( this->{density} > 18 ) {
			this->{density}=this->{density}-18;

		} else {
			print ">> density too small\n";
		}
#		MainWindow::diminueDensity();
	}
	my $density= this->{density};
#	my $density= MainWindow->density;
	system("convert -density $density tmp/tmp_tikz.pdf tmp_tikz.png");
	system("mv tmp_tikz.png tmp");
	system("convert -density $density tmp/tmp_tikz_IDC.pdf tmp_tikz_IDC.png");
	system("mv tmp_tikz_IDC.png tmp");
	#MainWindow->refresh_density();
	this->{zoomFactorImg}=(this->{density} / 18) *25; # ? 
	MainWindow::update_textbox_zoom_image(); 
	this->setPixmap(Qt::Pixmap("tmp/tmp_tikz.png"));
	##system("pkill eog");	##
	#system("eog tmp/tmp_tikz_tmp_IDC.png");	##
}

sub keyPressEvent
{
	my ($event) = @_;
	print "keyPressEvent\n";
}

1;
