use strict;

package param;
# Package for parsing CFG files, private work with files and directories 

use _ctrl;

sub test             (\@);
sub parse         (\@;\%);
sub get_subdir      ($$;$);
sub file_list     ($$$\@);

my ($a,$b,$c) = caller;
test @ARGV if not "$a$b$c";

1;

sub test  (\@) {
# print keys of hash and hash values
   my $param = parse @{$_[0]};
   my $pn;
   for $pn (sort keys %$param) {
      print "$pn\t";
      print ("'$param->{$pn}'\n", map {"\t$_\n"} @{$param->{$pn}});
   }
}

sub get_subdir ($$;$) {
   my ($path, $subdir, $quiet) = @_;
# creating subdirectory $subdir  in catalogue  $path, If it does not exist
   my $dir;

   if ($subdir) {
      $dir = "$path/$subdir";
   } else {
      my ($sec,$min,$hour,$mday,$mon,$yy) = localtime;
      $yy  += 1900;
      $mon  = "0$mon"  if ++$mon < 10;
      $mday = "0$mday" if $mday < 10;
      $dir = "$path/$yy$mon$mday";
   }

   unless (-d $dir) {
      ctrl::warning "Directory $dir is absent. Creating...\n" unless $quiet;
      unless (mkdir $dir, 0777) {
          ctrl::warning "Error creating directory $dir\n" unless $quiet;
          return '';
      }
   }
   return $dir;
}

sub file_list ($$$\@) {
   my ($dir, $tpl, $ext, $files0) = @_;
# Return array with names of files in directory $dir with extension $ext and names that match the pattern $tpl
   my ($file, $f, @files, $ext_tpl);

   if (-d $dir) {
      $dir .= '/' unless $dir =~ /\/$/;
   } else {
      $dir = '';
   }

   $ext_tpl = "\\.$ext" if $ext;
   $ext     = ".$ext"   if $ext;

#   ctrl::info2user ['dir', $dir], ['ext', $ext], ['files0', $files0];

   for $file (@$files0) {
      if ( -d $dir.$file ) {
         opendir DIR, $dir.$file;
         for $f (sort readdir DIR) {
            push @files, "$dir$file/$f" if (not -d "$dir$file/$f") and (not $tpl or $f =~ /$tpl/) and (not $ext_tpl or $f =~ s/$ext_tpl$//i);
         }
         closedir DIR;
      } elsif ( -f "$dir$file$ext" ) {
         push @files, "$dir$file" if $file.$ext =~ /$tpl/i;
      }
   }
   return \@files;
}

sub parse (\@;\%) {
# Parsing CFG-file, or command line
   my ($param, $ret) = @_;
   my (%ret, $one, $last, $block);

   unless ($ret) {
      $ret = \%ret;
      $ret->{''} = [];
   }

   if (not @$param) {
      $0 =~ s/.*\/([^\/]+)$/$1/o;
      $0 =~ s/\..*//o;
      if (-f "$0.cmd") {
         $ret->{f} = ["$0.cmd"];
      } elsif ( -f 'default.cmd') {
         $ret->{f} = ['default.cmd'];
      }
   } else {
      while (defined ($one = shift @$param)) {
#         print "$one\n";
         if ($block) {
            if ($one eq ')') {
               $block = '';
               $last = '';
            } else {
               push @{$ret->{$last}}, $one;
            }
         } elsif ($one =~ /^-(-?)(.*?)(\(?)$/o) {
            $block = 1 if $3;
            for ($2 ? $1 ? $2 : split //, $2 : '') {
               $ret->{$last} = []  unless $ret->{$last = $_};
            }
         } elsif ($ret->{$last}) {
            push @{$ret->{$last}}, $one;
         } else {
            $ret->{$last} = [$one];
         }
      }
   }

   my ($file, @files, @param);
   if ($ret->{f}) {
      @files = @{$ret->{f}};
   } else {
      return $ret;
   }
   delete $ret->{f};
   for $file (@files) {
      if (open PRESET, $file) {
         @param = ();
         @param = (@param, (split /\s+/, $_)) while <PRESET>;
         close PRESET;
         parse @param, %$ret; 
      }
   }
   return $ret;
}

