# See bottom of file for default license and copyright information

=begin TML

---+ package Foswiki::Plugins::TinyconPlugin

Foswiki plugins 'listen' to events happening in the core by registering an
interest in those events. They do this by declaring 'plugin handlers'. These
are simply functions with a particular name that, if they exist in your
plugin, will be called by the core.

This is an empty Foswiki plugin. It is a fully defined plugin, but is
disabled by default in a Foswiki installation. Use it as a template
for your own plugins.

To interact with Foswiki use ONLY the official APIs
documented in %SYSTEMWEB%.DevelopingPlugins. <strong>Do not reference any
packages, functions or variables elsewhere in Foswiki</strong>, as these are
subject to change without prior warning, and your plugin may suddenly stop
working.

Error messages can be output using the =Foswiki::Func= =writeWarning= and
=writeDebug= functions. These logs can be found in the Foswiki/working/logs
directory.  You can also =print STDERR=; the output will appear in the
webserver error log.  The {WarningsAreErrors} configure setting makes
Foswiki less tolerant of errors, and it is recommended to set it during
development.  It can be set using configure, in the 'Miscellaneous'
section.  Most handlers can also throw exceptions (e.g.
[[%SCRIPTURL{view}%/%SYSTEMWEB%/PerlDoc?module=Foswiki::OopsException][Foswiki::OopsException]])

For increased performance, all handler functions except =initPlugin= are
commented out below. *To enable a handler* remove the leading =#= from
each line of the function. For efficiency and clarity, you should
only uncomment handlers you actually use.

__NOTE:__ When developing a plugin it is important to remember that
Foswiki is tolerant of plugins that do not compile. In this case,
the failure will be silent but the plugin will not be available.
See %SYSTEMWEB%.InstalledPlugins for error messages.

__NOTE:__ Foswiki:Development.StepByStepRenderingOrder helps you decide which
rendering handler to use. When writing handlers, keep in mind that these may
be invoked on included topics. For example, if a plugin generates links to the
current topic, these need to be generated before the =afterCommonTagsHandler=
is run. After that point in the rendering loop we have lost the information
that the text had been included from another topic.

__NOTE:__ Not all handlers (and not all parameters passed to handlers) are
available with all versions of Foswiki. Where a handler has been added
the POD comment will indicate this with a "Since" line
e.g. *Since:* Foswiki::Plugins::VERSION 1.1

Deprecated handlers are still available, and can continue to be used to
maintain compatibility with earlier releases, but will be removed at some
point in the future. If you do implement deprecated handlers, then you can
do no harm by simply keeping them in your code, but you are recommended to
implement the alternative as soon as possible.

See http://foswiki.org/Download/ReleaseDates for a breakdown of release
versions.

=cut

package Foswiki::Plugins::TinyconPlugin;

# Always use strict to enforce variable scoping
use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version

# $VERSION is referred to by Foswiki, and is the only global variable that
# *must* exist in this package. This should always be in the format
# $Rev$ so that Foswiki can determine the checked-in status of the
# extension.
our $VERSION = '$Rev$';

# $RELEASE is used in the "Find More Extensions" automation in configure.
# It is a manually maintained string used to identify functionality steps.
# You can use any of the following formats:
# tuple   - a sequence of integers separated by . e.g. 1.2.3. The numbers
#           usually refer to major.minor.patch release or similar. You can
#           use as many numbers as you like e.g. '1' or '1.2.3.4.5'.
# isodate - a date in ISO8601 format e.g. 2009-08-07
# date    - a date in 1 Jun 2009 format. Three letter English month names only.
# Note: it's important that this string is exactly the same in the extension
# topic - if you use %$RELEASE% with BuildContrib this is done automatically.
our $RELEASE = '1.1.2';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION = 'Dynamic favicons';

# You must set $NO_PREFS_IN_TOPIC to 0 if you want your plugin to use
# preferences set in the plugin topic. This is required for compatibility
# with older plugins, but imposes a significant performance penalty, and
# is not recommended. Instead, leave $NO_PREFS_IN_TOPIC at 1 and use
# =$Foswiki::cfg= entries, or if you want the users
# to be able to change settings, then use standard Foswiki preferences that
# can be defined in your %USERSWEB%.SitePreferences and overridden at the web
# and topic level.
#
# %SYSTEMWEB%.DevelopingPlugins has details of how to define =$Foswiki::cfg=
# entries so they can be used with =configure=.
our $NO_PREFS_IN_TOPIC = 1;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin topic is in
     (usually the same as =$Foswiki::cfg{SystemWebName}=)

*REQUIRED*

Called to initialise the plugin. If everything is OK, should return
a non-zero value. On non-fatal failure, should write a message
using =Foswiki::Func::writeWarning= and return 0. In this case
%<nop>FAILEDPLUGINS% will indicate which plugins failed.

In the case of a catastrophic failure that will prevent the whole
installation from working safely, this handler may use 'die', which
will be trapped and reported in the browser.

__Note:__ Please align macro names with the Plugin name, e.g. if
your Plugin is called !FooBarPlugin, name macros FOOBAR and/or
FOOBARSOMETHING. This avoids namespace issues.

=cut

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    # Example code of how to get a preference value, register a macro
    # handler and register a RESTHandler (remove code you do not need)

    # Set your per-installation plugin configuration in LocalSite.cfg,
    # like this:
    # $Foswiki::cfg{Plugins}{TinyconPlugin}{ExampleSetting} = 1;
    # See %SYSTEMWEB%.DevelopingPlugins#ConfigSpec for information
    # on integrating your plugin configuration with =configure=.

    # Always provide a default in case the setting is not defined in
    # LocalSite.cfg.
    # my $setting = $Foswiki::cfg{Plugins}{TinyconPlugin}{ExampleSetting} || 0;

    # Register the _EXAMPLETAG function to handle %EXAMPLETAG{...}%
    # This will be called whenever %EXAMPLETAG% or %EXAMPLETAG{...}% is
    # seen in the topic text.
    Foswiki::Func::registerTagHandler( 'TINYCON', \&TINYCON );

    # Allow a sub to be called from the REST interface
    # using the provided alias
    #Foswiki::Func::registerRESTHandler( 'example', \&restExample );

    # Plugin correctly initialized
    return 1;
}

sub TINYCON {
    my ( $this, $params, $topic, $web, $topicObject ) = @_;

#its a shame that Func::addToZone is less useful - as you have to call JQREQUIRE anyway :()

    my $text = <<"THERE";
%JQREQUIRE{"TINYCON"}%
%ADDTOZONE{
  "script"
  requires="JQUERYPLUGIN::TINYCON"
  text="<script>
Tinycon.setOptions({
	width: 7,
	height: 9,
	font: '10px arial',
	colour: '#ffffff',
	background: 'lightred',
	fallback: true
});
Tinycon.setBubble($params->{_DEFAULT});
</script>"
  }%
THERE

    return $text;
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Author: SvenDowideit@fosiki.com

Copyright (C) 2012 Sven Dowideit

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 3
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
