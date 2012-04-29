package LabelImage;

use strict;
use warnings;
use QtCore4;
use QtGui4;
#use QtCore4::isa qw( Qt::GraphicsItem );
use QtCore4::isa qw( Qt::Label );
use Data::Dumper; #

sub NEW {
    my ($class,$dock) = @_;
    $class->SUPER::NEW($dock);
    this->setMouseTracking(1);
   # this->{color} = Qt::Color( rand(RAND_MAX) % 256, rand(RAND_MAX) % 256, rand(RAND_MAX) % 256 );
    #this->setToolTip(sprintf "Qt::Color(%d, %d, %d)\n%s",
     #         this->{color}->red(), this->{color}->green(), this->{color}->blue(),
      #        'Click and drag this color onto the robot!');
 #   this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
	this->setPixmap(Qt::Pixmap("images/test.png"));
}

=fe
sub boundingRect
{
    return Qt::RectF(-15.5, -15.5, 34, 34);
}

sub paint
{
    my ($painter) = @_;
    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::darkGray()));
    $painter->drawEllipse(-12, -12, 30, 30);
    $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::black())), 1));
    $painter->setBrush(Qt::Brush(this->{color}));
    $painter->drawEllipse(-15, -15, 30, 30);
}
=cut

sub mouseMoveEvent
{
    my ($event) = @_;
  #  this->setCursor(Qt::Cursor(Qt::WaitCursor()));
#	system("echo Mouse move event - `date +%H:%M:%S::%N`");

#	print " x : ",$event->x," , y : ",$event->y,"\n";
=mute	
		my $rgb = Qt::Color->fromRgb(Qt::Image::pixel( $event->x, $event->x ) );
		print "RGB : $rgb\n";
		my $r = $rgb->red();
		my $g = $rgb->green();
		my $b = $rgb->blue();
		print "color (R,G,B)  : ($r,$g,$b)\n";
=cut

=later  ->  meme couleur toujours détexctée
	my $rgb = Qt::Image::pixel( $event->x, $event->y );
	my $r = ($rgb >> 16) & 0xFF;
	my $g = ($rgb >> 8) & 0xFF;
	my $b = ($rgb) & 0xFF;
	print "color (R,G,B)  : ($r,$g,$b)\n";
=cut 

	#print Dumper(Qt::Image::pixel( $event->x, $event->y ));
	#print "pos : ", $event->pos(),"\n";
#	Qt::Image::setPixel($event->x, $event->y , 0x00FF00);
	#print "RGB : $rgb\n";
}

sub mousePressEvent
{
    my ($event) = @_;
    if ($event->button() != Qt::LeftButton()) {
        $event->ignore();
        return;
    }

    this->setCursor(Qt::Cursor(Qt::ClosedHandCursor()));
	print "mousePressEvent\n";
	#print "hasPixmap ? ", this->pixmap(), "\n";
	#print "is Valid ? : " , $rgb->Qt::Color->isValid();
=j	
	my $r = Qt::Color->red($rgb);
	##my $r = $rgb->qRed();
	#my $r = Qt::Color->red($rgb);
	my $g = Qt::Color->green();
	my $b = Qt::Color->blue();
#	print "color (R,G,B)  : ($r,$g,$b)\n";
	print "RGB : $rgb\n";
=cut
}


=vj
sub mouseMoveEvent
{
    my ($event) = @_;
    if (Qt::LineF(Qt::PointF($event->screenPos()), Qt::PointF($event->buttonDownScreenPos(Qt::LeftButton())))
        ->length() < Qt::Application::startDragDistance()) {
        return;
    }

    my $drag = Qt::Drag($event->widget());
    my $mime = Qt::MimeData();
    $drag->setMimeData($mime);

    my $n = 0;
    if ($n++ > 2 && (rand(RAND_MAX) % 3) == 0) {
        my $image = Qt::Image('images/head.png');
        $mime->setImageData($image);

        $drag->setPixmap(Qt::Pixmap::fromImage($image)->scaled(30, 40));
        $drag->setHotSpot(Qt::Point(15, 30));
    } else {
        $mime->setColorData(Qt::qVariantFromValue(this->{color}));
        $mime->setText(sprintf '#%02x%02x%02x',
                      this->{color}->red(),
                      this->{color}->green(),
                      this->{color}->blue());

        my $pixmap = Qt::Pixmap(34, 34);
        $pixmap->fill(Qt::Color(Qt::white()));

        my $painter = Qt::Painter($pixmap);
        $painter->translate(15, 15);
        $painter->setRenderHint(Qt::Painter::Antialiasing());
        this->paint($painter, 0, 0);
        $painter->end();

        $pixmap->setMask($pixmap->createHeuristicMask());

        $drag->setPixmap($pixmap);
        $drag->setHotSpot(Qt::Point(15, 20));
    }

    $drag->exec();
    this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
}
=cut

sub mouseReleaseEvent
{
    this->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
    print "mouseReleaseEvent\n";
}


sub wheelEvent
{
	my ($event) = @_;
	my $delta = $event->delta();
	print "wheelEvent, delta : $delta - ";
	if($delta > 0){
		print "up\n";
#		if($event->keyPressed() ){ #== Qt::ControlModifier
	#	if( Qt::Control.ModifierKeys == Keys.Ctrl ){
	#		print "ctrl pressed\n";
	#	}
	} else {
		print "down\n";
	}
}

sub keyPressEvent
{
	my ($event) = @_;
	print "keyPressEvent\n";
}

1;
