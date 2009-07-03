# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
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
package Foswiki::Plugins::JQueryPlugin;
use strict;

=begin TML

---+ package Foswiki::Plugins::JQueryPlugin

Container for jQuery and plugins

=cut

use Foswiki::Plugins::JQueryPlugin::Plugins ();

use vars qw( 
  $VERSION $RELEASE $SHORTDESCRIPTION 
  $NO_PREFS_IN_TOPIC
);


$VERSION = '$Rev: 3740 $';
$RELEASE = '2.02'; 
$SHORTDESCRIPTION = 'jQuery <nop>JavaScript library for Foswiki';
$NO_PREFS_IN_TOPIC = 1;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean

=cut

sub initPlugin {
  my( $topic, $web, $user ) = @_;

  # jquery.foswiki 
  Foswiki::Func::registerTagHandler('JQTHEME', \&handleJQueryTheme );
  Foswiki::Func::registerTagHandler('JQREQUIRE', \&handleJQueryRequire );
  Foswiki::Func::registerTagHandler('JQICON', \&handleJQueryIcon );
  Foswiki::Func::registerTagHandler('JQICONPATH', \&handleJQueryIconPath );
  Foswiki::Func::registerTagHandler('JQPLUGINS', \&handleJQueryPlugins );

  # jquery.tabpane
  Foswiki::Func::registerTagHandler('TABPANE', \&handleTabPane );
  Foswiki::Func::registerTagHandler('ENDTABPANE', \&handleEndTabPane );
  Foswiki::Func::registerTagHandler('TAB', \&handleTab );
  Foswiki::Func::registerTagHandler('ENDTAB', \&handleEndTab );

  # jquery.button
  Foswiki::Func::registerTagHandler('BUTTON', \&handleButton );
  Foswiki::Func::registerTagHandler('CLEAR', \&handleClear );

  # jquery.toggle
  Foswiki::Func::registerTagHandler('TOGGLE', \&handleToggle );

  # DEPRECATED
  Foswiki::Func::registerTagHandler('JQSCRIPT', \&handleJQueryScript ); 
  Foswiki::Func::registerTagHandler('JQSTYLE', \&handleJQueryStyle ); 

  # nukem
  Foswiki::Plugins::JQueryPlugin::Plugins::init();

  return 1;
}

=begin TML

finish up the plugins container

SMELL: I'd prefer a proper finishHandler, alas it does not exist

=cut

sub modifyHeaderHandler {
  Foswiki::Plugins::JQueryPlugin::Plugins::finish();
}

=begin TML

---++ createPlugin($pluginName, ...) -> $plugin

API to create a jQuery plugin. Instantiating it adds all required javascript
and css files to the html page header.

=cut

sub createPlugin {
  return Foswiki::Plugins::JQueryPlugin::Plugins::createPlugin(@_);
}

=begin TML

---++ registerPlugin($pluginName, $class) -> $plugin

API to register a jQuery plugin. this is of use for other Foswiki plugins
to register their javascript modules as a jQuery plugin. Registering a plugin 'foobar'
will make it available via =%<nop>JQREQUIRE{"foobar"}%=.

Class will default to 'Foswiki::Plugins::JQueryPlugin::FOOBAR,

The FOOBAR.pm stub must be derived from Foswiki::Plugins::JQueryPlugin::PLUGIN class.

=cut

sub registerPlugin {
  return Foswiki::Plugins::JQueryPlugin::Plugins::registerPlugin(@_);
}

=begin TML

---++ handleButton($session, $params, $topic, $web) -> $result

Handles the =%<nop>BUTTON% tag. 

=cut

sub handleButton {
  my $session = shift;
  my $plugin = createPlugin('Button', $session);
  return $plugin->handleButton(@_) if $plugin;
  return '';
}

=begin TML

---++ handleToggle($session, $params, $topic, $web) -> $result

Handles the =%<nop>TOGGLE% tag. 

=cut

sub handleToggle {
  my $session = shift;
  my $plugin = createPlugin('Toggle', $session);
  return $plugin->handleToggle(@_) if $plugin;
  return '';
}

