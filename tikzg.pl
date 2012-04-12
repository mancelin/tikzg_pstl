#!/usr/bin/perl -w

use strict;

use QtCore4;
use QtGui4;
use MainWindow;
use QtCore4::debug qw(ambiguous);

sub main {
    my $app = Qt::Application();
    my $mainWin = MainWindow();
    $mainWin->resize(700,400);
    $mainWin->show();
    exit $app->exec();
}

main();
