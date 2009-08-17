# This script Copyright (c) 2009 Oliver Krueger, (wiki-one.net)
# and distributed under the GPL (see below)
#
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
# Author(s): Oliver Krueger

package Foswiki::Plugins::TagsPlugin::Untag;

use strict;
use warnings;
use Error qw(:try);

=begin TML

---++ rest( $session )
This is the REST wrapper for untag.

Takes the following url parameters:
 item : name of the topic to be untagged (format: Sandbox.TestTopic)
 tag  : name of the tag
 user : (optional) Wikiname of the user or group, whose tag shall be deleted (format: JoeDoe) 

If "user" is a groupname, the currently logged in user has to be member of that group. 
Guest user is only permitted, if he wants to delete his own tags.

It checks the prerequisites and sets the following status codes:
 200 : Ok
 400 : url parameter(s) are missing
 401 : access denied for unauthorized user
 403 : the user is not allowed to untag 

Return:
In case of an error (!=200 ) just the status code incl. short description is returned.
Otherwise a 200 and the number of affected tags (usually 0 or 1) is returned.

TODO:
 force http POST method
=cut

sub rest {
    my $session = shift;
    my $query   = Foswiki::Func::getCgiQuery();

    my $item_name = $query->param('item') || '';
    my $tag_text  = $query->param('tag')  || '';
    my $user      = $query->param('user') || Foswiki::Func::getWikiName();

    $item_name = Foswiki::Sandbox::untaintUnchecked($item_name);
    $tag_text  = Foswiki::Sandbox::untaintUnchecked($tag_text);
    $user      = Foswiki::Sandbox::untaintUnchecked($user);

    #
    # checking prerequisites
    #

    # first check the existence of all necessary url parameters
    #
    if ( !$item_name ) {
        $session->{response}->status(400);
        return "<h1>400 'item' parameter missing</h1>";
    }
    if ( !$tag_text ) {
        $session->{response}->status(400);
        return "<h1>400 'tag' parameter missing</h1>";
    }

    # check if current user is allowed to do so
    #
    if ( Foswiki::Func::isGuest() ) {
        $session->{response}->status(401);
        return "<h1>401 Access denied for unauthorized user</h1>";
    }

    # can $currentUser speak for $user?
    if ( Foswiki::Func::isGroup($user) ) {
        if (
            !Foswiki::Func::isGroupMember(
                $user, Foswiki::Func::getWikiName()
            )
          )
        {
            $session->{response}->status(403);
            return "<h1>403 Forbidden</h1>";
        }
    }
    elsif ( Foswiki::Func::getWikiName() ne $user ) {
        $session->{response}->status(403);
        return "<h1>403 Forbidden</h1>";
    }

    #
    # actioning
    #
    $session->{response}->status(200);
    
    # returning the number of affected tags
    return Foswiki::Plugins::TagsPlugin::Untag::do( $item_name, $tag_text, $user );
}

=begin TML

---++ do( $item_name, $tag_text, $user )
This does untagging.

Takes the following parameters:
 item_name : name of the topic to be untagged (format: Sandbox.TestTopic)
 tag_text  : name of the tag
 user      : Wikiname of the user or group, whose tag shall be deleted (format: JoeDoe) 

This routine does not check any prerequisites and/or priviledges. It returns 0, if
the given item_name, tag_text or user_id was not found.

Return:
 number of affected rows/tags.
=cut

sub do {
    my ( $item_name, $tag_text, $user ) = @_;
    my $db = new Foswiki::Contrib::DbiContrib;

    # determine item_id for given item_name and exit if its not there
    #
    my $item_id;
    my $statement = sprintf(
        'SELECT %s from %s WHERE %s = ? AND %s = ?',
        qw( item_id Items item_name item_type)
    );
    my $arrayRef = $db->dbSelect( $statement, $item_name, 'topic' );
    if ( defined( $arrayRef->[0][0] ) ) {
        $item_id = $arrayRef->[0][0];
    }
    else { return " -1"; }

    # determine tag_id for given tag_text and exit if its not there
    #
    my $tag_id;
    $statement = sprintf( 'SELECT %s from %s WHERE %s = ? AND %s = ?',
        qw( item_id Items item_name item_type) );
    $arrayRef = $db->dbSelect( $statement, $tag_text, 'tag' );
    if ( defined( $arrayRef->[0][0] ) ) {
        $tag_id = $arrayRef->[0][0];
    }
    else { return " -2"; }

    # determine cuid for given user_id and exit if its not there
    #
    my $cuid;
    $statement =
      sprintf( 'SELECT %s from %s WHERE %s = ? ', qw( CUID Users FoswikicUID) );
    $arrayRef = $db->dbSelect( $statement, $user );
    if ( defined( $arrayRef->[0][0] ) ) {
        $cuid = $arrayRef->[0][0];
    }
    else { return " -3"; }

    # now we are ready to actually untag
    #
    $statement =
      sprintf( 'DELETE from %s WHERE %s = ? AND %s = ? AND %s = ?',
        qw( UserItemTag item_id tag_id user_id ) );
    my $affected_rows = $db->dbDelete( $statement, $item_id, $tag_id, $cuid );
    if ( $affected_rows eq "0E0" ) { $affected_rows=0; };
    
    # update statistics
    #
    if ( $affected_rows > 0 ) {
        # ...in UserTagStat
        $statement =
          sprintf( 'UPDATE %s SET %s=%s-1 WHERE %s = ? AND %s = ?',
            qw( UserTagStat num_items num_items tag_id user_id) );
        my $modified = $db->dbInsert( $statement, $tag_id, $cuid );

        # ... in TagStat
        $statement =
          sprintf( 'UPDATE %s SET %s=%s-1 WHERE %s = ?',
            qw( TagStat num_items num_items tag_id) );
        $modified = $db->dbInsert( $statement, $tag_id );
    }

    # flushing data to dbms
    #    
    $db->commit();

    # add extra space, so that zero affected rows does not clash with returning "0" from rest invocation
    return " $affected_rows";
}

1;