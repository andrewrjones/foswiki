# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/ympzZnp0Uq/australasia.  Olson data version 2012c
#
# Do not edit this file directly.
#
package DateTime::TimeZone::Pacific::Kwajalein;
{
  $DateTime::TimeZone::Pacific::Kwajalein::VERSION = '1.46';
}

use strict;

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::Pacific::Kwajalein::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY,
59958190240,
DateTime::TimeZone::NEG_INFINITY,
59958230400,
40160,
0,
'LMT'
    ],
    [
59958190240,
62127694800,
59958229840,
62127734400,
39600,
0,
'MHT'
    ],
    [
62127694800,
62881531200,
62127651600,
62881488000,
-43200,
0,
'KWAT'
    ],
    [
62881531200,
DateTime::TimeZone::INFINITY,
62881574400,
DateTime::TimeZone::INFINITY,
43200,
0,
'MHT'
    ],
];

sub olson_version { '2012c' }

sub has_dst_changes { 0 }

sub _max_year { 2022 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

