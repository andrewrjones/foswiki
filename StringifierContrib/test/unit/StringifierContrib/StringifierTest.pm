package StringifierTest;
use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;
use utf8;
use Encode ();

sub encode {
  my ($this, $string) = @_;

  return Encode::encode($Foswiki::cfg{Site}{CharSet}, $string);
}

1;
