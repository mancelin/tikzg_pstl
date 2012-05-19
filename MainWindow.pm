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
use TikzParser;
use TikzObjects;
use Data::Dumper; 

my @liste_instructions;
my @listenoeuds;
my $density;


sub NEW {
	#print "nb args : " , scalar(@_), "\n";
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
    this->{textEdit}->setUtf8(1);
    
   # this->{nodeDistance} = 50;
   # this->{density} = 72;
    $density = 90;
    this->{density} = \$density;
    
    this->{listeInstructions} = \@liste_instructions; # reference sur liste  ##
    this->{listeNoeuds} = \@listenoeuds;	##

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
		#parse();
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
    $newEditorAct->setStatusTip("Créer un nouveau fichier tikz");
    this->connect($newEditorAct, SIGNAL 'triggered()', this, SLOT 'newEditor()');

    my $saveAct = Qt::Action(Qt::Icon("images/save.png"), "&Save...", this);
    this->{saveAct} = $saveAct;
    $saveAct->setShortcut(Qt::KeySequence("Ctrl+S"));
    $saveAct->setStatusTip("Enregistrer le fichier courant");
    this->connect($saveAct, SIGNAL 'triggered()', this, SLOT 'save()');
    
    my $loadAct = Qt::Action(Qt::Icon("images/load.png"), "&Ouvrir", this);
    this->{loadAct} = $loadAct;
    $loadAct->setShortcut(Qt::KeySequence("Ctrl+O"));
    $loadAct->setStatusTip("Ouvrir un code tikz");
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
    my $view = LabelImage($dock,\$density);
    
   # $view->setPixmap(Qt::Pixmap("images/cheese.jpg"));
    this->{zoneGraphe} = $view;
 #   this->{zoneGraphe}->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
    $dock->setWidget($view);
    this->addDockWidget(Qt::RightDockWidgetArea(), $dock);
    this->{viewMenu}->addAction($dock->toggleViewAction());
    
   # this->connect($view, SIGNAL 'currentTextChanged(const QString &)',
   #            this, SLOT 'genImage()');
}


