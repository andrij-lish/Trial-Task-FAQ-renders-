use strict;

package db;
# Package for handled database operation
# Work with connections pool 

use _loc;
use _ctrl;
use DBI;

sub new ($);

my $exist_connect=();  # Hash with active connects to Database, keys of hash - names of DB
my @handlers = ();     # Array of Database handle objects
my @sth_handlers = (); # Array of Statement handle objects
my %prepared_sth = (); # Array of Prepared Statement handle objects

1;

END {
# Disconnecting the database from all connected the database handles
	my ($h);
	for $h (@sth_handlers) { $h->finish; }
	for $h (@handlers) { $h->disconnect; }
}

# Methods:

sub new ($) {
my ($db) = @_;
	if ($exist_connect->{$db}) {
		return $exist_connect->{$db};
	}
	else {
		my $this = bless {};
		$this->{db_name} = $db;
		$this->{db_name_full} = "DBI:mysql:$db:$loc::db_host{$db}";
		$this->{connected} = 0;
		$exist_connect->{$db} = $this;
		return $this;
	}
}

sub get_uniques ($$) {
	my ($this, $table) = @_;
	$this->connect() unless $this->{connected};
	my (@unique, %unique);
	my $index = $this->{dbh}->selectall_arrayref("show index from $table");
	for (@$index) {
		unless ($_->[1]) {
			push @{$unique{$_->[2]}}, $_->[4];
		}
	}
	return [map $unique{$_}, keys %unique];
}

sub get_history_field ($$) {
	my ($this, $table) = @_;
	$this->connect() unless $this->{connected};
	for ( @{$this->{dbh}->selectall_arrayref("explain $table")} ) {
		return $_->[0] if ($_->[0] eq '_history' or $_->[0] eq '_record_history');
	}
	return '';
}

sub do ($$) {
	my ($this, $sql) = @_;
	my ($res,$time,$date);

	$this->connect() unless $this->{connected};
#   ctrl::info2user['do', $sql];
	my $dbh = $this->{dbh};
	$res = $dbh->do($sql);
	return $res;
}

sub errstr ($) {
	my ($this) = @_;
	$this->connect() unless $this->{connected};
	return $this->{dbh}->errstr();
}

sub selectrow_array ($$) {
	my ($this, $sql) = @_;
	$this->connect() unless $this->{connected};
#   ctrl::info2user['select', $sql];
	return $this->{dbh}->selectrow_array($sql);
}

sub selectall_arrayref ($$) {
	my ($this, $sql) = @_;
	my ($res,$time,$date);

	$this->connect() unless $this->{connected};
	$res = $this->{dbh}->selectall_arrayref($sql);
	$res = $this->{dbh}->selectall_arrayref($sql);
	return $res;
}

sub prepare ($$) {
	my ($this, $sql) = @_;
	$this->connect() unless $this->{connected};

	if ($prepared_sth{$sql})
	{
		return $prepared_sth{$sql};
	}

	my $local_sth = sth::new ($this->{dbh}, $sql, $this->{connect_id});
	push @sth_handlers, $local_sth if $local_sth;
	return $local_sth;
}

sub all_tables ($) {
	my ($dbh) = @_;
	my (@row, @ret, $sth);
	($sth = $dbh->prepare ('show tables'))->execute;
	while (@row = $sth->fetchrow_array) {
		push @ret, $row[0] if $row[0];
	}
	return @ret;
}

sub connect ($$) {
# Connecting to Database
	my ($this) = @_;

	my $db = $this->{db_name};
	my $db_user = $loc::db_user{$db} ;
	my $db_pass = $loc::db_pass{$db} ;

	my $h = DBI->connect( $this->{db_name_full}, $db_user, $db_pass );
	if ($h)
	{
		push @handlers, $h;
		$this->{dbh}       = $h;
		$this->{connected} = 1;

		my $rand = int(rand(100));
		srand();
		$this->{connect_id} = $0."::".time."::".$rand;

		return 1;
	}
	else
	{
		die "Unable to connect: $DBI::errstr";
	}
}


#############################################################

package sth;
# Package for work with Statement handle objects

use _loc;
use _ctrl;
use DBI;

sub new ($$$);

1;

# Methods:

sub new ($$$) {
	my ($dbh, $sql, $id) = @_;
	my $this = bless {};
	$this->{prepared} = 0;
	$this->{dbh} = $dbh;
	$this->{sql} = $sql;
	$this->{connect_id} = $id;
	$prepared_sth{$sql} = $this;
	return $this;
}

sub sth_prepare ($) {
	my ($this) = @_;
	unless ($this->{prepared})
	{
		$this->{sth} = $this->{dbh}->prepare($this->{sql});
		$this->{prepared} = 1;
	}
}

sub execute ($@) {
	my ($this,@parameters) = @_;
	my ($res,$param,$time,$date);

	$this->sth_prepare() unless $this->{prepared};
	if (@parameters)
		{ $res = $this->{sth}->execute(@parameters); }
	else
		{ $res = $this->{sth}->execute();}
	return $res;
}

sub fetchrow_array ($) {
	my ($this) = @_;
	$this->sth_prepare() unless $this->{prepared};
	return $this->{sth}->fetchrow_array();
}

sub fetchrow_arrayref ($) {
	my ($this) = @_;
	$this->sth_prepare() unless $this->{prepared};
	return $this->{sth}->fetchrow_arrayref();
}

sub fetchrow_hashref ($) {
	my ($this) = @_;
	$this->sth_prepare() unless $this->{prepared};
	return $this->{sth}->fetchrow_hashref();
}

sub fetchall_arrayref ($) {
	my ($this) = @_;
	$this->sth_prepare() unless $this->{prepared};
	return $this->{sth}->fetchall_arrayref();
}

sub rows ($) {
	my ($this) = @_;
	$this->sth_prepare() unless $this->{prepared};
	return $this->{sth}->rows();
}

sub finish ($) {
	my ($this) = @_;
	return $this->{sth}->finish() if $this->{prepared};
}


