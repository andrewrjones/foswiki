# Test for Search.pm
package SearchTests;
use base qw( FoswikiFnTestCase );

use strict;
use CGI;

use Foswiki::Func;
use Foswiki::Contrib::SearchEngineKinoSearchAddOn::Search;
use Foswiki::Contrib::SearchEngineKinoSearchAddOn::Index;

sub new {
    my $self = shift()->SUPER::new('Search', @_);
    
    $self->{attachmentDir} = 'attachement_examples/';
    if (! -e $self->{attachmentDir}) {
        #running from foswiki/test/unit
        $self->{attachmentDir} = 'SearchEngineKinoSearchAddOn/attachement_examples/';
    }
    return $self;
}

sub set_up {
    my $this = shift;

    $this->SUPER::set_up();
    # Use RcsLite so we can manually gen topic revs
    $Foswiki::cfg{StoreImpl} = 'RcsLite';

    $this->registerUser("TestUser", "User", "TestUser", 'testuser@an-address.net');
    $this->assert( defined $this->{users_web}, "no {users_web}" );
    Foswiki::Func::saveTopicText( $this->{users_web}, 'TopicWithoutAttachment', <<'HERE');
Just an example topic
Keyword: startpoint
HERE
	Foswiki::Func::saveTopicText( $this->{users_web}, 'TopicWithWordAttachment', <<'HERE');
Just an example topic wird MS Word
Keyword: redmond
HERE
	Foswiki::Func::saveAttachment( $this->{users_web}, "TopicWithWordAttachment", "Simple_example.doc",
				       {file => $this->{attachmentDir}."Simple_example.doc"});
}

sub tear_down {
    my $this = shift;
    $this->SUPER::tear_down();
}

sub test_newSearch {
    my $this = shift;
    my $search = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Search->newSearch();

    $this->assert(defined($search), "Search exemplar not created.")
}

sub test_docsForQuery {
    my $this = shift;
    my $search = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Search->newSearch();

    # Create an index of the current situation.
    my $ind = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Index->newCreateIndex();
    $ind->createIndex();

    # Now I search for something that does not exist.
    my $docs = $search->docsForQuery( "ThisDoesNotExist");
    my $hit  = $docs->fetch_hit_hashref;
    $this->assert(!defined($hit), "Bad hit found.");

    # Let's create something
    Foswiki::Func::saveTopicText( $this->{users_web}, "TopicTitleToSearch", <<'HERE');
Just an example topic
Keyword: BodyToSearchFor
HERE

    # Create an index of the current situation.
    $ind->createIndex();

    # Now I search for the title
    $docs = $search->docsForQuery( "TopicTitleToSearch");
    $hit  = $docs->fetch_hit_hashref;
    $this->assert(defined($hit), "Hit for title not found.");
    my $topic = $hit->{topic};
    $topic =~ s/ .*//;
    $this->assert_str_equals($topic, "TopicTitleToSearch", "Wrong topic for tile.");

    $docs = $search->docsForQuery( "BodyToSearchFor");
    $hit  = $docs->fetch_hit_hashref;
    $this->assert(defined($hit), "Hit for body not found.");
    $topic = $hit->{topic};
    $topic =~ s/ .*//;
    $this->assert_str_equals($topic, "TopicTitleToSearch", "Wrong topic for body.");
}

