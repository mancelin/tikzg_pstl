package TikzNode;
use Exporter;
@ISA = qw(Exporter);
{
	sub new{
		my ($classe, $lineNumber,$shape, $isDraw, $pos, $additionalProp, $name, $text, $colorId)= @_;
					#   1            2      3       4         5            6      7      8
		my %this = {
			"lineNumber" => $lineNumber,
			"shape" => $shape,
			"isDraw" => $isDraw,
			"pos" => $pos,
			"additionalProp" => $additionalProp,
			"name" => $name,
			"text" => $text,
			"colorId" => $colorId
		};
		
		bless( %this, $classe );		  #lie la référence à la classe
		return $this;
	}
}
