# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2000-2003 Andrea Sterbini, a.sterbini@flashnet.it
# Copyright (C) 2001-2003 Peter Thoeny, peter@thoeny.com
# Copyright (C) 2003      Nathan Ollerenshaw, chrome@stupendous.net
# Copyright (C) 2006-2009 Sven Dowideit, SvenDowideit@WikiRing.com
# Copyright (C) 2010      Bryan Thale, bryan.thale@motorola.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

=begin TML

---+ package LocalTimePlugin

Implements the %<nop>LOCALTIME% macro to display a formatted date and time 
possibly adjusted for a given time zone.

Plugin Version: $Rev$

=cut

package Foswiki::Plugins::LocalTimePlugin;

use strict;

require Foswiki::Func;
require Foswiki::Plugins;

# $VERSION is referenced by Foswiki and is the only global variable that
# *must* exist in this package.  This should always be '$Rev$'
# so that Foswiki can determine the checked-in status of the plugin.  It is
# used by the build automation tools, so you should leave it alone.
our $VERSION = '$Rev$';

# $RELEASE is a free-form string used to identify "releases" of a plugin
# independent of the build system.  It is *not* used by the build automation
# tools, but *is* reported as part of the version number by %PLUGINDESCRIPTIONS%.
#
# LocalTimePlugin uses a major.minor.patch numbering scheme for releases.
# 'major' releases indicate a break in compatibility with previous versions
# such as the removal of deprecated features.  'minor' releases indicate
# backward-compatible changes to or new additions of functionality.  'patch'
# releases indicate bug fixes or other internal implementation changes that
# aren't visible to users of the package.
our $RELEASE = '1.1';

# One line description of this plugin reported by %PLUGINDESCRIPTIONS%
our $SHORTDESCRIPTION =
  'Provides the %<nop>LOCALTIME% macro to display a formatted date and/or time';

# LocalTimePlugin uses the normal Foswiki preferences mechanism for settings
our $NO_PREFS_IN_TOPIC = 1;

=begin TML

---++ initPlugin( $topic, $web, $user, $installWeb ) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin topic is in

Initializes and installs the handler routine for the %<nop>LOCALTIME% macro.

Returns: 1 on success, 0 on failure

=cut

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    my $min_api_version = 1.0;
    if ( $Foswiki::Plugins::VERSION < $min_api_version ) {

        # Oops! We are not compatible with this version of the Plugin API
        Foswiki::Func::writeWarning( "Version $RELEASE of "
              . __PACKAGE__
              . " requires at least version $min_api_version of the Foswiki "
              . "Plugin API.  Current version is $Foswiki::Plugins::VERSION" );
        return 0;
    }

    _debugEntryPoint( "$web.$topic", 'initPlugin',
        { user => $user, installWeb => $installWeb } );

    # Install our macro handler for %LOCALTIME%
    Foswiki::Func::registerTagHandler( 'LOCALTIME', \&handleLocalTime );

    # Plugin correctly initialized
    _debug( "$web.$topic", "Plugin initialized" );
    return 1;
}

=begin TML

---++ handleLocalTime( $session, $params, $theTopic, $theWeb ) -> $string

Process the %<nop>LOCALTIME% macro and return the desired date/time as a 
formatted string.  Uses the Date::Handler Perl module.

   * =$session= - a reference to the Foswiki session object
   * =$params= - a reference to a Foswiki::Attrs object containing the macro parameters
      * =DEFAULT= - (optional) the desired timezone in which to render the date/time. Defaults to the LOCALTIMEPLUGIN_TIMEZONE preference setting or UTC.
      * =dateGMT= - (optional) the date/time to display, assumed to be in UTC unless the string contains a timezone identifier.  Defaults to the current date and time
      * =format= - (optional) the desired output format specifier string. Defaults to the LOCALTIMEPLUGIN_DATEFORMAT preference or to the Foswiki '$longdate' format
      * =fromtopic= - (optional) the web.topic from which to set the value of the TIMEZONE variable
   * =$theTopic= - the name of the topic being processed
   * =$theWeb= - the name of the web containing the topic being processed

Returns: the date and/or time as a formatted string or an error message upon failure

=cut

