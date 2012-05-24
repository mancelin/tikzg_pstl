#!/bin/sh

# dossier ou tout sera telechargé pour les install
mkdir for_perlqt4
cd for_perlqt4

# ligne en dessous ptet a decomenter ...
# sudo apt-get install libsmokeqt4-dev

apt-get install git # installe git si besoin
apt-get install kdelibs5-dev 
apt-get install qt4-qmake
apt-get install cmake
apt-get install g++
apt-get install libsmokeqt4-dev

#new 
apt-get install perlmagick


# recuperation de Scintilla ( et decompression )
wget http://www.riverbankcomputing.co.uk/static/Downloads/QScintilla2/QScintilla-gpl-2.6.1.tar.gz
tar xfvz QSc*
# install Scintilla
cd QSc*/Qt4/
qmake qscintilla.pro
make
make install
cd ../..


# install de la libperl-dev
apt-get install libperl-dev

# smokegen
#git clone http://anongit.kde.org/smokegen
git clone git://anongit.kde.org/smokegen
cd smokegen
mkdir build	
cd build
cmake ..
make
make install
cd ../..

# smokeqt
git clone git://anongit.kde.org/smokeqt
cd smokeqt
mkdir build	
cd build
cmake ..
make
make install
cd ../..

# perlqt
git clone git://anongit.kde.org/perlqt
cd perlqt
mkdir build	
cd build
cmake ..
make
make install
cd ../..

# quelques modules perl
cpan install List::MoreUtils
#cpan install Ix::IxHash
#cpan install Image::PNG