#propriétés du noeud sélectionné
sub proprieteNode{
    my $dock = Qt::DockWidget("Proprietes", this);
    my $top=Qt::Widget();
    my $layout = Qt::VBoxLayout();
    my $visible = Qt::CheckBox(this->tr('Visible'));
    $visible->setChecked(1);
    $layout->addWidget($visible);               #cacher le noeud
    $layout->addWidget(this->Qt::LineEdit());   #le nom du noeud
    my $forme=this->Qt::ComboBox();
    $forme->addItem(this->tr('Cercle'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $forme->addItem(this->tr('Rectangle'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $forme->addItem(this->tr('Triangle'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $layout->addWidget($forme);                 #la forme du noeud
    $layout->addWidget(Qt::LineEdit());         #dimension du noeud
    my $trait=this->Qt::ComboBox();
    $trait->addItem(this->tr('Plein'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $trait->addItem(this->tr('Pointille'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $trait->addItem(this->tr('Double'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $layout->addWidget($trait);                 #le type de trait
    $layout->addWidget(this->Qt::LineEdit());   #le texte inscrit dans le noeud
    $layout->addWidget(this->Qt::ComboBox());   #right of (à compléter après identification du noeud)
    $layout->addWidget(this->Qt::ComboBox());   #left of  (idem)
    $layout->addWidget(this->Qt::ComboBox());   #up of    (idem)
    $layout->addWidget(this->Qt::ComboBox());   #down of  (idem)
    $top->setLayout($layout);
    $dock->setWidget($top);
    this->addDockWidget(Qt::LeftDockWidgetArea(), $dock);
    this->{viewMenu}->addAction($dock->toggleViewAction());
}


#proprietes de l'arete selectionné
sub proprieteDraw{
    my $dock = Qt::DockWidget("Proprietes", this);
    my $top=Qt::Widget();
    my $layout = Qt::VBoxLayout();
    $layout->addWidget(this->Qt::LineEdit());   #le nom
    $layout->addWidget(this->Qt::ComboBox());   #origine (à compléter après identification de l'arete)
    my $sens=this->Qt::ComboBox();
    $sens->addItem(this->tr('<->'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $sens->addItem(this->tr('->'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $sens->addItem(this->tr('<-'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $sens->addItem(this->tr('-'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $layout->addWidget($sens);                 #le sens de l'arete
    my $trait=this->Qt::ComboBox();
    $trait->addItem(this->tr('Plein'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $trait->addItem(this->tr('Pointille'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $trait->addItem(this->tr('Double'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    $layout->addWidget($trait);                 #le type de trait
    $layout->addWidget(this->Qt::ComboBox());   #destination (à compléter après identification du noeud)


    $top->setLayout($layout);
    $dock->setWidget($top);
    this->addDockWidget(Qt::LeftDockWidgetArea(), $dock);
    this->{viewMenu}->addAction($dock->toggleViewAction());
}





sub genImage {
	# reinisialisation de liste d' objets tikz et de liste d'instructions
	@liste_instructions = ();
	@listenoeuds = ();
	
	# recupération de val density du LabelImage
	this->{density}=this->{zoneGraphe}->{density} ;
	
	#my ($distance_node, $density)=(this->{nodeDistance}, this->{density});
	my ($density)=(this->{density});

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
  #  system("perl tikz2png.pl tmp_tikz $distance_node $density");
    system("perl tikz2png.pl tmp_tikz $density");
    
    # lier l' image générée au QLabel de droite
    if( -e "./tmp/tmp_tikz.png"){
		this->{zoneGraphe}-> setPixmap(Qt::Pixmap("tmp/tmp_tikz.png"));
	} else {
		# si imposible de generer png, on affiche rien
		this->{zoneGraphe}-> setPixmap(Qt::Pixmap(""));
	#	my $pic = this->{zoneGraphe}->pixmap();
		
	}

   parse();
   list_of_nodes();
}

=waste
# zoom +25 %	##?
sub augmentDensity {
	this->{density} += 18;
	#&genImage();
}

# zoom -25 %	##?
sub diminueDensity {
	this->{density} -= 18;
	#&genImage();
}

sub density {
	return this->{density};
}

sub set_density {
	my ( $density ) = @_;
	print "set_density $density\n";
	this->{density} = $density;
}
=cut

sub clean {
	system("rm tmp/*tmp*");
}


sub parse {
	@liste_instructions = &TikzParser::decoupe_lignes(this->{textEdit}->text());
	&TikzParser::parse_liste_instructions(@liste_instructions);
	print "_"x80; #dbg
	print "parsing\n";
	print "~"x80; #dbg
	print Dumper(this->{listeInstructions}); #dbg
	#@liste_instructions = @{this->{listeInstructions}};
}


sub list_of_nodes{
	print "list nodes \n";
	print "-"x80;
	print Dumper(@liste_instructions);
	foreach my $elem (@liste_instructions){
		if($elem->{type} eq "node") {
			push (@listenoeuds, $elem->{nom});
		}
	}
	print "-x"x80; #dbg
	print Dumper(this->{listeNoeuds}); #dbg
	print "-x"x80; #dbg
	#@listenoeuds = \@{listenoeuds};
	print Dumper(\@{listenoeuds}); #dbg
}

sub nb_IDC{
	my $nb_IDC = 0;
	foreach my $elem (@liste_instructions){
		if(defined($elem->{colorId})) {
			$nb_IDC++;
		}
	}
	print "-"x80; #dbg
	return $nb_IDC;
}


sub object_ofIDC{
	my ($idc) = @_;
	$idc="$idc,fill=$idc";
	print " >>> idc : $idc\n";
	my $nb_IDC = nb_IDC();
	foreach my $elem (@liste_instructions){
		print $elem->{colorId},"\n";
		if(defined($elem->{colorId}) && ($elem->{colorId} eq $idc) ) {
			return $elem;
		}
	}	
}



1;
