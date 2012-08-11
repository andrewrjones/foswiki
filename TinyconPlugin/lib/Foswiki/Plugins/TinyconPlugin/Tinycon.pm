package Foswiki::Plugins::TinyconPlugin::Tinycon;
use strict;
use warnings;

use Foswiki::Plugins::JQueryPlugin ();
our @ISA = qw( Foswiki::Plugins::JQueryPlugin::Plugin );

use Foswiki::Plugins::JQueryPlugin::Plugin ();
use Foswiki::Plugins::TinyconPlugin        ();

sub new {
    my $class = shift;
    my $session = shift || $Foswiki::Plugins::SESSION;

    my $this = $class->SUPER::new(
        $session,
        name          => 'tinycon',
        version       => $Foswiki::Plugins::TinyconPlugin::RELEASE,
        author        => 'Copyright (c) 2012 Tom Moor',
        homepage      => 'http://tinycon.org',
        puburl        => '%PUBURLPATH%/%SYSTEMWEB%/TinyconPlugin',
        documentation => "$Foswiki::cfg{SystemWebName}.TinyconPlugin",
        summary       => $Foswiki::Plugins::TinyconPlugin::SHORTDESCRIPTION,
        dependencies  => [],
        javascript    => ["tinycon.min.js"],

        #        css           => ["hallo.css"]
    );

    return $this;
}

sub renderCSS {
    my ( $this, $text ) = @_;

    $text =~ s/\.min// if $this->{debug};
    $text .= '?version=' . $this->{version};
    $text =
"<link rel='stylesheet' href='$this->{puburl}/$text' type='text/css' media='all' />\n";

    return $text;
}

sub renderJS {
    my ( $this, $text ) = @_;

    $text =~ s/\.min// if ( $this->{debug} );

    $text .= '?version=' . $this->{version} if ( $this->{version} =~ '$Rev$' );
    $text =
      "<script type='text/javascript' src='$this->{puburl}/$text'></script>\n";
    return $text;
}

1;
