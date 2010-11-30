#!perl
#
# Install script for PhyloWidgetPlugin
#
# Copyright (C) 2004-2007 Foswiki Contributors. All Rights Reserved.
# Foswiki Contributors are listed in the AUTHORS file in the root of
# this distribution. NOTE: Please extend that file, not this notice.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version. For
# more details read LICENSE in the root of this distribution.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# As per the GPL, removal of this notice is prohibited.
#
# Author: Crawford Currie http://c-dot.co.uk
#
# NOTE TO THE DEVELOPER: THIS FILE IS GENERATED AUTOMATICALLY
# BY THE BUILD PROCESS DO NOT EDIT IT - IT WILL BE OVERWRITTEN
#
use strict;
use warnings;
require 5.008;

use File::Spec;
use Cwd;

=pod

---+ PhyloWidgetPlugin_installer
This is the installer script. The basic function of this script is to
locate an archive and unpack it.

It will also check the dependencies listed in DEPENDENCIES and assist
the user in installing any that are missing. The script also automatically
maintains the revision histories of any files that are being installed by the
package but already have ,v files on disc (indicating that they are
revision controlled).

The script also functions as an *uninstaller* by passing the parameter
=uninstall= on the command-line. Note that uninstallation does *not* revert
the history of any topic changed during the installation.

The script allows the definition of PREINSTALL and POSTINSTALL scripts.
These scripts can be used for example to modify the configuration during
installation, using the functions described below.

Refer to the documentation of =configure=

=cut

# This is all done in package Foswiki so that reading LocalSite.cfg and Foswiki.cfg
# will put the config vars into the right namespace.
package Foswiki;

# The root of package URLs
my $PACKAGES_URL = 'http://foswiki.org/pub/Extensions';

# Extract MANIFEST and DEPENDENCIES from the __DATA__
undef $/;
my @DATA = split( /<<<< (.*?) >>>>\s*\n/, <DATA> );
shift @DATA;    # remove empty first element

# Establish where we are
my @path = ( 'tools', 'extender.pl' );
my $wd = Cwd::cwd();
$wd =~ /^(.*)$/;    # untaint
unshift( @path, $1 ) if $1;
my $script = File::Spec->catfile(@path);

unless ( my $return = do $script ) {
    my $message = <<MESSAGE;
************************************************************
Could not load $script
MESSAGE
    if ($@) {
        $message .= "There was a compile error: $@\n";
    }
    elsif (defined $return) {
        $message .= "There was a file error: $!\n";
    }
    else {
        $message .= "An unspecified error occurred\n";
    }

    # Try again, using open. This cures some uncooperative platforms.
    if ( open( F, '<', $script ) ) {
        local $/;
        my $data = <F>;
        close(F);
        $data =~ /^(.*)$/s;    # untaint
        eval $1;
        if ($@) {
            $message .= "Error when trying to eval the file content: $@\n";
        }
        else {
            print STDERR
              "'do $script failed, but install was able to proceed: $message";
            undef $message;
        }
    }
    else {
        $message .= "Could not open file using open() either: $!\n";
    }
    die $message if $message;
}

sub preuninstall {

    # # No PREUNINSTALL script;
}

sub postuninstall {

    # # No POSTUNINSTALL script;
}

sub preinstall {

    # # No PREINSTALL script;
}

sub postinstall {

    # # No POSTINSTALL script;
}

Foswiki::Extender::install( $PACKAGES_URL, 'PhyloWidgetPlugin', 'PhyloWidgetPlugin', @DATA );

1;

# MANIFEST and DEPENDENCIES are done this way
# to make it easy to extract them from this script.

__DATA__
<<<< MANIFEST >>>>
data/System/PhyloWidgetPlugin.txt,0644,
data/System/PhyloNexusViewer.txt,0644,
data/System/PhyloWidgetExample.txt,0644,
data/System/PhyloWidgetViewHelper.txt,0644,
data/System/VarNEXUSTREES.txt,0644,
data/System/VarPHYLOWIDGET.txt,0644,
data/System/ViewTrees.txt,0644,
lib/Foswiki/Plugins/PhyloWidgetPlugin.pm,0644,
pub/System/PhyloWidgetExample/Tree.nex,0644,
pub/System/PhyloWidgetPlugin/bare.html,0644,
pub/System/PhyloWidgetPlugin/img/pw.ico,0644,
pub/System/PhyloWidgetPlugin/index.html,0644,
pub/System/PhyloWidgetPlugin/jquery.phylowidget.uncompressed.js,0644,
pub/System/PhyloWidgetPlugin/lib/core.jar,0644,
pub/System/PhyloWidgetPlugin/lib/freeloader.jar,0644,
pub/System/PhyloWidgetPlugin/lib/itext.jar,0644,
pub/System/PhyloWidgetPlugin/lib/loading.gif,0644,
pub/System/PhyloWidgetPlugin/lib/pdf.jar,0644,
pub/System/PhyloWidgetPlugin/lib/phylowidget.jar,0644,
pub/System/PhyloWidgetPlugin/minimal.txt,0644,
pub/System/PhyloWidgetPlugin/phylotest.html,0644,
pub/System/PhyloWidgetPlugin/scripts/phylopopup.js,0644,
pub/System/PhyloWidgetPlugin/scripts/phylowidget.js,0644,
pub/System/PhyloWidgetPlugin/style.css,0644,
pub/System/PhyloWidgetPlugin/test.html,0644,
pub/System/PhyloWidgetPlugin/zip/phylowidget_src.zip,0644,
pub/System/PhyloWidgetPlugin/zip/phylowidget_standalone.zip,0644,
templates/phylonhx.tmpl,0644,

<<<< DEPENDENCIES >>>>
Bio::NEXUS,>=0,1,cpan,Required
Foswiki::Plugins::DBCachePlugin,>=0,1,plugin,Optional, For examples

