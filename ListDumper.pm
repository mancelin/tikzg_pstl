package ListDumper;

use Exporter;
@ISA = ('Exporter');
@EXPORT = ('listdump');

sub listdump {
	my $i=1;
	foreach(@_){
		print $i," ",$_,"\n";
		$i++;
	}
}

1;
