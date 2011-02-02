# See bottom of file for copyright
package Foswiki::Plugins::EditRowPlugin::Save;

use strict;
use warnings;
use Assert;

use Foswiki;
use Foswiki::Func();

# REST handler for table row edit save with redirect on completion.
# The erp_noredirect URL parameter can be passed to prevent
# the redirection. If it is set, the request will respond with a 500
# status code with a human readable message. This allows the handler
# to be used by Javascript table editors.
sub process {
    my $query = Foswiki::Func::getCgiQuery();

    unless ($query) {
        print CGI::header( -status => 500 );
        return undef;
    }

    my $saveType = $query->param('editrowplugin_save') || '';
    my $active_topic = $query->param('erp_active_topic');
    $active_topic =~ /(.*)/;
    my ( $web, $topic ) = Foswiki::Func::normalizeWebTopicName( undef, $1 );

    my ( $meta, $text ) = Foswiki::Func::readTopic( $web, $topic );
    my ( $url, $mess );
    if (
        !Foswiki::Func::checkAccessPermission(
            'CHANGE', Foswiki::Func::getWikiName(),
            $text, $topic, $web, $meta
        )
      )
    {

        $url = Foswiki::Func::getScriptUrl(
            $web, $topic, 'oops',
            template => 'oopsaccessdenied',
            def      => 'topic_access',
            param1   => 'CHANGE',
            param2   => 'access not allowed to topic'
        );
        $mess = "ACCESS DENIED";
    }
    else {
        $text =~ s/\\\n//gs;
        my @ps   = $query->param();
        my $urps = {};
        foreach my $p (@ps) {
            my @vals = $query->param($p);

            # We interpreted multi-value parameters as comma-separated
            # lists. This is what checkboxes, select+multi etc. use.
            $urps->{$p} = join( ',', @vals );
        }
        require Foswiki::Plugins::EditRowPlugin::TableParser;
        ASSERT( !$@ ) if DEBUG;
        my $content =
          Foswiki::Plugins::EditRowPlugin::TableParser::parseTables( $text,
            $web, $topic, $meta, $urps );

        my $nlines       = '';
        my $table        = undef;
        my $active_table = 0;
        my $action;
        my $minor        = 0;          # If true, this is a quiet save
        my $no_save      = 0;          # if true, we are cancelling
        my $no_return = 0; # if true, we want to finish editing after the action
        my $macro = $Foswiki::cfg{Plugins}{EditRowPlugin}{Macro}
          || 'EDITTABLE';

	# Dispatch whichever button was pressed
	my $clicked = $query->param('erp_action') || '';
        if ( $clicked eq 'erp_save' ) {
            $action    = 'change';
            $no_return = 1;
        }
        elsif ( $clicked eq 'erp_quietSave' ) {
            $action    = 'change';
            $minor     = 1;
            $no_return = 1;
        }
        elsif ( $clicked eq 'erp_upRow' ) {
            $action = 'moveUp';
        }
        elsif ( $clicked eq 'erp_downRow' ) {
            $action = 'moveDown';
        }
        elsif ( $clicked eq 'erp_addRow' ) {
            $action = 'addRow';
        }
        elsif ( $clicked eq 'erp_deleteRow' ) {
            $action = 'deleteRow';
        }
        else {
	    $action = 'cancel';
            $no_save   = 1;
            $no_return = 1;
        }
        foreach my $line (@$content) {
            if (
                UNIVERSAL::isa(
                    $line, 'Foswiki::Plugins::EditRowPlugin::Table'
                )
              )
            {
                $table = $line;
                $active_table++;
                if (   $active_topic eq $urps->{erp_active_topic}
                    && $urps->{erp_active_table} eq "${macro}_$active_table" )
                {
                    $table->$action($urps);
                }
                $line = $table->stringify();
                $table->finish();
                $nlines .= $line;
            }
            else {
                $nlines .= "$line\n";
            }
        }
        unless ($no_save) {
            Foswiki::Func::saveTopic( $web, $topic, $meta, $nlines,
                { minor => $minor } );
        }

        # Use a row anchor within range of the row being edited as
        # the goto target
        my $anchor = 'erp_' . $urps->{erp_active_table};
        if ( $urps->{erp_active_row} > 5 ) {
            my $before = $urps->{erp_active_row} - 1;
            $anchor .= '_' . $before;
        }
        else {
            $anchor .= '_1';
        }
        my @p = ( '#' => $anchor );
        unless ($no_return) {
            push( @p, erp_active_topic => $urps->{erp_active_topic} );
            push( @p, erp_active_table => $urps->{erp_active_table} );
            push( @p, erp_active_row   => $urps->{erp_active_row} );
        }
        $url = Foswiki::Func::getScriptUrl( $web, $topic, 'view', @p );
    }

    unless ( $query->param('erp_noredirect') ) {
        Foswiki::Func::redirectCgiQuery( undef, $url );
    }
    elsif ($mess) {
        print CGI::header( -status => "500 $mess" );
    }
    else {
        print CGI::header( -status => 200 );
    }

    return undef;    # Suppress standard redirection mechanism
}

1;
__END__
Author: Crawford Currie http://c-dot.co.uk

Copyright (c) 2008-2011 Foswiki Contributors
Copyright (c) 2007 WindRiver Inc. and TWiki Contributors.
All Rights Reserved. Foswiki Contributors are listed in the
AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Do not remove this copyright notice.

This plugin supports editing of a table row-by-row.

It uses a fairly generic table object, and employs a REST handler
for saving.
