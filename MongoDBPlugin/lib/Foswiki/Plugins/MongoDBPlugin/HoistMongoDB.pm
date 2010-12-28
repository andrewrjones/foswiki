# See bottom of file for copyright and license details

=begin TML

---+ package Foswiki::Plugins::MongoDBPlugin::HoistMongoDB

extract MonogDB queries from Query Nodes to accellerate querying

=cut

package Foswiki::Plugins::MongoDBPlugin::HoistMongoDB;

use strict;
use warnings;

use Foswiki::Infix::Node ();
use Foswiki::Query::Node ();
use Tie::IxHash          ();
use Data::Dumper;
use Error::Simple;
use Assert;

use Foswiki::Query::HoistREs ();

use constant MONITOR => 0;

=begin TML

---++ ObjectMethod hoist($query) -> $ref to IxHash


=cut

sub hoist {
    my ( $node, $indent ) = @_;

    return undef unless ref( $node->{op} );

    print STDERR "hoist from: ", $node->stringify(), "\n" if MONITOR;

#TODO: use IxHash to keep the hash order - _some_ parts of queries are order sensitive
#    my %mongoQuery = ();
#    my $ixhQuery = tie( %mongoQuery, 'Tie::IxHash' );
#    $ixhQuery->Push( $scope => $elem );
    my $mongoDBQuery;

    $mongoDBQuery =
      Foswiki::Plugins::MongoDBPlugin::HoistMongoDB::_hoist($node);

#TODO: sadly, the exception throwing wasn't working so I'm using a brutish propogate error
    if ( defined( $mongoDBQuery->{ERROR} ) ) {
        print STDERR "AAAAARGH " . $mongoDBQuery->{ERROR} . "\n";
        return;
    }

    print STDERR "Hoisted to:  ",    #$node->stringify(), " -> /",
      Dumper($mongoDBQuery), "/\n"
      if MONITOR;

    return $mongoDBQuery;
}

sub _hoist {
    my $node = shift;

    #name, or constants.
    if ( !ref( $node->{op} ) ) {
        return Foswiki::Query::OP_dot::hoistMongoDB($node);
    }
    if ( ref( $node->{op} ) eq 'Foswiki::Query::OP_dot' ) {
        return Foswiki::Query::OP_dot::hoistMongoDB($node);
    }
    print STDERR "???????" . ref( $node->{op} ) . "\n" if MONITOR;

    #TODO: if 2 constants(NUMBER,STRING) ASSERT
    #TODO: if the first is a constant, swap

    print STDERR "\nparam0(" . $node->{params}[0]->{op} . "): ",
      Data::Dumper::Dumper( $node->{params}[0] ), "\n"
      if MONITOR;
    print STDERR "\nparam1(" . $node->{params}[1]->{op} . "): ",
      Data::Dumper::Dumper( $node->{params}[1] ), "\n"
      if MONITOR;

    $node->{lhs} = Foswiki::Plugins::MongoDBPlugin::HoistMongoDB::_hoist(
        $node->{params}[0] )
      if ( $node->{op}->{arity} > 0 );
    $node->{ERROR} = $node->{lhs}->{ERROR}
      if ( ref( $node->{lhs} ) and defined( $node->{lhs}->{ERROR} ) );

    $node->{rhs} = Foswiki::Plugins::MongoDBPlugin::HoistMongoDB::_hoist(
        $node->{params}[1] )
      if ( $node->{op}->{arity} > 0 );
    $node->{ERROR} = $node->{rhs}->{ERROR}
      if ( ref( $node->{rhs} ) and defined( $node->{rhs}->{ERROR} ) );

    #TODO: mmm, do we only have unary and binary ops?

    print STDERR "----lhs: "
      . Data::Dumper::Dumper( $node->{lhs} )
      . "----rhs: "
      . Data::Dumper::Dumper( $node->{rhs} ) . " \n"
      if MONITOR;

    use Data::Dumper;

#print STDERR "HoistS ",$query->stringify()," -> /",Dumper($mongoDBQuery),"/\n";

    print STDERR "Hoist node->op="
      . Dumper( $node->{op} )
      . " ref(node->op)="
      . ref( $node->{op} ) . "\n"
      if MONITOR;

#DAMMIT, I presume we have oddly nested eval/try catch so throwing isn't working
#throw Error::Simple( 'failed to Hoist ' . ref( $node->{op} ) . "\n" )
# unless ( $node->{op}->can('hoistMongoDB') );
    unless ( $node->{op}->can('hoistMongoDB') ) {
        $node->{ERROR} = 'can\'t Hoist ' . ref( $node->{op} );
    }
    if ( defined( $node->{ERROR} ) ) {
        print STDERR "HOIST ERROR: " . $node->{ERROR};
        return $node;
    }

    return $node->{op}->hoistMongoDB($node);
}

########################################################################################
#Hoist the OP's

=begin TML

---++ ObjectMethod Foswiki::Query::OP_eq::hoistMongoDB($node) -> $ref to IxHash

hoist ~ into a mongoDB ixHash query

=cut

package Foswiki::Query::OP_eq;
use Assert;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    ASSERT( $node->{op}->{name} eq '=' ) if DEBUG;
    return { $node->{lhs} => $node->{rhs} };
}

=begin TML

---++ ObjectMethod Foswiki::Query::OP_like::hoistMongoDB($node) -> $ref to IxHash

