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
    redo           => [''],
    cut            => [''],
    copy           => [''],
    paste          => [''],
    delete         => [''],
    selectAll      => [''],
    about          => [''],
    recalcul_density=> [''],
    addParagraph   => ['QString'],
    genImage       => [''],
 #   myEvent        => [''],	# dbg
    documentWasModified => [];
use LabelImage;
use TikzParser;
use TikzObjects;
use Data::Dumper; 
use File::Basename;
use File::Spec;
use utf8;

my @liste_instructions;
my @listenoeuds;
my @liste_noeuds_rel;
my @liste_arretes_rel;
my $mainWindow;
my $density;
my $zoomFactorImg;
my $timer = Qt::Timer();
my $generation_img_en_cours = 0;
my $viewMenu;
my $textBox_zoom;
my $currentFile_tikz;
#my $gen_rel;

sub NEW {
	#print "nb args : " , scalar(@_), "\n";
	my $file;
	if(scalar(@_) > 1){
		$file=$_[1];
	}
	shift->SUPER::NEW($_[1]);
	$mainWindow=this;
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
    this->{zoomFactorImg} = \$zoomFactorImg;
    this->{zoomFactorImg}=int((	$density / 18) *25);
    #printf "zoom_factor_image : %d\n", this->{zoomFactorImg};
    
    this->{listeInstructions} = \@liste_instructions; # reference sur liste
    this->{listeNoeuds} = \@listenoeuds;

    createActions();
    createMenus();
    createToolBars();
    createDockWindows();
	createStatusBar();
	
    #this->setWindowTitle("Tikz G");

    newEditor();
    
    this->{textBox_zoom}->setText(sprintf "%s", this->{zoomFactorImg});

    
    #this->connect($textEdit, SIGNAL 'isModified()',
    this->connect(this->{textEdit}, SIGNAL 'textChanged()',
                  this, SLOT 'documentWasModified()');
	this->connect( $timer, SIGNAL 'timeout()', this, SLOT 'genImage()' );
#	Qt::Object::connect( $timer, SIGNAL 'timeout()', this, SLOT 'myEvent()' );

	$currentFile_tikz="tmp_tikz";
	#$gen_rel=0;
    $timer->start(1000);

    
 #   print "file : $file\n";
	if(defined $file){
		loadFile($file);
		#parse();
	} else {
		this->setCurrentFile("");
	}
}


sub closeEvent {
    my ($event) = @_;
    if (maybeSave()) {
        $event->accept();
    } else {
        $event->ignore();
    }
}

sub update_textbox_zoom_image {
	my $zoomFactorImg = int((this->{density} / 18) *25);
#	printf "density : %d\n", this->{density};
#	printf "zoomFactorImg : %d\n", $zoomFactorImg;
	$textBox_zoom->setText(sprintf "%s", $zoomFactorImg);
}

sub documentWasModified {
    this->setWindowModified(this->{textEdit}->isModified());
    
    if (!$generation_img_en_cours){
	#	printf "Timer interval : %d\n      timerId : %d\n", $timer->interval(), $timer->timerId();
		$timer->start();
	}
}

