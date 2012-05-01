package MainWindow;

use strict;

use QtCore4;
use QtGui4;
use Qsci;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    newEditor      => [''],
    save           => [''],
    load           => [''],
    undo           => [''],
    about          => [''],
    insertCustomer => ['QString'],
    addParagraph   => ['QString'],
    genImage       => [''];
use LabelImage; 

sub NEW {
	print "nb args : " , scalar(@_), "\n";
	my $file;
	if(scalar(@_) > 1){
		$file=$_[1];
	}
	shift->SUPER::NEW($_[1]);

	my $textEdit = new QsciScintilla;
    this->{textEdit} = $textEdit;
    this->setCentralWidget($textEdit);
    my $lexerTeX = new QsciLexerTeX;
    this->{textEdit}->setLexer($lexerTeX);
    this->{textEdit}->setMarginLineNumbers (1, 1);
    this->{textEdit}->setMarginWidth(1, 30);
    
    this->{nodeDistance} = 50;
   # this->{density} = 72;
    this->{density} = 90;

    createActions();
    createMenus();
    createToolBars();
    createDockWindows();
	createStatusBar();
	
    this->setWindowTitle("Tikz G");

    newEditor();
    
 #   print "file : $file\n";
	if(defined $file){
		loadFile($file);
	}
}

sub newEditor {
    this->{textEdit}->clear(); 
}


sub save {
    my $fileName = Qt::FileDialog::getSaveFileName(this,
                        "Choose a file name", ".",
                        "tikz (*.tikz)");
    if (!$fileName) {
        return;
    }

    my $FH;
    if(!(open $FH, '>', $fileName)) {
        Qt::MessageBox::warning(this, "Dock Widgets",
                                 sprintf("Cannot write file %s:\n%s.",
                                 $fileName,
                                 $!));
        return;
    }

    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    print $FH this->{textEdit}->text();
    print $FH "\n";
    close $FH;
    Qt::Application::restoreOverrideCursor();

    this->statusBar()->showMessage("Saved '$fileName'", 2000);
}

sub load {
	#my $fileName = Qt::FileDialog::

 #   if (maybeSave()) {
	 # /home/randoom/2012/pstl/for_perlqt4/perlqt/qtgui/examples/mainwindows/application

	my $fileName = Qt::FileDialog::getOpenFileName(this);
	if ($fileName) {
		loadFile($fileName);
	}
  #  }

}

sub loadFile {
    my ( $fileName ) = @_;
    if(!(open( FH, "< $fileName"))) {
        Qt::MessageBox::warning(this, "Application",
                                 sprintf("Cannot read file %s:\n%s.",
                                 $fileName,
                                 $!));
        return 0;
    }
	my $text = "";
	foreach( <FH> ){
		$text .= $_;
	}

    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
   this->{textEdit}->setText($text);
    Qt::Application::restoreOverrideCursor();
    close FH;

   # setCurrentFile($fileName);
    this->statusBar()->showMessage("File loaded", 2000);
	&genImage();
}

sub undo {
    my $document = this->{textEdit}->document();
    $document->undo();
}


sub about {
   Qt::MessageBox::about(this, "A propos",
            "<b>TikzG</b> permet de ..." .
            "........".
            "................." );
}

