use strict;

package ctrl;
# Service functions, confirmation requests, logging

use _ctrl;
use _loc;

sub warning          ($;$);
sub logging           ($@);
sub info2user          (@);
sub stop_unless       ($$);
sub do_you_want      ($;$);

my %warnings_done = ();

open LOG, ">>_log";
print LOG ("\n".mytime()." -- $0 @ARGV\n");

1;

sub mytime (;$) {
# Convert current time, or change time to format: DDDD-MM-YY HH:MM;SS
   my $time = $_[0] ? $_[0] : time;
   my ($sec,$min,$hour,$mday,$mon,$year) = localtime $time;
   $year += 1900;
   $mon = "0$mon" if ++$mon < 10; 
   $mday = "0$mday" if $mday < 10; 
   $sec = "0$sec" if $sec < 10; 
   $min = "0$min" if $min < 10; 
   $hour = "0$hour" if $hour < 10; 
   return "$year-$mon-$mday $hour:$min:$sec";
}


sub warning ($;$) {
# print warning message to concole
   my ($msg, $supress_doubles) = @_;
   $msg =~ s/\n\s*$//mo;
   unless ($supress_doubles and $warnings_done{$msg}) {
      print "$msg...\n";
      print LOG "$msg...\n";
      close LOG; open LOG, ">>_log";
   }
   $warnings_done{$msg}++;
}

sub do_you_want ($;$) {
# confirmation requests to concole

   my ($msg, $answer) = @_;
   $msg =~ s/\?+\s*$//mgo;

   my $var = ($answer > 0) ? '[Y/n]' : $answer ? '[y/N]' : '[y/n]';

   LOOP:
      print  "$msg\nYes or No? $var ";
      my $buf = <STDIN>;
      if ($buf =~ /^\s*y\s*\n/i) {
         $answer = 1;
      } elsif ($buf =~ /^\s*n\s*\n/i) {
         $answer = -1;
      }
   unless ($answer) {
      print  "Sorry? ";
      goto LOOP;
   }
   return ($answer > 0);
}


sub logging ($@) {
# logging script works into the file _log
   my ($file, @params) = @_;
   my ($name, $value, $options, $key, $key1, $accum);

#   $file = *LOG unless $file;

   for (@params) {
      if (ref $_ eq 'ARRAY') {
         ($name, $value, $options) = @$_;
         if (ref $value eq 'ARRAY') {
            $accum .= ("list '$name' = ").(join ',', map {"'$_'"} @$value)."\n";
         } elsif (ref $value eq 'HASH') {
            $accum .= "hash '$name' =\n";
            for $key (keys %$value) {
               $accum .= "\t'$key' => '$value->{$key}'\n";
               if (ref $value->{$key} eq 'HASH' and $options) {
                  for $key1 (keys %{$value->{$key}}) {
                     $accum .= "\t\t'$key1' => '$value->{$key}->{$key1}'\n";
                  }
               }
            }    
         } else {
            $accum .= "'$name': '$value'\n";
         }
      } else {
         $accum .= "$_\n";
      }
   }
   open LOG, '>>_log';
   print LOG $accum;
   close LOG; 
   print $file $accum if $file;
}


sub info2user (@) {
# logging script works into the file _log
   logging *STDOUT, @_;
#   print "press enter...\n"; <STDIN>;
}

sub stop_unless ($$) {
# message to console and exit if $value empty
   my ($message, $value) = @_;
   unless ($value) {
      print "$message\tpress enter...\n"; <STDIN>;
      exit;
   }
}




