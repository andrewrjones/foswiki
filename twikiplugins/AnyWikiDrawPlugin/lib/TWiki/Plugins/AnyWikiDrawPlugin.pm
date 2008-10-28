# Plugin for TWiki Enterprise Collaboration Platform, http://TWiki.org/
#
# Copyright (C) 2000-2001 Andrea Sterbini, a.sterbini@flashnet.it
# Copyright (C) 2001-2006 Peter Thoeny, Peter@Thoeny.org
# Copyright (C) 2002-2006 Crawford Currie, cc@c-dot.co.uk
# Copyright (C) 2007 Werner Randelshofer, werner.randelshofer@bluewin.ch
#
# For licensing info read LICENSE file in the TWiki root.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
#
# As per the GPL, removal of this notice is prohibited.

package TWiki::Plugins::AnyWikiDrawPlugin;

use vars qw(
        $web $topic $user $installWeb $VERSION $RELEASE $editButton
    );
use CGI qw(:standard);
use File::Basename;

# This should always be $Rev: 0001 $ so that TWiki can determine the checked-in
# status of the plugin. It is used by the build automation tools, so
# you should leave it alone.
$VERSION = '$Rev: 0001 $';

# This is a free-form string you can use to "name" your own plugin version.
# It is *not* used by the build automation tools, but is reported as part
# of the version number in PLUGINDESCRIPTIONS.
$RELEASE = 'First Prototype';

my $editmess;

