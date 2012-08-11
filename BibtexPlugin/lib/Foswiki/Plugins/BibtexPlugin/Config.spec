# ---+ Extensions
# ---++ BibtexPlugin
# **PATH**
# Location of the <code>bibtex</code> executable.
$Foswiki::cfg{Plugins}{BibtexPlugin}{bibtex} = '/usr/bin/bibtex';

# **PATH**
# Location of the <code>bibtool</code> executable.
$Foswiki::cfg{Plugins}{BibtexPlugin}{bibtool} = '/usr/bin/bibtool';

# **PATH**
# Location of the <code>bib2bib</code> executable.
$Foswiki::cfg{Plugins}{BibtexPlugin}{bib2bib} = '/usr/bin/bib2bib';

# **PATH**
# Location of the <code>bibtex2html</code> executable.
$Foswiki::cfg{Plugins}{BibtexPlugin}{bibtex2html} = '/usr/bin/bibtex2html';

# **PATH**
# Location of the <code>texmf</code> tree path. 
# For custom <code>.bst</code> styles, bibtex processing needs to know where to find them.  The easiest way is to use a texmf tree below 'HOME'. On UNIX this is usually <code>~/texmf</code>, on MacOSX <code>~/Library/texmf</code> or when using MacPorts, <code>/opt/local/share/texmf</code>.
# See: <a href='http://en.wikibooks.org/wiki/LaTeX/Packages/Installing_Extra_Packages'>Wikibooks: LaTeX/Packages/Installing Extra Packages</a>.
$Foswiki::cfg{Plugins}{BibtexPlugin}{texmftree} = '/home/nobody';

# **PATH**
# Location of temporary files.
# Usually this <code>/tmp</code>, but you can assign an arbitrary directory. 
# Inside this directory, a directory <code>BibtexPlugin</code> will be created.
# Note that the directory must be emptied manually or by a custom cronjob if 
# it's not a regular system tmp directory. You can use 
# <code>$Foswiki::cfg{WorkingDir}/tmp</code> to use the default temporary files 
# location for Foswiki.
$Foswiki::cfg{Plugins}{BibtexPlugin}{tmpdir} = '/tmp';

# **PATH**
# URL of the CSS file.
$Foswiki::cfg{Plugins}{BibtexPlugin}{styleurl} = '$Foswiki::cfg{PubUrlPath}/$Foswiki::cfg{SystemWebName}/BibtexPlugin/style.css';

# **PERL H**
# This setting is required to enable executing the cgibibsearch script from the bin directory
$Foswiki::cfg{SwitchBoard}{bibsearch} = {
    package  => 'Foswiki::Plugins::BibtexPlugin::CgiBibSearch',
    function => 'cgibibsearch',
    context  => {
        bibsearch      => 1
    }
};

# **BOOLEAN**
# Debug flag; logs debugging messages to your debug.log
$Foswiki::cfg{Plugins}{BibtexPlugin}{Debug} = 0;
 
1;

