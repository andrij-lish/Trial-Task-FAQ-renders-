use strict;

# Project configuration data

package loc;

our $home_path      = 'd:/_itest';                # Absolute path to project directory
our $lib_path       = 'd:/_itest/lib';            # Absolute path to project library directory
our $www_path       = 'd:/_itest/www';            # Absolute path to WWW directory in project  (ServerRoot from Apapche)
our $templates_path = 'd:/_itest/templates';      # Absolute path to teplates directory
our $home_url       = 'http://localhost';         # Site url, not used in this version
our $cgi_url        = 'http://localhost/cgi-bin'; # CGI-url, not used in this version

our (%db_host, %db_user, %db_pass);

$db_host{EWC_FAQ}  = 'localhost';  # MySQL host for db=EWC_FAQ
$db_user{EWC_FAQ}  = 'root';       # MySQL user for db=EWC_FAQ
$db_pass{EWC_FAQ}  = 'root';       # MySQL password for db=EWC_FAQ


1;