sub initPlugin {
  ( $topic, $web, $user, $installWeb ) = @_;

  # check for Plugins.pm versions
  if( $TWiki::Plugins::VERSION < 1 ) {
	TWiki::Func::writeWarning( "Version mismatch between AnyWikiDrawPlugin and Plugins.pm" );
	return 0;
  }

  # Get plugin debug flag
  #$editButton = TWiki::Func::getPreferencesValue( "ANYWIKIDRAWPLUGIN_EDIT_BUTTON" ); 
  $editButton = 1; 
  $editmess = TWiki::Func::getPreferencesValue( "ANYWIKIDRAWPLUGIN_EDIT_TEXT" ) ||
    "Edit %F%";
  $editmess =~ s/['"]/`/g;

  return 1;
}

sub handleDrawing {
  my( $attributes, $width, $height, $topic, $web ) = @_;
  my $nameVal = TWiki::Func::extractNameValuePair( $attributes );
  if( ! $nameVal ) {
	$nameVal = "untitled";
  }
  $nameVal =~ s/[^A-Za-z0-9_\.\-]//go; # delete special characters

  $cgi = new CGI;
  
	if ($nameVal !~ /\./ || $nameVal =~/\.draw/) {
		return handleDrawDrawing($attributes, $topic, $web);
	} else {
		if ($cgi->param('editDrawing') eq $nameVal) {
			return editAnyDrawing($attributes, $width, $height, $topic, $web);
		} else {
			return handleAnyDrawing($attributes, $width, $height, $topic, $web);
		}
	}
}

#
# Handle Drawing tag for the .draw file format
#
sub handleDrawDrawing {
  my( $attributes, $topic, $web ) = @_;
  my $nameVal = TWiki::Func::extractNameValuePair( $attributes );
  if( ! $nameVal ) {
	$nameVal = "untitled";
  }
  $nameVal =~ s/[^A-Za-z0-9_\.\-]//go; # delete special characters
	if ($nameVal =~/\.draw$/) {
		$nameVal = substr($nameVal, 0, length($nameVal) - 5);
	}
  
  # should really use TWiki server-side include mechanism....
  my $mapFile = TWiki::Func::getPubDir() . "/$web/$topic/$nameVal.map";
  my $img = "src=\"%ATTACHURLPATH%/$nameVal.gif\"";
  my $editUrl =
	TWiki::Func::getOopsUrl($web, $topic, "anywikidraw", $nameVal);
  my $imgText = "";
  my $edittext = $editmess;
  $edittext =~ s/%F%/$nameVal/g;
  my $hover =
    "onmouseover=\"window.status='$edittext';return true;\" ".
      "onmouseout=\"window.status='';return true;\"";

    my $artworkURLPath = "%PUBURLPATH%/%SYSTEMWEB%/AnyWikiDrawPlugin";

  if ( -e $mapFile ) {
	my $mapname = $nameVal;
	$mapname =~ s/^.*\/([^\/]+)$/$1/;
	$img .= " usemap=\"#$mapname\"";
	my $map = TWiki::Func::readFile($mapFile);
    # Unashamed hack to handle Web.TopicName links
    $map =~ s/href=\"((\w+)\.)?(\w+)(#\w+)?\"/&_processHref($2,$3,$4,$web)/ge;
	$map = TWiki::Func::expandCommonVariables( $map, $topic );
	$map =~ s/%MAPNAME%/$mapname/g;
	$map =~ s/%ANYWIKIDRAW%/$editUrl/g;
	$map =~ s/%EDITTEXT%/$edittext/g;
	$map =~ s/%HOVER%/$hover/g;
	$map =~ s/[\r\n]+//g;

	# Add an edit link just above the image if required
	$imgText .= "<img $img>$map";
	if ( $editButton == 1 ) {
		$imgText .= "<a href=\"$editUrl\" $hover>".
            "<img src=\"".$artworkURLPath."/edit.gif\" title=\"".$edittext."\"/>".
            "</a>";
    }
  } else {
	# insensitive drawing; the whole image gets a rather more
	# decorative version of the edit URL
	$imgText .= "<a href=\"$editUrl\" $hover>".
          "<img $img $hover alt=\"$edittext\" title=\"$edittext\" /></a>";
	if ( $editButton == 1 ) {
		$imgText .= "<a href=\"$editUrl\" $hover>".
            "<img src=\"".$artworkURLPath."/edit.gif\" title=\"".$edittext."\"/>".
            "</a>";
    }
  }

  return $imgText;
}

#
# Handle Drawing tag for all formats except the .draw file format
#
sub handleAnyDrawing {
  my( $attributes, $width, $height, $topic, $web ) = @_;
  my $nameVal = TWiki::Func::extractNameValuePair( $attributes );
  if( ! $nameVal ) {
	$nameVal = "untitled.svg";
  }
  $nameVal =~ s/[^A-Za-z0-9_\.\-]//go; # delete special characters
  
  # should really use TWiki server-side include mechanism....
  my $mapFile = TWiki::Func::getPubDir() . "/$web/$topic/$nameVal.map";
  my $img = '';
  if($nameVal =~ /\.svg$/) {
  	$img = "src=\"%ATTACHURLPATH%/$nameVal.png\"";
  } else {
  	$img = "src=\"%ATTACHURLPATH%/$nameVal\"";
  }
  my $editUrl = $ENV["REQUEST_URI"]."?editDrawing=$nameVal";
  my $imgText = "";
  my $edittext = $editmess;
  $edittext =~ s/%F%/$nameVal/g;
  my $hover =
    "onmouseover=\"window.status='$edittext';return true;\" ".
      "onmouseout=\"window.status='';return true;\"";

    my $artworkURLPath = "%PUBURLPATH%/%SYSTEMWEB%/AnyWikiDrawPlugin";

  if ( -e $mapFile ) {
	my $mapname = $nameVal;
	$mapname =~ s/^.*\/([^\/]+)$/$1/;
	$img .= " usemap=\"#$mapname\"";
	my $map = TWiki::Func::readFile($mapFile);
    # Unashamed hack to handle Web.TopicName links
    $map =~ s/href=\"((\w+)\.)?(\w+)(#\w+)?\"/&_processHref($2,$3,$4,$web)/ge;
	$map = TWiki::Func::expandCommonVariables( $map, $topic );
	$map =~ s/%MAPNAME%/$mapname/g;
	$map =~ s/%ANYWIKIDRAW%/$editUrl/g;
	$map =~ s/%EDITTEXT%/$edittext/g;
	$map =~ s/%HOVER%/$hover/g;
	$map =~ s/[\r\n]+//g;

	# Add an edit link to the right of the image if required
	if ($editButton eq 1) {
		$imgText .= "$map<img $img>";
		$imgText .= "<a href=\"$editUrl\" $hover>".
            "<img src=\"".$artworkURLPath."/edit.gif\" title=\"".$edittext."\"/>".
            "</a>";
	} else {
		$imgText .= "<a href=\"$editUrl\" $hover>".
			"<img $img $hover alt=\"$edittext\" title=\"$edittext\" />$map</a>";
	}
  } else {
	# insensitive drawing; the whole image gets a rather more
	# decorative version of the edit URL
	if ($editButton eq 1) {
		$imgText .= "<img $img>";
		$imgText .= "<a href=\"$editUrl\" $hover>".
            "<img src=\"".$artworkURLPath."/edit.gif\" title=\"".$edittext."\"/>".
            "</a>";
	} else {
		$imgText .= "<a href=\"$editUrl\" $hover>".
			"<img $img $hover alt=\"$edittext\" title=\"$edittext\" /></a>";
	}
  }
  return $imgText;
}

sub editAnyDrawing {
	my( $attributes, $width, $height, $topic, $web ) = @_;
  
	my $nameVal = TWiki::Func::extractNameValuePair( $attributes );
	if( ! $nameVal ) {
		$nameVal = "untitled.svg";
	}
	$nameVal =~ s/[^A-Za-z0-9_\.\-]//go; # delete special characters
  
	my $drawingFile = TWiki::Func::getPubDir() . "/$web/$topic/$nameVal";
	my $downloadURL = "%ATTACHURLPATH%/$nameVal";
	my $scriptURLPath = "%SCRIPTURLPATH%/pack200%SCRIPTSUFFIX%";
	
	my $output = '<a name="appletdrawing"></a>'.
			'<div style="z-index: 101;">'.
			'<applet codebase="/" '.
			' archive="'.$scriptURLPath."/pub/TWiki/AnyWikiDrawPlugin/AnyWikiDrawForTWiki.jar\"". 
			' code="org.anywikidraw.twiki.TWikiDrawingApplet.class"'.
			' width="'.(($width + 4 < 400) ? 400 : $width+4).'" height="'.(($height + 130 < 200) ? 200 : $height+130).'">'.
				'<param name="DrawingName" value="'.$nameVal.'">'.
				'<param name="DrawingWidth" value="'.$width.'">'.
				'<param name="DrawingHeight" value="'.$height.'">'.
				((-e $drawingFile) ? '<param name="DrawingURL" value="'.$downloadURL.'">' : '').
				'<param name="PageURL" value="'."%SCRIPTURLPATH%/view%SCRIPTSUFFIX%/%WEB%/%TOPIC%".'">'.
				'<param name="UploadURL" value="'."%SCRIPTURLPATH%/upload%SCRIPTSUFFIX%/%WEB%/%TOPIC%".'">'.
			'</applet>'.
			'</div>';
	return $output;
}

sub _processHref {
    my ( $web, $topic, $anchor, $defweb ) = @_;

    $web = $defweb unless ( $web );
    $anchor = "" unless $anchor;

    return "href=\"%SCRIPTURLPATH%/view%SCRIPTSUFFIX%/$web/$topic$anchor\"";
}

sub commonTagsHandler
{
  ### my ( $text, $topic, $web ) = @_;   # do not uncomment, use $_[0], $_[1]... instead
  $_[0] =~ s/%DRAWING{(.*?)(?:\|(.*?))?(?:\|(.*?))?}%/&handleDrawing($1, $2, $3, $_[1], $_[2])/geo;
  $_[0] =~ s/%DRAWING%/&handleDrawing("untitled", 300, 400, $_[1], $_[2])/geo;
}

1;
