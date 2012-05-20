package MainWindow;

use strict;

use QtCore4;
use QtGui4;
use Qsci;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    newEditor      => [''],
    load           => [''],
    save           => [''],
    saveAs         => [''],
    exportAsPng    => [''],
    exportAsPdf    => [''],
    copyTikzpicture=> [''],
    printSlot      => [''],
    undo           => [''],
    about          => [''],
    insertCustomer => ['QString'],
    addParagraph   => ['QString'],
    genImage       => [''],
    documentWasModified => [];
use LabelImage;
use TikzParser;
use TikzObjects;
use Data::Dumper; 
use File::Basename;
use File::Spec;

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
    
    this->{listeInstructions} = \@liste_instructions; # reference sur liste
    this->{listeNoeuds} = \@listenoeuds;

    createActions();
    createMenus();
    createToolBars();
    createDockWindows();
	createStatusBar();
	
    #this->setWindowTitle("Tikz G");

    newEditor();
    
    #this->connect($textEdit, SIGNAL 'isModified()',
    this->connect(this->{textEdit}, SIGNAL 'textChanged()',
                  this, SLOT 'documentWasModified()');

    
 #   print "file : $file\n";
	if(defined $file){
		loadFile($file);
		#parse();
	} else {
		this->setCurrentFile("");
	}
}

sub newEditor {
    this->{textEdit}->clear(); 
    setCurrentFile("");
}

sub setCurrentFile {
    my ( $fileName ) = @_;
    this->{curFile} = $fileName;
    this->{textEdit}->setModified(0);
    this->setWindowModified(0);

    my $shownName;
    my $path;
    if (!defined this->{curFile} || !(this->{curFile})) {
        $shownName = "Sans Titre";
    }
    else {
		my $curFile = this->{curFile};
        $shownName = &basename($curFile);
        $path = &dirname($curFile);
        $path = File::Spec->rel2abs($path);
    }
	if (defined $path){
		this->setWindowTitle(sprintf("\[*]%s - %s - %s", $shownName,$path, "TikzG"));
	} else {
		this->setWindowTitle(sprintf("\[*]%s - %s", $shownName, "TikzG"));
	}
}

sub maybeSave {
    if (this->{textEdit}->document()->isModified()) {
        my $ret = Qt::MessageBox::warning(this, "Application",
                        "The document has been modified.\n" .
                        "Do you want to save your changes?",
                        CAST Qt::MessageBox::Save() | Qt::MessageBox::Discard() | Qt::MessageBox::Cancel(), 'QMessageBox::StandardButtons'); 
        if ($ret == Qt::MessageBox::Save()) {
            return save();
        }
        elsif ($ret == Qt::MessageBox::Cancel()) {
            return 0;
        }
    }
    return 1;
}

sub save {
#	printf "save, curFile : %s\n", this->{curFile};
    if (!defined this->{curFile} || !this->{curFile}) {
        return saveAs();
    } else {
        return saveFile(this->{curFile});
    }
}

sub saveAs {
	#printf "saveAs, curFile : %s\n", this->{curFile};
    my $fileName = Qt::FileDialog::getSaveFileName(this);
    #printf "getSaveFileName, fileName : %s\n", $fileName;
    if (!defined $fileName){
        return 0;
    }

    return saveFile($fileName);
}

sub saveFile {
	my ($fileName) = @_;
    #printf "saveFile, fileName : %s\n", $fileName;
    
    my $FH;
    if(!(open $FH, '>', $fileName)) {
        Qt::MessageBox::warning(this, "Dock Widgets",
                                 sprintf("Impossible d\' écrire le fichier %s:\n%s.",
                                 $fileName,
                                 $!));
        return;
    }

    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    print $FH this->{textEdit}->text();
    print $FH "\n";
    close $FH;
    Qt::Application::restoreOverrideCursor();

	setCurrentFile($fileName);
    this->statusBar()->showMessage("Fichier '$fileName' sauvegardé", 2000);
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

    setCurrentFile($fileName);
    this->statusBar()->showMessage("File loaded", 2000);
	&genImage();
}

sub forceExtension{
	my ($fileName,$extension) = @_;
	my ($file,$suffix) = split /[.]/,$fileName;
	printf "file : %s,  suffix : %s\n", $file, $suffix;
	if($suffix ne $extension){
		print "export as $extension $fileName\n";
		return "$file.$extension";
	} else  {
		print "export as $extension $fileName\n";
		return $fileName;
	}
}