=dbg
# pour test
sub myEvent {
	#my ($event) = @_;
	print "Event !!\n";
}
=cut



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
	my $curFile = &basename(this->{curFile});
    if (this->{textEdit}->isModified()) {
        my $ret = Qt::MessageBox::warning(this, "TikzG",
                        "Le fichier \'$curFile\' n' a pas été enregistré.\n" . 
                        "Voulez-vous l' enregistrer avant la fermeture?",
                        Qt::MessageBox::Save() | Qt::MessageBox::Discard() | Qt::MessageBox::Cancel()); 
        if ($ret == Qt::MessageBox::Save()) {
#			printf "save : %s\n", this->{curFile};
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
    #print "text :\n$text\n";
    utf8::decode($text);
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
	$pressePapier->setText($code_tikzpicture);
	
	#print $code_tikzpicture;
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
    this->{textEdit}->undo();
}

sub redo {
	this->{textEdit}->redo();
}

sub cut {
	this->{textEdit}->cut();
}

sub copy {
	this->{textEdit}->copy();
}

sub paste {
	this->{textEdit}->paste();
}

sub delete {
	this->{textEdit}->removeSelectedText();
}

sub selectAll {
	this->{textEdit}->selectAll();
}

sub about {
   Qt::MessageBox::about(this, "A propos",
            "<b>TikzG</b> permet de ..." .
            "........".
            "................." );
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
    
    
    my $undoAct = Qt::Action(Qt::Icon("images/undo.png"), "&Défaire", this);
    this->{undoAct} = $undoAct;
    $undoAct->setShortcut(Qt::KeySequence("Ctrl+Z"));
    $undoAct->setStatusTip("Annuler la derniére action");
    this->connect($undoAct, SIGNAL 'triggered()', this, SLOT 'undo()');

	my $redoAct = Qt::Action(Qt::Icon("images/redo.png"), "&Refaire", this);
    this->{redoAct} = $redoAct;
    $redoAct->setShortcut(Qt::KeySequence("Ctrl+Y"));
    $redoAct->setStatusTip("Refaire la derniére action");
    this->connect($redoAct, SIGNAL 'triggered()', this, SLOT 'redo()');
   
    my $cutAct = Qt::Action(Qt::Icon("images/cut.png"), "Co&uper", this);
    this->{cutAct} = $cutAct;
    $cutAct->setShortcut(Qt::KeySequence("Ctrl+X"));
    $cutAct->setStatusTip("Couper le texte sélectionné");
    this->connect($cutAct, SIGNAL 'triggered()', this, SLOT 'cut()'); 

	my $copyAct = Qt::Action(Qt::Icon("images/copy.png"), "&Copier", this);
    this->{copyAct} = $copyAct;
    $copyAct->setShortcut(Qt::KeySequence("Ctrl+C"));
    $copyAct->setStatusTip("Copier le texte sélectionné");
    this->connect($copyAct, SIGNAL 'triggered()', this, SLOT 'copy()'); 

	my $pasteAct = Qt::Action(Qt::Icon("images/paste.png"), "C&oller", this);
    this->{pasteAct} = $pasteAct;
    $pasteAct->setShortcut(Qt::KeySequence("Ctrl+V"));
    $pasteAct->setStatusTip("Coller le texte copié");
    this->connect($pasteAct, SIGNAL 'triggered()', this, SLOT 'paste()'); 

	my $deleteAct = Qt::Action("&Supprimer", this);
    this->{deleteAct} = $deleteAct;
    $deleteAct->setStatusTip("Supprimmer le texte sélectionné");
    this->connect($deleteAct, SIGNAL 'triggered()', this, SLOT 'delete()'); 
    
    my $selectAllAct = Qt::Action("&Tout sélectionner", this);
    this->{selectAllAct} = $selectAllAct;
    $selectAllAct->setShortcut(Qt::KeySequence("Ctrl+A"));
    $selectAllAct->setStatusTip("Sélectionner tout le texte sélectionné");
    this->connect($selectAllAct, SIGNAL 'triggered()', this, SLOT 'selectAll()'); 
    
  

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
    
    my $editMenu = this->menuBar()->addMenu("&Éditer");
    #my $strMenu ="&Éditer";
   # utf8::decode($strMenu);
    #my $editMenu = this->menuBar()->addMenu($strMenu);
    $editMenu->addAction(this->{undoAct});
	$editMenu->addAction(this->{redoAct});
	$editMenu->addSeparator();
	$editMenu->addAction(this->{cutAct});
	$editMenu->addAction(this->{copyAct});
	$editMenu->addAction(this->{pasteAct});
	$editMenu->addAction(this->{deleteAct});
	$editMenu->addSeparator();
	$editMenu->addAction(this->{selectAllAct});
	
	
	
	
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
    
    my $viewToolBar = this->addToolBar("View");
    my $label_textBox_zoom = Qt::Label("Zoom Image :");
    $viewToolBar->addWidget($label_textBox_zoom);
    $textBox_zoom = Qt::LineEdit();
    $textBox_zoom->setMaxLength(4);
    $textBox_zoom->setMaximumWidth(40);
    this->{textBox_zoom} = $textBox_zoom;
    this->connect($textBox_zoom, SIGNAL 'editingFinished()', this, SLOT 'recalcul_density()');
    $viewToolBar->addWidget($textBox_zoom);
    $viewToolBar->addWidget(Qt::Label("%"));
    
}

sub createStatusBar {
    this->statusBar()->showMessage("Ready");
}

sub createDockWindows {
    my $dock = Qt::DockWidget("Graphe", this);
    this->{dock} = $dock;
    $dock->setAllowedAreas(Qt::LeftDockWidgetArea() | Qt::RightDockWidgetArea());
    $dock->setFeatures(Qt::DockWidget::DockWidgetMovable() | Qt::DockWidget::DockWidgetFloatable());
  #  my $view = Qt::Label($dock);
#    my $view = LabelImage($dock,\$density);
	my $viewMenu = LabelImage($dock,\$density,\$zoomFactorImg);
	
    this->{zoneGraphe} = $viewMenu;
 #   this->{zoneGraphe}->setCursor(Qt::Cursor(Qt::OpenHandCursor()));
    $dock->setWidget($viewMenu);
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


sub recalcul_density {
	my $textZoom = $textBox_zoom->text();
	if( $textZoom =~ /(^\s*(\d+)\s*$)/){
		printf "1 : %d, 2 : %d\n", $1, $2;
		this->{zoomFactorImg} = $textZoom;
		printf "zoom_factor_image : %d\n", this->{zoomFactorImg} ;
		this->{density} = int(($textZoom/25) * 18);
		my $density = this->{density};
		printf "density : %d\n", $density;
		system("convert -density $density tmp/tmp_tikz.pdf tmp_tikz.png");
		system("mv tmp_tikz.png tmp");
		system("convert -density $density tmp/tmp_tikz_IDC.pdf tmp_tikz_IDC.png");
		system("mv tmp_tikz_IDC.png tmp");
		this->{zoneGraphe}->setPixmap(Qt::Pixmap("tmp/tmp_tikz.png"));
	} else {	# si la valeur courante de la textbox de zoom n' est pas numérique, on reinitialise la textbox a la derniére valeur correcte
		printf "zoom_factor_image : %d\n", this->{zoomFactorImg};
		$textBox_zoom->setText(this->{zoomFactorImg});
	}
}
	


sub triggerWaitCursor {
	this->setCursor(Qt::Cursor(Qt::WaitCursor()));
	this->{dock}->setCursor(Qt::Cursor(Qt::WaitCursor()));
#	this->setStatusTip("Generation de la figure Tikz en cours ...");
	this->statusBar()->showMessage("Generation de la figure Tikz en cours ...",0);
#	this->{textEdit}->setCursor(Qt::Cursor(Qt::WaitCursor()));	# inutile
}

sub triggerArrowCursor {
	this->setCursor(Qt::Cursor(Qt::ArrowCursor()));
	this->{dock}->setCursor(Qt::Cursor(Qt::ArrowCursor()));
	this->statusBar()->clearMessage();
#	this->setStatusTip("");
}

sub genImage {
	$generation_img_en_cours = 1;
	$timer->stop();
	
	print "gen Image\n";  ##
	triggerWaitCursor();
	
	# reinitialisation de liste d' objets tikz et de liste d'instructions
	@liste_instructions = ();
	@listenoeuds = ();
	
	# recupération de val density du LabelImage
	this->{density}=this->{zoneGraphe}->{density} ;
	
	#my ($distance_node, $density)=(this->{nodeDistance}, this->{density});
	my ($density)=(this->{density});

	# suppresions de tous les tmp
	#clean();
	
	#my $filename = "tmp/".$currentFile_tikz;#"tmp/tmp_tikz";
	my $filename = "tmp/tmp_tikz";
	
	#if (!$gen_rel){
	#print "! gen_rel\n";
	# generation du fichier tikz
	my $FH;
	
	if(!(open $FH, '>', $filename)) {
		Qt::MessageBox::warning(this, "Dock Widgets",
								 sprintf("Cannot write file %s:\n%s.",
								 $filename,
								 $!));
		return;
	}

#    print $FH this->{textEdit}->toPlainText();
	my $text = this->{textEdit}->text();
	utf8::encode($text); 
	print $FH $text;
	print $FH "\n";
	close $FH;
	#}
	
	#print "-"x80, $currentFile_tikz, "\n","-"x80;
    
    # generation d' un fichier png a partir du code tikz
    #system("perl tikz2png.pl tmp_tikz $density");
    system("perl tikz2png.pl tmp_tikz $density");
    
    # lier l' image générée au QLabel de droite
    my $png = "tmp/tmp_tikz.png";
    #print "png : $png\n";
    if( -e $png){
		this->{zoneGraphe}-> setPixmap(Qt::Pixmap("tmp/tmp_tikz.png"));
		this->{zoneGraphe}->setPixmap(Qt::Pixmap($png));
	} else {
		# si imposible de generer png, on affiche rien
		this->{zoneGraphe}->setPixmap(Qt::Pixmap(""));
	#	my $pic = this->{zoneGraphe}->pixmap();
		
	}

   parse();
   list_of_nodes();
   $generation_img_en_cours = 0;
   triggerArrowCursor();
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
#	print Dumper(@liste_instructions); #dbg
	#@liste_instructions = @{this->{listeInstructions}};
}



######      fonctions pour acceder au objets Tikz	#####

sub list_of_nodes {
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

# rend la liste des objets tikz correspondant au noeud passé en paramétre
sub get_objsTikz_of_nodes {
	my @node_names = @_;
	my @list_objsTikz;
	my $i=0;
	foreach my $elem (@liste_instructions){
		if(($i < scalar(@node_names)) && ($elem->{type} eq "node") && ($elem->{nom} eq $node_names[$i])) {
			printf "elemnt : %s\n", $elem->{nom};
			push (@list_objsTikz, $elem);
			$i++;
		}
	}
	return @list_objsTikz;
}


# rend la liste des noeuds liés au noeud passé en paramètre
sub list_of_relative_nodes {
	my ($node) = @_;
	@liste_noeuds_rel = ();
	#printf "list_of_relative_nodes %s\n", $node->{nom};
	#print Dumper(@liste_instructions);
	foreach my $elem (@liste_instructions){
		#print Dumper($elem);
		if(($elem->{type} eq "node") && ($elem->{nom} ne $node->{nom}) ){
			#printf "elem nom : %s, node nom : %s\n", $elem->{nom}, $node->{nom};
			if(param_contient_noeud($node->{nom}, values $elem->{params})) {
				#printf "adding %s\n", $elem->{nom};
				push (@liste_noeuds_rel, $elem);
			}
		}
	}
}


# retourne 1 si le hash de paramètres params_node contient le noeud nom_noeud
sub param_contient_noeud {
	my ($nom_noeud, @params_node) = @_;
	#printf "nom_noeud : %s\n params_node : \n", $nom_noeud;
	#print Dumper(@params_node);
	#print "-"x80;
	foreach my $param (@params_node){
		if($param =~ /\Q$nom_noeud/){		
			return 1;
		}
	}
	return 0;
}

# rend la liste des arrếtes liées au noeud passé en paramètre
sub list_of_relative_draw {
	my ($node) = @_;
	#printf "list_of_relative_nodes %s\n", $node->{nom};
	foreach my $elem (@liste_instructions){
		if(($elem->{type} eq "draw") && (($elem->{origine} eq $node->{nom}) || ($elem->{but} eq $node->{nom})) ){
				#print "adding %s\n", $elem->{nom};
				push (@liste_arretes_rel, $elem);
		}
	}
}

# rend la liste des noms des noeuds liés a une arrête passée en paramètre
sub list_of_relative_nodes_of_draw {
	my ($arrete) = @_;
	#printf "list_of_relative_nodes %s\n", $node->{nom};
	my @liste_noms_noeuds_rel;
	push (@liste_noms_noeuds_rel, $arrete->{origine});
	push (@liste_noms_noeuds_rel, $arrete->{but});
	@liste_noeuds_rel=get_objsTikz_of_nodes(@liste_noms_noeuds_rel);
}

# retourne l' objet tikz associé au noeud passé en paramétre
sub tikzobj_of_node {
	my ($node_name) = @_;
	foreach my $elem (@liste_instructions){
		if(($elem->{type} eq "node") && ($elem->{nom} eq $node_name)) {
			return $elem;
		}
	}
}

# retourne l' index de l' objet dont la ligne est passé en paramétre dans la liste passée en paramètre, -1 si non trouvé
sub index_of_line {
	my ($ligne) = @_;
	my $i=0;
	#printf "index_of_line : $ligne\n";
	foreach my $elem (@liste_instructions){
		if($elem->{ligne} == $ligne) {
			return $i;
		}
		$i++;
	}
	return (-1);
}

# retourne la chaine de charactéres correspondant a la liste d' instruction passé en paramètre
sub string_of_liste_instructions {
	my ($rel_color_actif, @l_instructions) = @_;
	my $prog_tikz ="";
	#printf "length list : %d\n", scalar(@l_instructions);
	foreach my $elem (@liste_instructions){
		if ($elem->{type} eq "node"){
			$prog_tikz.='\node';
			#print '\node';
			if (defined($elem->{params_keys}) && (scalar ($elem->{params_keys}) > 0 )) {
				$prog_tikz.='['.string_of_param($elem, $elem->{params_keys});
				if ((defined ($elem->{couleur_rel})) && $rel_color_actif) {
					$prog_tikz.=",fill=".$elem->{couleur_rel}.'] ';
				} else {
					$prog_tikz.='] ';
				}
			#	print '['.string_of_param($elem, $elem->{params_keys}).'] ';
			}
			$prog_tikz.='('.$elem->{nom}.') {'.$elem->{text}.'}'.";\n";
		} elsif ( $elem->{type} eq "draw" ) {
			#print "draw\n";
			$prog_tikz.='\draw';
			if (defined($elem->{params_keys}) && (scalar ($elem->{params_keys}) > 0 )) {
				$prog_tikz.='['.string_of_param($elem, $elem->{params_keys});
				if ((defined ($elem->{couleur_rel})) && $rel_color_actif) {
					$prog_tikz.=",".$elem->{couleur_rel}.'] ';
				} else {
					$prog_tikz.='] ';
				}
			}
			$prog_tikz.='('.$elem->{origine}.') -- ('.$elem->{but}.')'.";\n";
		} #elsif ( $elem->{type} eq "NodeDistance" ) {
		else {
			$prog_tikz.=$elem->{code}."\n";
		}
	}
	#print "prog tikz :\n", $prog_tikz;
	#print "-"x80;
	#print "rel_color_actif : $rel_color_actif\n";
	return $prog_tikz;	
}

=cr
                 'ligne' => 4,
                 'colorId' => 'red!30!green!32,fill=red!30!green!32',
                 'params' => {
                               '->' => undef
                             },
                 'params_keys' => [
                                    '->'
                                  ],
                 'origine' => 'n1',
                 'type' => 'draw',
                 'but' => 'n2',
                 'code' => '\\draw[->] (n1) -- (n2);',
                 'code_segment' => ' -- '
               }, 'TikzObjects' );
=cut


sub string_of_param {
	my ($elem, $ref_params_keys) = @_;
	my @params_keys = @$ref_params_keys;
	my $length = scalar(@params_keys);
	my $res_string="";
	for (my $i=0; $i < $length; $i++) {
		if (defined ($elem->{params}->{$params_keys[$i]} ) ){
			$res_string.=$params_keys[$i]."=".$elem->{params}->{$params_keys[$i]}.",";
		} else {
			$res_string.=$params_keys[$i].",";
		}

	}
	# suppression du dernier caractére de $res_string ( , )
	chop $res_string;
	
	return $res_string;
}


# reinitialise les couleurs rel
sub reset_couleur_rel {
	foreach my $elem (@liste_instructions){
		if(defined($elem->{couleur_rel}) ) {
			$elem->{couleur_rel} = undef;
		}
	}
}
			
	

# ajoute un couleur a un élément tikz pour le "marquer" en tant que liée a d' autre noeuds
sub mark_as_rel {
	my ($objTikz , $color ) = @_;
	$objTikz->{couleur_rel} = $color;
	#$objTikz->{params}->{fill}=$color;
	#return $objTikz;
}

# cree une image ou les objets relatifs a objTikz sont colorés et l' affiche
sub make_list_instructions_rel {
	my ($objTikz , $color_obj_select) = @_;
	reset_couleur_rel();
	#"blue!30"
	#my @liste_instructions_rel = @liste_instructions;
	#print "?"x80;
	#print Dumper(@liste_instructions_rel);
	
	my @l_rel_objects;
	#my @l_rel_draw;
	if ($objTikz->{type} eq "node" ){
		#mark_as_rel($objTikz, "blue!50");
		mark_as_rel($objTikz, $color_obj_select);
		list_of_relative_nodes($objTikz);
		list_of_relative_draw($objTikz);
		@l_rel_objects = (@liste_noeuds_rel,@liste_arretes_rel);
		#print Dumper(@l_rel_objects);
	} elsif ($objTikz->{type} eq "draw" ){
		#mark_as_rel($objTikz, "blue!50");
		mark_as_rel($objTikz, $color_obj_select);
		list_of_relative_nodes_of_draw($objTikz);
		@l_rel_objects = @liste_noeuds_rel;
	}
	
	#foreach my $elem (@list_instructions_rel){
	print "+"x80;
	print Dumper(@l_rel_objects);
	print "+"x80;
	foreach my $rel_obj (@l_rel_objects){
		my $ligne = $rel_obj->{ligne};
		my $i = index_of_line($ligne);
		if ($rel_obj->{type} eq "node") {
			mark_as_rel($liste_instructions[$i], "red!20");
		} elsif ($rel_obj->{type} eq "draw") {
			mark_as_rel($liste_instructions[$i], "red");
		}
	}
#=later	
	unless (open FICTIKZ_REL, ">tmp_tikz_rel"){
		die "Impossible d'ecrire sur 'tmp_tikz_rel' : $!";
	}
	
	my $entete_tikz= 
	q (\documentclass{article}
	\usepackage[graphics,tightpage,active]{preview}
	\usepackage[utf8]{inputenc}  
	\usepackage{xcolor}
	\usepackage{tikz}
	\PreviewEnvironment{tikzpicture}
	\begin{document}
	\begin{tikzpicture});
	
	my $fin=
	q(\end{tikzpicture}
	\end{document}
	);

	my $code_rel =string_of_liste_instructions(1,@liste_instructions);
	print FICTIKZ_REL $entete_tikz.$code_rel.$fin;
	close FICTIKZ_REL;
	print "code rel :\n",$code_rel;
	#$currentFile_tikz = "tmp_tikz_rel";
	system("pdflatex -halt-on-error tmp_tikz_rel > /dev/null");
	#my $img=$currentFile_tikz.".png";
	#print "img : $img\n";
	system("convert -density $density tmp_tikz_rel.pdf tmp_tikz_rel.png");

	system("rm *.log *.aux *.pdf");
	system("mv tmp_tikz_rel.png tmp");
	$mainWindow->{zoneGraphe}->setPixmap(Qt::Pixmap("tmp/tmp_tikz_rel.png"));
#	$gen_rel=1;
	
=later
	print "\n","-"x80, "code rel:\n";
	print $code;
	
	my $code2 =string_of_liste_instructions(0,@liste_instructions);
	print "\n","-"x80, "code non_rel:\n";
	print $code2;
=cut
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


sub object_ofIDC {
	my ($idc) = @_;
	$idc="$idc,fill=$idc";
#	print " >>> idc : $idc\n";
	my $nb_IDC = nb_IDC();
	@liste_noeuds_rel =();	
	@liste_arretes_rel =();	
#	print "="x80;
	foreach my $elem (@liste_instructions){
		if(defined($elem->{colorId}) && ($elem->{colorId} eq $idc) ) {
	#		print $elem->{colorId},"  ", $elem->{ligne},"\n";
			if($elem->{type} eq "node"){
				print $elem->{nom},"\n";
=MUTE
				list_of_relative_nodes($elem);
				print "-"x80;
				print "relative nodes :\n";
				print Dumper(@liste_noeuds_rel);
				list_of_relative_draw($elem);
			
				print "*"x80;
				print "relative draw :\n";
				print Dumper(@liste_arretes_rel);
=cut
				#make_list_instructions_rel($elem);
				make_list_instructions_rel($elem,"blue!50");

			} elsif ($elem->{type} eq "draw"){
=MUTE
				list_of_relative_nodes_of_draw($elem);
				print "_"x80;
				print "list_of_relative_nodes_of_draw :\n";
				print Dumper(@liste_noeuds_rel);
=cut
				make_list_instructions_rel($elem, "blue");
			}
			#print "-"x28, "  liste instruction bfr " , "-"x28;
			#print Dumper(@liste_instructions);

=fv			
			my $a_node = tikzobj_of_node("n1");
			print "/"x80;
			push $a_node->{params_keys},"fill";
			$a_node->{params}->{fill}="blue!30";
			print Dumper($a_node);
			my $index_n1 = index_of_line($a_node->{ligne},@liste_instructions);
			print "index_n1 : $index_n1\n";
			$liste_instructions[$index_n1] = $a_node;
			my $code =string_of_liste_instructions(@liste_instructions);
			print "\n","-"x80, "code :\n";
			print $code;
			#print "+"x28, " liste instruction aftr " , "+"x28;
=cut			
			#print Dumper(@liste_instructions);
			return $elem;
		}
	}	
}


1;
