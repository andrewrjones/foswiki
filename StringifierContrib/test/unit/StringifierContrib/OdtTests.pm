# Test for ODT.pm
package OdtTests;
use FoswikiFnTestCase;
our @ISA = qw( FoswikiFnTestCase );

use strict;

use Foswiki::Contrib::Stringifier::Base();
use Foswiki::Contrib::Stringifier();
use utf8;

sub set_up {
        my $this = shift;
        
    $this->{attachmentDir} = 'attachement_examples/';
    if (! -e $this->{attachmentDir}) {
        #running from foswiki/test/unit
        $this->{attachmentDir} = 'StringifierContrib/attachement_examples/';
    }
    
    $this->SUPER::set_up();
}

sub tear_down {
    my $this = shift;
    $this->SUPER::tear_down();
}

sub test_stringForFile {
    my $this = shift;
    my $stringifier = Foswiki::Contrib::Stringifier::Plugins::ODT->new();

    my $text  = $stringifier->stringForFile($this->{attachmentDir}.'test.odt');
    my $text2 = Foswiki::Contrib::Stringifier->stringFor($this->{attachmentDir}.'test.odt');

    $this->assert(defined($text), "No text returned.");
    $this->assert_str_equals($text, $text2, "ODT stringifier not well registered.");

    my $ok = $text =~ /breitschlag/;
    $this->assert($ok, "Text breitschlag not included");

    $ok = $text =~ /Grünkohl/;
    $this->assert($ok, "Text Grühnkohl not included");
}

1;