sub test_renderHtmlStringFor {
    my $this = shift;
    my $search = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Search->newSearch();

    # Let's create something
    Foswiki::Func::saveTopicText( $this->{users_web}, "TopicTitleToSearch", <<'HERE');
Just an example topic
Keyword: BodyToSearchFor
HERE

    my $ind = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Index->newCreateIndex();
    $ind->createIndex();

    # Now I search for the title
    my $docs = $search->docsForQuery( "TopicTitleToSearch");
    my $hit  = $docs->fetch_hit_hashref;

    # load the template
    my $tmpl = Foswiki::Func::readTemplate( "kinosearch" );
    $tmpl =~ s/\%META{.*?}\%//go;  # remove %META{"parent"}%;
    # split the template into sections
    my( $tmplHead, $tmplSearch,
        $tmplTable, $tmplNumber, $tmplTail ) = split( /%SPLIT%/, $tmpl );

    # prepare for the result list
    my( $beforeText, $repeatText, $afterText ) = split( /%REPEAT%/, $tmplTable );

    my $nosummary = "";
    my $htmlString = $search->renderHtmlStringFor($hit, $repeatText, $nosummary);

    #print "HTML Result: #############################\n";
    #print "$htmlString\n";

    $this->assert(index($htmlString, $hit->{web}),   "Web not in result");
    my $restopic = $hit->{topic};
    # For partial name search of topics, just hold the first part of the string
    if($restopic =~ m/(\w+)/) { $restopic =~ s/ .*//; }
    $this->assert(index($htmlString, $restopic), "Topic not in result");
    
}

sub test_search {
    my $this = shift;
    my $result;

    my $ind = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Index->newCreateIndex();
    $ind->createIndex();

    $result = $this->_search($this->{test_web},
			     "Kino",
			     $this->{test_user_wikiname},
			     "startpoint");

    $this->assert(index($result, "TopicWithoutAttachment") > 0,   "TopicWithoutAttachment not found");
}

sub test_searchAttachments {
    my $this = shift;
    my $search = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Search->newSearch();

    # Let's create something
    Foswiki::Func::saveTopicText( $this->{users_web}, "TopicToSearch", <<'HERE');
Just an example topic
Keyword: BodyToSearchFor
HERE

	Foswiki::Func::saveAttachment( $this->{users_web}, "TopicToSearch", "Simple_example.doc",
				       {file => $this->{attachmentDir}."Simple_example.doc"});

    my $ind = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Index->newCreateIndex();
    $ind->createIndex();

    my $result = $this->_search($this->{test_web},
			     "Kino",
			     $this->{test_user_wikiname},
			     "type:doc");

    $this->assert(index($result, "TopicToSearch") > 0,   "TopicToSearch not found for type:doc");

    $result = $this->_search($this->{test_web},
			     "Kino",
			     $this->{test_user_wikiname},
			     "name:Simple_example.doc");

    $this->assert(index($result, "TopicToSearch") > 0,   "TopicToSearch not found for name:Simple_example.doc");
}

# I check, if the access rights of the users are checked.
sub test_search_with_users {
    my $this = shift;
    my $result;

    # I add another user
    $this->registerUser("TestUser2", "User", "TestUser2", 'testuser@an-address.net');

    # Now I create a topic that only "TestUser2" can read
    Foswiki::Func::saveTopicText( $this->{users_web}, "TopicWithAccesControl", << 'HERE');
Just an example topic
Keyword: KeepOutHere
      * Set ALLOWTOPICVIEW = UserTestUser2
HERE

    my $ind = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Index->newCreateIndex();
    $ind->createIndex();

    # Let's see if TestUser2 can find his topic
    $result = $this->_search($this->{test_web},
			     "Kino",
			     "TestUser2",
			     "KeepOutHere");

    $this->assert(index($result, "TopicWithAccesControl") > 0,   "TopicWithAccesControl not found");    

    # No the reverse test: The normal test uses should not find the toipic
    $result = $this->_search($this->{test_web},
			     "Kino",
			     $this->{test_user_wikiname},
			     "KeepOutHere");

    $this->assert(index($result, "TopicWithoutAttachment") < 0,   "TopicWithoutAttachment should not be found");
}

# Helper method to do a search.
sub _search {
    my ( $this, $web, $topic, $user, $searchString ) = @_;
    
    my $query = new CGI({
        webName   => [ $web ],
        topicName => [ $topic ],
        search    => [ $searchString ],
    });

    $query->path_info( "$web/$topic" );

    #my $foswiki  = new Foswiki( $this->{test_user_login}, $query );
    my $foswiki  = new Foswiki( $user, $query );

    my $search = Foswiki::Contrib::SearchEngineKinoSearchAddOn::Search->newSearch();

    # Note: With $foswiki I hand over the just defined session. Thus I have full 
    # control over query etc.
    my ($text, $result) = $this->capture( \&Foswiki::Contrib::SearchEngineKinoSearchAddOn::Search::search, $search, undef, $foswiki);

    $foswiki->finish();
    $text =~ s/\r//g;
    $text =~ s/^.*?\n\n+//s; # remove CGI header
    return $text;
}

1;
