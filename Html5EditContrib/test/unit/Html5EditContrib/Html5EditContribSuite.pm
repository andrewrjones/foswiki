package Html5EditContribSuite;

use Unit::TestSuite;
our @ISA = qw( Unit::TestSuite );

sub name { 'Html5EditContribSuite' }

sub include_tests { qw(Html5EditContribTests) }

1;