hoist ~ into a mongoDB ixHash query

=cut

package Foswiki::Query::OP_like;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    my $rhs = quotemeta( $node->{rhs} );
    $rhs =~ s/\\\?/./g;
    $rhs =~ s/\\\*/.*/g;
    $rhs = qr/$rhs/;

    return { $node->{lhs} => $rhs };
}

=begin TML

---++ ObjectMethod Foswiki::Query::OP_dot::hoistMongoDB($node) -> $ref to IxHash

hoist ~ into a mongoDB ixHash query

=cut

package Foswiki::Query::OP_dot;
our %aliases = (

    #    attachments => 'META:FILEATTACHMENT',
    #    fields      => 'META:FIELD',
    #    form        => 'META:FORM',
    #    info        => 'META:TOPICINFO',
    #    moved       => 'META:TOPICMOVED',
    #    parent      => 'META:TOPICPARENT',
    #    preferences => 'META:PREFERENCE',
    name => '_topic',
    web  => '_web',
    text => '_text'
);

sub hoistMongoDB {
    my $node = shift;

    if ( ref( $node->{op} ) ) {

        #an actual OP_dot
        my $lhs = $node->{params}[0];
        my $rhs = $node->{params}[1];

        #        ASSERT( !ref( $lhs->{op} ) ) if DEBUG;
        #        ASSERT( !ref( $rhs->{op} ) ) if DEBUG;
        #        ASSERT( $lhs->{op} eq Foswiki::Infix::Node::NAME ) if DEBUG;
        #        ASSERT( $rhs->{op} eq Foswiki::Infix::Node::NAME )
        #          if DEBUG;

        $lhs = $lhs->{params}[0];
        $rhs = $rhs->{params}[0];
        if ( $Foswiki::Query::Node::aliases{$lhs} ) {
            $lhs = $Foswiki::Query::Node::aliases{$lhs};
        }

        #        print STDERR "hoist OP_dot("
        #          . ref( $node->{op} ) . ", "
        #          . Data::Dumper::Dumper($node)
        #          . ")\n INTO "
        #          . $lhs . '.'
        #          . $rhs . "\n";

        if ( $lhs =~ s/^META:// ) {
            return $lhs . '.' . $rhs;
        }
        else {

            # TODO: assumes the term before the dot is the form name??? gads
            return 'FIELD.' . $rhs . '.value';
        }
    }
    elsif ( $node->{op} == Foswiki::Infix::Node::NAME ) {

        #        print STDERR "hoist OP_dot("
        #          . $node->{op} . ", "
        #          . $node->{params}[0] . ")\n";

        #TODO: map to the MongoDB field names (name, web, text, fieldname)
        return $aliases{ $node->{params}[0] }
          if ( defined( $aliases{ $node->{params}[0] } ) );
        return 'FIELD.' . $node->{params}[0] . '.value';
    }
    elsif (( $node->{op} == Foswiki::Infix::Node::NUMBER )
        or ( $node->{op} == Foswiki::Infix::Node::STRING ) )
    {
        return $node->{params}[0];
    }
}

package Foswiki::Query::OP_and;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return { %{ $node->{lhs} }, %{ $node->{rhs} } };
}

package Foswiki::Query::OP_or;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    #need to detect nested OR's and unwind them
    if ( defined( $node->{lhs}->{'$or'} ) ) {
        push( @{ $node->{lhs}->{'$or'} }, $node->{rhs} );
        return $node->{lhs};
    }

    return { '$or' => [ $node->{lhs}, $node->{rhs} ] };
}

package Foswiki::Query::OP_not;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return { '$not' => $node->{lhs} };
}

package Foswiki::Query::OP_gte;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return { $node->{lhs} => { '$gte' => $node->{rhs} } };
}

package Foswiki::Query::OP_gt;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return { $node->{lhs} => { '$gt' => $node->{rhs} } };
}

package Foswiki::Query::OP_lte;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return { $node->{lhs} => { '$lte' => $node->{rhs} } };
}

package Foswiki::Query::OP_lt;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return { $node->{lhs} => { '$lt' => $node->{rhs} } };
}

package Foswiki::Query::OP_match;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    my $rhs = quotemeta( $node->{rhs} );
    $rhs =~ s/\\\././g;
    $rhs =~ s/\\\*/*/g;
    $rhs = qr/$rhs/;

    return { $node->{lhs} => $rhs };
}

package Foswiki::Query::OP_ne;

sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return { $node->{lhs} => { '$ne' => $node->{rhs} } };
}

package Foswiki::Query::OP_d2n;

package Foswiki::Query::OP_lc;

package Foswiki::Query::OP_length;

package Foswiki::Query::OP_ob;

# ( )
sub hoistMongoDB {
    my $op   = shift;
    my $node = shift;

    return $node->{lhs};
}

package Foswiki::Query::OP_ref;

package Foswiki::Query::OP_uc;

package Foswiki::Query::OP_where;

1;
__DATA__

Module of Foswiki - The Free and Open Source Wiki, http://foswiki.org/, http://Foswiki.org/

Copyright (C) 2010 Foswiki Contributors. All Rights Reserved.
Foswiki Contributors are listed in the AUTHORS file in the root
of this distribution. NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.

Author: Sven Dowideit http://fosiki.com