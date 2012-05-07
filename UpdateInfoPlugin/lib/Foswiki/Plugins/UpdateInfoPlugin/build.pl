#!/usr/bin/perl -w
#
# Build for UpdateInfoPlugin
#
BEGIN {
    foreach my $pc ( split( /:/, $ENV{FOSWIKI_LIBS} ) ) {
        unshift @INC, $pc;
    }
}

use Foswiki::Contrib::Build;

# Create the build object
$build = new Foswiki::Contrib::Build('UpdateInfoPlugin');

# Build the target on the command line, or the default target
$build->build( $build->{target} );