sub exportAsPng{
	my $fileName = Qt::FileDialog::getSaveFileName(this,
					" Exporter en tant que", ".",
					"png (*.png)");
	print "filename : $fileName\n";
	my $pngFile = forceExtension($fileName, "png");
	print "pngfile  : $pngFile\n";
	system("cp tmp/tmp_tikz.png $pngFile");
}

sub exportAsPdf{
	my $fileName = Qt::FileDialog::getSaveFileName(this,
					" Exporter en tant que", ".",
					"pdf (*.pdf)");
	print "filename : $fileName\n";
	my $pdfFile = forceExtension($fileName, "pdf");
	print "pdfFile  : $pdfFile\n";
	system("cp tmp/tmp_tikz.pdf $pdfFile");
}

sub copyTikzpicture{
	my $code_tikzpicture= sprintf "\\begin{tikzpicture}%s\n\\end{tikzpicture}\n", this->{textEdit}->text();
	
	my $pressePapier = Qt::Application::clipboard();
	#Pour mettre du texte dans le presse papier
	$pressePapier->setText($code_tikzpicture);
	print $code_tikzpicture;
}


sub printSlot {
    my $document = this->{textEdit}->text();
    my $printer = Qt::Printer();
    my $dialog = Qt::PrintDialog($printer, this);
    if ($dialog->exec() != ${Qt::Dialog::Accepted()}){
        return;
    }

    $document->print($printer);

    this->statusBar()->showMessage("Impression en cours", 2000);
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

sub documentWasModified {
    this->setWindowModified(this->{textEdit}->isModified());
}

sub createActions {
    my $newEditorAct = Qt::Action(Qt::Icon("images/new.png"), "&Nouveau",
                               this);
    this->{newEditorAct} = $newEditorAct;
    $newEditorAct->setShortcut(Qt::KeySequence("Ctrl+N"));
    $newEditorAct->setStatusTip("Créer un nouveau fichier tikz");
    this->connect($newEditorAct, SIGNAL 'triggered()', this, SLOT 'newEditor()');
    
    my $loadAct = Qt::Action(Qt::Icon("images/load.png"), "&Ouvrir", this);
    this->{loadAct} = $loadAct;
    $loadAct->setShortcut(Qt::KeySequence("Ctrl+O"));
    $loadAct->setStatusTip("Ouvrir un code tikz");
    this->connect($loadAct, SIGNAL 'triggered()', this, SLOT 'load()');

	my $saveAct = Qt::Action(Qt::Icon("images/save.png"), "&Enregistrer", this);
    this->{saveAct} = $saveAct;
    $saveAct->setShortcut(Qt::KeySequence("Ctrl+S"));
    $saveAct->setStatusTip("Enregistrer le fichier courant");
    this->connect($saveAct, SIGNAL 'triggered()', this, SLOT 'save()');
    
    my $saveAsAct = Qt::Action(Qt::Icon("images/saveAs.png"), "Enregistrer &sous", this);
    this->{saveAsAct} = $saveAsAct;
    $saveAsAct->setShortcut(Qt::KeySequence("Ctrl+Shift+S"));
    $saveAsAct->setStatusTip("Enregistrer sous");
    this->connect($saveAsAct, SIGNAL 'triggered()', this, SLOT 'saveAs()');
    
    my $exportAsPngAct = Qt::Action("png", this);
    this->{exportAsPngAct} = $exportAsPngAct;
    $exportAsPngAct->setStatusTip("Exporter en tant que png");
    this->connect($exportAsPngAct, SIGNAL 'triggered()', this, SLOT 'exportAsPng()');
    
    my $exportAsPdfAct = Qt::Action("pdf", this);
    this->{exportAsPdfAct} = $exportAsPdfAct;
    $exportAsPdfAct->setStatusTip("Exporter en tant que pdf");
    this->connect($exportAsPdfAct, SIGNAL 'triggered()', this, SLOT 'exportAsPdf()');
    
    my $copyTikzpictureAct = Qt::Action(Qt::Icon("images/copyTikz.png"), "&Copier source figure tikz", this);
    this->{copyTikzpictureAct} = $copyTikzpictureAct;
    $copyTikzpictureAct->setShortcut(Qt::KeySequence("Ctrl+Shift+C"));
    $copyTikzpictureAct->setStatusTip("Copier code source figure tikz");
    this->connect($copyTikzpictureAct, SIGNAL 'triggered()', this, SLOT 'copyTikzpicture()');
    
    my $printAct = Qt::Action(Qt::Icon("images/print.png"), "Imprimer code Tikz", this);
    this->{printAct} = $printAct;
    $printAct->setShortcut(Qt::KeySequence("Ctrl+P"));
    $printAct->setStatusTip("Imprimer le code Tikz");
    this->connect($printAct, SIGNAL 'triggered()', this, SLOT 'printSlot()');
    
    my $quitAct = Qt::Action("&Quitter", this);
    this->{quitAct} = $quitAct;
    $quitAct->setShortcut(Qt::KeySequence("Ctrl+Q"));
    $quitAct->setStatusTip("Quitter l' application");
    this->connect($quitAct, SIGNAL 'triggered()', this, SLOT 'close()');
    
    
    my $undoAct = Qt::Action(Qt::Icon("images/undo.png"), "&Undo", this);
    this->{undoAct} = $undoAct;
    $undoAct->setShortcut(Qt::KeySequence("Ctrl+Z"));
    $undoAct->setStatusTip("Undo the last editing action");
    this->connect($undoAct, SIGNAL 'triggered()', this, SLOT 'undo()');

    

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
    $fileMenu->addSeparator();
    $fileMenu->addAction(this->{loadAct});
    $fileMenu->addSeparator();
    $fileMenu->addAction(this->{saveAct});
    $fileMenu->addAction(this->{saveAsAct});
    $fileMenu->addSeparator();
    my $fileExportMenu = $fileMenu->addMenu("E&xporter");
		$fileExportMenu->addAction(this->{exportAsPngAct});
		$fileExportMenu->addAction(this->{exportAsPdfAct});
	$fileMenu->addAction(this->{copyTikzpictureAct});
    $fileMenu->addSeparator();
    $fileMenu->addAction(this->{printAct});
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
	$fileToolBar->addAction(this->{copyTikzpictureAct});
	
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
	&ColorId::reset_ColorId();
	@liste_instructions = &TikzParser::decoupe_lignes(this->{textEdit}->text());
	&TikzParser::parse_liste_instructions(@liste_instructions);
=dbg
	print "-"x80;
	foreach(@liste_instructions){
		print $_->{code}, "\n";
	}
	print "-"x80;	
=cut
	#this->{listeInstructions} = \@liste_instructions;
#	print "_"x80; #dbg
#	print "parsing\n";
#	print "~"x80; #dbg
	#print Dumper(this->{listeInstructions}); #dbg
	#@liste_instructions = @{this->{listeInstructions}};
}


sub list_of_nodes{
=dbg
	print "list nodes \n";
	print "-"x80;
	printf "length liste_instructions : %d\n", scalar(@liste_instructions);
=cut
#	print Dumper(@liste_instructions);
	foreach my $elem (@liste_instructions){
		if($elem->{type} eq "node") {
			push (@listenoeuds, $elem->{nom});
		}
	}
#	print "-"x80; #dbg
	#print Dumper(this->{listeNoeuds}); #dbg
	#print "-x"x80; #dbg
	#@listenoeuds = \@{listenoeuds};
	#print Dumper(\@{listenoeuds}); #dbg
}

sub nb_IDC{
	my $nb_IDC = 0;
#	printf "nb_IDC => length liste_instructions : %d\n", scalar(@liste_instructions);
#	print Dumper(@liste_instructions);
	foreach my $elem (@liste_instructions){
		if(defined($elem->{colorId})) {
			$nb_IDC++;
		}
	}
#	print "nb IDC : $nb_IDC\n";
#	print "-"x80; #dbg
	return $nb_IDC;
}


sub object_ofIDC{
	my ($idc) = @_;
	$idc="$idc,fill=$idc";
#	print " >>> idc : $idc\n";
	my $nb_IDC = nb_IDC();
#	print "="x80;
	foreach my $elem (@liste_instructions){
		if(defined($elem->{colorId}) && ($elem->{colorId} eq $idc) ) {
	#		print $elem->{colorId},"  ", $elem->{ligne},"\n";
			return $elem;
		}
	}	
}



1;