sub handleLocalTime {
    my ( $session, $params, $theTopic, $theWeb ) = @_;

    _debugEntryPoint( "$theWeb.$theTopic", 'handleLocalTime', $params );

    eval {
        require Date::Handler;
    };
    if ($@) {
        my $msg = "Error: Can't load required modules ($@)";
        _warning( "$theWeb.$theTopic", $msg );
        return "%RED%$msg%ENDCOLOR%";
    }

    my $tz               = $params->{_DEFAULT}
      || &Foswiki::Func::getPreferencesValue('LOCALTIMEPLUGIN_TIMEZONE')
      || 'Asia/Tokyo';
    my $formatString     = $params->{format};
    my $fromtopic        = $params->{fromtopic};
    my $specifieddateGMT = $params->{dateGMT};

    if ( defined($fromtopic) ) {

        #TODO: normalise topic
        my ( $web, $topic ) =
          $session->normalizeWebTopicName( $theWeb, $fromtopic );
        my $zone =
          $session->{prefs}
          ->getTopicPreferencesValue( 'TIMEZONE', $web, $topic );
        $tz = $zone if defined($zone);
    }

    my $date;
    if ( defined($specifieddateGMT) ) {
        $date = new Date::Handler(
            {
                date      => Foswiki::Time::parseTime($specifieddateGMT),
                time_zone => $tz
            }
        );
    }
    else {
        $date = new Date::Handler( { date => time, time_zone => $tz } );
    }

#swiped from Foswiki::Time::formatTime
#SMELL: should combine this code into Foswiki::Time, or abstract out and reuse..
    my $value = '';
    $formatString ||= '$wday, $day $month $year, $hour:$min:$sec ($tz)';

    #    my $outputTimeZone ||= $Foswiki::cfg{DisplayTimeValues};

    #standard foswiki date time formats
    if ( $formatString =~ /rcs/i ) {

        # RCS format, example: "2001/12/31 23:59:59"
        $formatString = '$year/$mo/$day $hour:$min:$sec';
    }
    elsif ( $formatString =~ /http|email/i ) {

        # HTTP header format, e.g. "Thu, 23 Jul 1998 07:21:56 EST"
        # - based on RFC 2616/1123 and HTTP::Date; also used
        # by Foswiki::Net for Date header in emails.
        $formatString = '$wday, $day $month $year $hour:$min:$sec $tz';
    }
    elsif ( $formatString =~ /iso/i ) {

        # ISO Format, see spec at http://www.w3.org/TR/NOTE-datetime
        # e.g. "2002-12-31T19:30:12Z"
        $formatString = '$year-$mo-$dayT$hour:$min:$sec';
    }

    my $wday = $date->WeekDay();

    $value = $formatString;
    $value =~ s/\$seco?n?d?s?/sprintf('%.2u',$date->Sec())/gei;
    $value =~ s/\$minu?t?e?s?/sprintf('%.2u',$date->Min())/gei;
    $value =~ s/\$hour?s?/sprintf('%.2u',$date->Hour())/gei;
    $value =~ s/\$day/sprintf('%.2u',$date->Day())/gei;
    $value =~ s/\$wday/$Foswiki::Time::WEEKDAY[$date->WeekDay()]/gi;
    $value =~ s/\$dow/$date->WeekDay()/gei;
    $value =~
s/\$week/Foswiki::Time::_weekNumber($date->Day(),$date->Month()-1,$date->Year(),$date->WeekDay())/egi;
    $value =~ s/\$mont?h?/$Foswiki::Time::ISOMONTH[$date->Month()-1]/gi;
    $value =~ s/\$mo/sprintf('%.2u',$date->Month())/gei;
    $value =~ s/\$year?/sprintf('%.4u',$date->Year())/gei;
    $value =~ s/\$ye/sprintf('%.2u',$date->Year()%100)/gei;
    $value =~ s/\$epoch/$date->Epoch()/gei;
    $value =~ s/\$tz/$date->TimeZone()/gei;

    return $value;
}

sub _weekNumber {
    my ( $day, $mon, $year, $wday ) = @_;

    # calculate the calendar week (ISO 8601)
    my $nextThursday =
      timegm( 0, 0, 0, $day, $mon, $year ) +
      ( 3 - ( $wday + 6 ) % 7 ) * 24 * 60 * 60;    # nearest thursday
    my $firstFourth = timegm( 0, 0, 0, 4, 0, $year );    # january, 4th
    return
      sprintf( '%.0f', ( $nextThursday - $firstFourth ) / ( 7 * 86400 ) ) + 1;
}

=begin TML

---++ _warning( $topic, $msg )

Log a warning and debug message. The topic is prepended to the message.

   * =$topic= - the web.topic being processed
   * =$msg= - the message text to write to the warning and debug logs

=cut

sub _warning {
    my ( $topic, $msg ) = @_;
    Foswiki::Func::writeWarning( $topic, $msg );
    _debug( $topic, $msg );
}

=begin TML

---++ _debugEntryPoint( $topic, $func, $args )

Write a function entry message to the debug log if debug logging is enabled.
The topic is prepended to the message.

   * =$topic= - the web.topic being processed
   * =$func= - the name of the function being logged
   * =$args= - a reference to a hash containing the arguments passed to $func

=cut

sub _debugEntryPoint {
    if ( Foswiki::Func::getPreferencesFlag('LOCALTIMEPLUGIN_DEBUG') ) {
        my ( $topic, $func, $args ) = @_;
        my $msg = '';
        foreach my $key ( sort keys %$args ) {
            $msg .= ", $key=>'$args->{$key}'";
        }
        $msg =~ s/^, //;
        _debug( $topic, "$func( $msg )" );
    }
}

=begin TML

---++ _debug( $topic, $msg )

Write the supplied message to the debug log if debug logging is enabled. The
Perl package name and topic are prepended to the message.

   * =$topic= - the web.topic being processed
   * =$msg= - the message text to write to the debug log

=cut

sub _debug {
    if ( Foswiki::Func::getPreferencesFlag('LOCALTIMEPLUGIN_DEBUG') ) {
        my ( $topic, $msg ) = @_;
        Foswiki::Func::writeDebug( __PACKAGE__, $topic, $msg );
    }
}

1;