sub createActions {
    my $newEditorAct = Qt::Action(Qt::Icon("images/new.png"), "&New",
                               this);
    this->{newEditorAct} = $newEditorAct;
    $newEditorAct->setShortcut(Qt::KeySequence("Ctrl+N"));
    $newEditorAct->setStatusTip("Create a new tikz");
    this->connect($newEditorAct, SIGNAL 'triggered()', this, SLOT 'newEditor()');

    my $saveAct = Qt::Action(Qt::Icon("images/save.png"), "&Save...", this);
    this->{saveAct} = $saveAct;
    $saveAct->setShortcut(Qt::KeySequence("Ctrl+S"));
    $saveAct->setStatusTip("Save the current tikz");
    this->connect($saveAct, SIGNAL 'triggered()', this, SLOT 'save()');
    
    my $loadAct = Qt::Action(Qt::Icon("images/load.png"), "&Ouvrir", this);
    this->{loadAct} = $loadAct;
    $loadAct->setShortcut(Qt::KeySequence("Ctrl+O"));
    $loadAct->setStatusTip("Load tikz");
    this->connect($loadAct, SIGNAL 'triggered()', this, SLOT 'load()');

    my $undoAct = Qt::Action(Qt::Icon("images/undo.png"), "&Undo", this);
    this->{undoAct} = $undoAct;
    $undoAct->setShortcut(Qt::KeySequence("Ctrl+Z"));
    $undoAct->setStatusTip("Undo the last editing action");
    this->connect($undoAct, SIGNAL 'triggered()', this, SLOT 'undo()');

    my $quitAct = Qt::Action("&Quit", this);
    this->{quitAct} = $quitAct;
    $quitAct->setShortcut(Qt::KeySequence("Ctrl+Q"));
    $quitAct->setStatusTip("Quit the application");
    this->connect($quitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    my $aboutAct = Qt::Action("&About", this);
    this->{aboutAct} = $aboutAct;
    $aboutAct->setStatusTip("Show the application's About box");
    this->connect($aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    my $aboutQtAct = Qt::Action("About &Qt", this);
    this->{aboutQtAct} = $aboutQtAct;
    $aboutQtAct->setStatusTip("Show the Qt4 library's About box");
    this->connect($aboutQtAct, SIGNAL 'triggered()', Qt::qApp(), SLOT 'aboutQt()');
    
    my $genAct = Qt::Action("generer image", this);
    this->{genAct} = $genAct;
    $genAct->setShortcut(Qt::KeySequence("Ctrl+R"));
    $genAct->setStatusTip("genere une image");
    this->connect($genAct, SIGNAL 'triggered()', this, SLOT 'genImage()');

}

sub createMenus {
    my $fileMenu = this->menuBar()->addMenu("&Fichier");
    $fileMenu->addAction(this->{newEditorAct});
    $fileMenu->addAction(this->{saveAct});
    $fileMenu->addAction(this->{loadAct});
    $fileMenu->addSeparator();
    $fileMenu->addAction(this->{quitAct});

    my $editMenu = this->menuBar()->addMenu("&Edit");
    $editMenu->addAction(this->{undoAct});

    my $viewMenu = this->menuBar()->addMenu("&View");
    this->{viewMenu} = $viewMenu;

    this->menuBar()->addSeparator();

    my $helpMenu = this->menuBar()->addMenu("&Help");
    $helpMenu->addAction(this->{aboutAct});
    $helpMenu->addAction(this->{aboutQtAct});
}

sub createToolBars {
    my $fileToolBar = this->addToolBar("File");
    $fileToolBar->addAction(this->{newEditorAct});
    $fileToolBar->addAction(this->{saveAct});
    $fileToolBar->addAction(this->{loadAct});

    my $editToolBar = this->addToolBar("Edit");
    $editToolBar->addAction(this->{undoAct});
    $editToolBar->addAction(this->{genAct});
    
}

sub createStatusBar {
    this->statusBar()->showMessage("Ready");
}

sub createDockWindows {
   
    my $dock = Qt::DockWidget("Graphe", this);
    $dock->setAllowedAreas(Qt::LeftDockWidgetArea() | Qt::RightDockWidgetArea());
    $dock->setFeatures(Qt::DockWidget::DockWidgetMovable() | Qt::DockWidget::DockWidgetFloatable());
  #  my $view = Qt::Label($dock);
    my $view = LabelImage($dock);
    
   # $view->setPixmap(Qt::Pixmap("images/cheese.jpg"));
    this->{zoneGraphe} = $view;
 #   this->{zoneGraphe}->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
    $dock->setWidget($view);
    this->addDockWidget(Qt::RightDockWidgetArea(), $dock);
    this->{viewMenu}->addAction($dock->toggleViewAction());
    
   # this->connect($view, SIGNAL 'currentTextChanged(const QString &)',
   #            this, SLOT 'genImage()');
}

sub genImage {
	my ($distance_node, $density)=(this->{nodeDistance}, this->{density} = 72);

	# suppresions de tous les tmp
	#clean();
	
	
	# generation du fichier tex
	my $FH;
	my $filename = "tmp/tmp_tikz";
    if(!(open $FH, '>', $filename)) {
        Qt::MessageBox::warning(this, "Dock Widgets",
                                 sprintf("Cannot write file %s:\n%s.",
                                 $filename,
                                 $!));
        return;
    }

#    print $FH this->{textEdit}->toPlainText();
	print $FH this->{textEdit}->text();
    print $FH "\n";
    close $FH;
    
    # generation d' un fichier png a partir d' un fichier tex
    
    # tikz2png.pl file distance_node density"
    
    #my $distance_node=50;
    
    #my $density=100;	###
    
    #my $density=72;
    system("perl tikz2png.pl tmp_tikz $distance_node $density");
    
    # lier l' image générée au QLabel de droite
    if( -e "./tmp/tmp_tikz.png"){
		this->{zoneGraphe}-> setPixmap(Qt::Pixmap("tmp/tmp_tikz.png"));
	} else {
		# si imposible de generer png, on affiche rien
		this->{zoneGraphe}-> setPixmap(Qt::Pixmap(""));
	#	my $pic = this->{zoneGraphe}->pixmap();
		
	}

   
}

# zoom +25 %
sub augmentDensity {
	this->{density} += 18;
	&genImage();
}

# zoom -25 %
sub diminueDensity {
	this->{density} -= 18;
	&genImage();
}

sub clean {
	system("rm tmp/*tmp*");
}

1;
