#!/usr/bin/perl

# takes Q&A data from two tables (questions and questions) in a MySQL database and renders it as HTML

use strict;
use CGI;
use CGI::Carp qw/fatalsToBrowser/;

#pod =absolute path to our  privat library
#pod
#pod B<WARNING>: We need to specify the absolute path to our  privat library directory
#pod This can be done in several ways:
#pod a) Set use lib '/path_to_our_project/lib'
#pod b) Set the environment variable PERL5LIB
#pod c) Use '-I' command line parameter: perl -I /path_to_our_project/lib
#pod d) Changing the Apache configuration (httpd.conf), for example adding 
#pod
#pod =cut

use lib 'D:/_itest/lib';
use lib '../../lib';

use _loc;
use _db;

my $title_string = "Questions The European Watch Company has Frequently Been Asked";  # better got it from some CFG file
my $db           = "EWC_FAQ";                                                         # better got DB name from some CFG file

my $dbh = db::new $db;

my $faq_hash = build_faq_hash ($dbh);               # build the hash from Q&A values from database
my $faq_content = faq_hash_to_content ($faq_hash);  # convert the hash with values to HTML code 
my $html_header = get_page_header();                # get HTML header from some templates

######################### here must be code for handle insertion of the faq content into the larger page and output a page #########################

print STDOUT "Content-type: text/html\n\n";
print STDOUT "$html_header\n";
print STDOUT "<body>\n";
print STDOUT "<div id=\"content\">\n$faq_content\n</div>\n";
print STDOUT "</body>\n";
print STDOUT "</html>\n";

######################### here must be code for handle insertion of the faq content into the larger page and output a page #########################


sub build_faq_hash ($) {
### Receives the parameter $dbh  - Database Handle
### Then selected records from table "questions" which mark enabled=1
### Construct a hash of values, the keys of which are categories of questions
### Returns the constructed hash

	my ($dbh_faq) = @_;
	my %result_hash = ();
	my $result_hash = \%result_hash;
	
	my $sth = $dbh_faq->prepare (   "select categories.category_name as category,categories.description, categories.sort_order, question, answer, mail_target
									from questions inner join categories on questions.category=categories.id
									where questions.enabled=1 and categories.enabled=1 order by sort_order;");
	$sth->execute;
	my $li = 0;
	while (my $r = $sth->fetchrow_hashref)
	{
		$result_hash{$r->{category}}{description} = $r->{description};
		$result_hash{$r->{category}}{mail_target} = $r->{mail_target};
		$result_hash{$r->{category}}{questions_order} = $li;
		$result_hash{$r->{category}}{questions}{$li}{q} = $r->{question};
		$result_hash{$r->{category}}{questions}{$li}{a} = $r->{answer};
		$li++;
	}
	return $result_hash;
}

sub faq_hash_to_content ($) {
### Receives the hash with data from MySQL tables
### Then renders the HTML code
### <ul class="accordion"> - This is the beginning of the block FAQ
### </ul> - This is the end of the block FAQ
### Returns the HTML code

	my ($faq_h) = @_;
	my $content = "<div class=\"heading\"><h1 class=\"title\">$title_string</h1></div>\n";

	$content .= "<ul class=\"accordion\">\n";
	for my $key (sort {$faq_h->{$a}->{questions_order} <=> $faq_h->{$b}->{questions_order} } keys %{$faq_h})
	{
		$content .="<li><a class=\"opener\" href=\"#\"> $faq_h->{$key}->{description}</a>\n";
		$content .= qq (<div class="slide">
								<div class="slide-holder">
									<div class="slide-area">)."\n";
		
		for my $key1 (sort keys %{$faq_h->{$key}->{questions}} ) 	
		{
			$content .= "<div class=\"row\">\n";
			$content .= "\t<div class=\"question\"> <strong class=\"title\">Q:</strong>\n";
			$content .= "\t\t<div class=\"holder\">$faq_h->{$key}->{questions}->{$key1}{q}</div>\n\t</div>\n";
			$content .= "\t<div class=\"answer\"><strong class=\"title\">A:</strong>\n";
			$content .= "\t\t<div class=\"holder\">$faq_h->{$key}->{questions}{$key1}->{a}</div>\n\t</div>\n";
			$content .= "</div>\n";
			
		}
		$content .= "\t\t\t\t\t\t\t\t\t</div>\n<a href=\"/email-contact.php?to=$faq_h->{$key}->{mail_target}&amp;subject=A Question About the $key\">Ask a question</a>\n";
		$content .= "\t\t\t\t\t\t\t\t</div>\n</div>\n</li>\n";
	}
	$content .= "</ul>\n";
	return $content;
}

sub get_page_header() {
### Example of getting a page header from a template
### Probably will be change on Template Toolkit
### Returns content from teplate, or simly HTML header, if that do not exists

	my $content = "";
	my $filename = $loc::templates_path."/header.html";
	if (open(my $fh, '<:encoding(UTF-8)', $filename)) {
		while (my $row = <$fh>) {
			$content .= $row;
		}
	}
	else {
		my $q = new CGI;
		$content = $q->header( "text/html" );
	}
	return $content;
}

