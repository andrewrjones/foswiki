use File::Spec;

BEGIN {
    # Load setlib.cfg
    my ( $volume, $rootDir ) = File::Spec->splitpath(__FILE__);
    my $setlib = File::Spec->catpath( $volume, $rootDir, 'bin/setlib.cfg' );
    @INC = ( '.', grep { $_ ne '.' } @INC ) unless $rootDir;
    require $setlib;
}

use Foswiki     ();
use Foswiki::UI ();

# TODO: new config value?
$Foswiki::cfg{UseViewFile} = 0;

use Plack::Builder;
use Plack::App::WrapCGI;
builder {
    mount '/' => builder {
        
        # enables the debugger, for local user
        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'Debug';
        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' } 'Lint';
    
        # avoid viewfile
        enable_if { $Foswiki::cfg{UseViewFile} == 0 } "Plack::Middleware::Static",
            path => qr{^$Foswiki::cfg{PubUrlPath}}, root => "$Foswiki::cfg{PubDir}/../";
    
        # this must be last
        sub { $Foswiki::engine->run(@_) };
    };
    
    # cheating with configure for the moment...
    mount "$Foswiki::cfg{ScriptUrlPath}/configure" => builder {
        Plack::App::WrapCGI->new( script => "$Foswiki::cfg{ScriptDir}/configure", execute => 1)->to_app;
    };
};

__END__

Getting Started
---------------

This is the entry point for PSGI. To get a server running, just do:
  plackup foswiki.psgi

If your doing development, the following will recompile on each request:
  plackup -L Shotgun foswiki.psg
  
TODO
----
- Get tests passing. Current progress at http://ci.arjones.co.uk/waterfall?show=foswiki-psgi
- Fix generated edit links
- Check 'auth' scripts
- Test uploads
- Rename foswiki.psgi to foswiki.psg.sample (or similar) and add lots of documentation
- Mark accessors in Foswiki::Request and Foswiki::Response as depreciated where they do not match Plack::(Request|Response)

ISSUES
------

- Can't log in
  - a redirect to the login form produces a die
  - something to do with Foswiki::getScriptUrl?
- Some URLS are not generated correctly
