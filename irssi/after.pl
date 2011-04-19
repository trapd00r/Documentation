use warnings;
use strict;

use Irssi ();

our $VERSION = '0.02';

our %IRSSI = (
	authors => 'mauke',
	name => 'after',
);

{
	my %units = (
		d => 60 * 60 * 24,
		h => 60 * 60,
		m => 60,
		s => 1,
	);

	sub scale; *scale = sub {
		$_[0] * $units{$_[1]};
	};
}

sub parsetime {
	my ($spec) = @_;
	my $n = 0;
	while ($spec =~ s/^(\d+)([dhms])//) {
		$n += scale $1, $2;
	}
	$n += $spec if $spec;
	$n
}

Irssi::command_bind after => sub {
	my ($data, $server, $witem) = @_;
	$data =~ s/^\s*(\S+)\s+(?=\S)// or do {
		Irssi::print "after: syntax error: $data";
		return;
	};
	my $time = 1000 * parsetime $1;
	$time >= 10 or $time = 10;
	Irssi::timeout_add_once($time, sub { ($witem || $server)->command($data) }, undef);
};
