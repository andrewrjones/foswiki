# See bottom of file for license and copyright information
package Foswiki::Plugins::HolidaylistPlugin;    

use strict;
use warnings;

# See plugin topic for complete release history
our $VERSION = '$Rev: 18212 $';
our $RELEASE = '1.032';
our $SHORTDESCRIPTION = 'Create a table with a list of people on holidays';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    # my ( $topic, $web, $user, $installWeb ) = @_;
    Foswiki::Func::registerTagHandler( 'HOLIDAYLIST', \&_HOLIDAYLIST );
    return 1;
}

sub _HOLIDAYLIST {
    # my($session, $params, $topic, $web) = @_;
    require Foswiki::Plugins::HolidaylistPlugin::Core;
#    *_HOLIDAYLIST = \&Foswiki::Plugins::HolidaylistPlugin::Core::HOLIDAYLIST;
    return Foswiki::Plugins::HolidaylistPlugin::Core::HOLIDAYLIST(@_);
}

1;
__END__

Copyright (C) 2000-2003 Andrea Sterbini, a.sterbini@flashnet.it
Copyright (C) 2001-2004 Peter Thoeny, peter@thoeny.com
Copyright (C) 2005-2009 Daniel Rohde
Copyright (C) 2008-2010 Foswiki Contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details, published at 
http://www.gnu.org/copyleft/gpl.html