=begin TML

---++ handleTabPane($session, $params, $topic, $web) -> $result

Handles the =%<nop>TABPANE% tag. 

=cut

sub handleTabPane {
  my $session = shift;
  my $plugin = createPlugin('Tabpane', $session);
  return $plugin->handleTabPane(@_) if $plugin;
  return '';
}

=begin TML

---++ handleTab($session, $params, $topic, $web) -> $result

Handles the =%<nop>TAB% tag. 

=cut

sub handleTab {
  my $session = shift;
  my $plugin = createPlugin('Tabpane', $session);
  return $plugin->handleTab(@_) if $plugin;
  return '';
}

=begin TML

---++ handleEndTab($session, $params, $topic, $web) -> $result

Handles the =%<nop>ENDTAB% tag. 

=cut

sub handleEndTab {
  my $session = shift;
  my $plugin = createPlugin('Tabpane', $session);
  return $plugin->handleEndTab(@_) if $plugin;
  return '';
}

=begin TML

---++ handleEndTabPane($session, $params, $topic, $web) -> $result

Handles the =%<nop>ENDTABPANE% tag. 

=cut

sub handleEndTabPane {
  my $session = shift;
  my $plugin = createPlugin('Tabpane', $session);
  return $plugin->handleEndTabPane(@_) if $plugin;
  return '';
}

=begin TML

---++ handleClear($session, $params, $topic, $web) -> $result

Handles the =%<nop>CLEAR% tag. 

TODO: move this to another plugin; check against Foswiki:Extensions/ImagePlugin's 
way to clear using =%<nop>IMAGE{"clear"}%=.

=cut

sub handleClear {
  return "<span class='foswikiClear'></span>";
}

=begin TML

---++ handleJQueryRequire($session, $params, $topic, $web) -> $result

Handles the =%<nop>JQREQUIRE% tag. 

=cut

sub handleJQueryRequire {
  my ($session, $params, $theTopic, $theWeb) = @_;   

  my $pluginName = $params->{_DEFAULT};
  my $warn = $params->{warn} || '';
  my $plugin = createPlugin($pluginName, $session);
  return "<span class='foswikiAlert'>Error: no such plugin $pluginName</span>"
    if !$plugin && $warn ne 'off' ;

  return '';
}

=begin TML

---++ handleJQueryTheme($session, $params, $topic, $web) -> $result

Handles the =%<nop>JQTHEME% tag. 

=cut

sub handleJQueryTheme {
  my ($session, $params, $theTopic, $theWeb) = @_;   

  my $themeName = $params->{_DEFAULT} || $Foswiki::cfg{JQueryPlugin}{JQueryTheme} || 'base';
  Foswiki::Plugins::JQueryPlugin::Plugins::createTheme($themeName);

  return '';
}

=begin TML

---++ handleJQueryIconPath($session, $params, $topic, $web) -> $result

Handles the =%<nop>JQICONPATH% tag. 

=cut

sub handleJQueryIconPath {
  my ($session, $params, $theTopic, $theWeb) = @_;   

  my $iconName = $params->{_DEFAULT} || '';
  return Foswiki::Plugins::JQueryPlugin::Plugins::getIconUrlPath($iconName);
}

=begin TML

---++ handleJQueryIcon($session, $params, $topic, $web) -> $result

Handles the =%<nop>JQICON% tag. 

=cut

sub handleJQueryIcon {
  my ($session, $params, $theTopic, $theWeb) = @_;   

  my $iconName = $params->{_DEFAULT} || '';
  my $iconAlt = $params->{alt} || $iconName;
  my $iconTitle = $params->{title} || '';
  my $iconPath = Foswiki::Plugins::JQueryPlugin::Plugins::getIconUrlPath($iconName);
  
  return '' unless $iconPath;

  my $iconClass = "foswikiIcon jqIcon";
  $iconClass .= " $params->{class}" if $params->{class};

  my $img = '<img src=\'$iconPath\' class=\'$iconClass\' $iconAlt$iconTitle/>';
  $img =~ s/\$iconPath/$iconPath/g;
  $img =~ s/\$iconClass/$iconClass/g;
  $img =~ s/\$iconAlt/alt='$iconAlt' /g if $iconAlt;
  $img =~ s/\$iconTitle/title='$iconTitle' /g if $iconTitle;

  return $img;
}

=begin TML

---++ handleJQueryPlugins($session, $params, $topic, $web) -> $result

Handles the =%<nop>JQPLUGINS% tag. 

=cut

sub handleJQueryPlugins {
  my ($session, $params, $theTopic, $theWeb) = @_;   

  my $theFormat = $params->{format};
  my $theHeader = $params->{header} || '';
  my $theFooter = $params->{footer} || '';
  my $theSeparator = $params->{separator};
  my $theTagFormat = $params->{tagformat};

  $theFormat= '   1 <a href="$homepage">$name</a> $active $version $author'
    unless defined $theFormat;
  $theSeparator = '$n' 
    unless defined $theSeparator;
  $theTagFormat = '[[%SYSTEMWEB%.Var$tag][$tag]]' 
    unless defined $theTagFormat;

  my @plugins = Foswiki::Plugins::JQueryPlugin::Plugins::getPlugins();

  my @result;
  my $counter = 0;
  foreach my $plugin (@plugins) {
    my $summary = $plugin->{summary};
    $summary =~ s/^\s+//;
    $summary =~ s/\s+$//;
    my $tags = '';
    if ($theFormat =~ /\$tags/) {
      my @tags = ();
      foreach my $tag (sort split(/\s*,\s*/, $plugin->{tags})) {
        my $line = $theTagFormat;
        $line =~ s/\$tag/$tag/g;
        push @tags, $line if $line;
      }
      $tags = join(', ', @tags);
    }
    my $active = defined($plugin->{isInit})?'<span class="foswikiAlert">(active)</span>':'';
    my $line = 
      Foswiki::Plugins::JQueryPlugin::Plugins::expandVariables($theFormat,
        'index' => ($counter+1),
        name => $plugin->{name},
        version => $plugin->{version},
        summary => $summary,
        author => $plugin->{author},
        homepage => $plugin->{homepage},
        tags => $tags,
        active => $active,
      );
    next unless $line;
    push @result, $line;
    $counter++;
  }

  $theHeader = 
    Foswiki::Plugins::JQueryPlugin::Plugins::expandVariables($theHeader,
      counter => $counter,
    );
  $theFooter = 
    Foswiki::Plugins::JQueryPlugin::Plugins::expandVariables($theFooter,
      counter => $counter,
    );
  $theSeparator = 
    Foswiki::Plugins::JQueryPlugin::Plugins::expandVariables($theSeparator);
  return $theHeader.join($theSeparator, @result).$theFooter;
}

###############################################################################
# deprecated handlers

sub handleJQueryScript {
  my ($session, $params, $theTopic, $theWeb) = @_;   

  Foswiki::Func::writeWarning("WARNING: deprecated use of JQSCRIPT in $theWeb.$theTopic");

  my $scriptFileName = $params->{_DEFAULT};
  return '' unless $scriptFileName;
  $scriptFileName .= '.js' unless $scriptFileName =~ /\.js$/;
  return "<script type=\"text/javascript\" src=\"%PUBURLPATH%/%SYSTEMWEB%/JQueryPlugin/$scriptFileName\"></script>";
}

sub handleJQueryStyle {
  my ($session, $params, $theTopic, $theWeb) = @_;   

  Foswiki::Func::writeWarning("WARNING: deprecated use of JQSTYLE in $theWeb.$theTopic");

  my $styleFileName = $params->{_DEFAULT};
  return '' unless $styleFileName;
  $styleFileName .= '.css' unless $styleFileName =~ /\.css$/;
  return "<style type='text/css'>\@import url('%PUBURLPATH%/%SYSTEMWEB%/JQueryPlugin/$styleFileName');</style>";
}

1;
