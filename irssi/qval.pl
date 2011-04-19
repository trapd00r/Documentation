use warnings;
use strict;

use Irssi ();

our $VERSION = '0.09';
our %IRSSI = (
	authors => 'mauke',
	name => 'qval',
);

use charnames qw(:short :full);

use constant {
	IRSSI_COLOR_NOCHANGE => "\x2f",
	IRSSI_ESCAPE => "\x04",
};

my %tr = (
	a => "\a",
	b => "\b",
	e => "\e",
	f => "\f",
	n => "\n",
	r => "\r",
	t => "\t",
	v => "\013",
);

my %pretty = (
	"\r" => '\r',
	"\n" => '\n',
	"\0" => '\0',
);

my %irssi = (
	B => "\x61", # blink
	b => "\x63", # bold
	d => "\x67", # defaults
	r => "\x64", # reverse
	u => "\x62", # underline
);

my %color = (
	n => 0, # black
	b => 1, # blue
	g => 2, # green
	c => 3, # cyan
	r => 4, # red
	m => 5, # magenta
	y => 6, # yellow
	w => 7, # white
	N => 8,  # special black
	B => 9,  # special blue
	G => 10, # special green
	C => 11, # special cyan
	R => 12, # special red
	M => 13, # special magenta
	Y => 14, # special yellow
	W => 15, # special white
);

Irssi::command_bind(
	qval => sub {
		my ($data, $server, $witem) = @_;
		$data =~ s"\\([\\abefnrtv]|[0-7]{1,3}|d(?:\d+|\{\d+\})|x(?:\{[[:xdigit:]]+\}|[[:xdigit:]]{1,2})|c[\@A-Z?_]|m[\@-_]|i(?:[Bbdru]|\{(?:\d*(?:,\d+)?|[nbgcrmywNBGCRMYW](?:,[nbgcrmywNBGCRMYW])?|,[nbgcrmywNBGCRMYW])\})|N\{[^}]*\})"
			my $x = $1;
			if ($x =~ /^[0-7]{1,3}\z/) {
				$x = chr oct $x;
			} elsif ($x =~ /^d\d+\z/) {
				$x = chr substr $x, 1;
			} elsif ($x =~ /^d\{(\d+)\}\z/) {
				$x = chr $1;
			} elsif ($x =~ /^x[[:xdigit:]]{1,2}\z/) {
				$x = chr hex substr $x, 1;
			} elsif ($x =~ /^x\{[[:xdigit:]]+\}\z/) {
				$x = chr hex substr $x, 2, -1;
			} elsif ($x =~ /^c[\@A-Z?_]\z/) {
				$x = chr((ord(substr $x, 1) + 64) % 128);
			} elsif ($x =~ /^m[\@-_]\z/) {
				$x = chr(ord(substr $x, 1) - ord('@') + 128);
			} elsif ($x =~ /^i([Bbdru])/) {
				$x = IRSSI_ESCAPE . $irssi{$1};
			} elsif ($x =~ /^i\{(\d*)(?:,(\d+))?\}\z/) {
				my $fg = length $1 ? chr($1 + ord '0') : IRSSI_COLOR_NOCHANGE;
				my $bg = defined $2 ? chr($2 + ord '0') : IRSSI_COLOR_NOCHANGE;
				$x = IRSSI_ESCAPE . $fg . $bg;
			} elsif ($x =~ /^i\{([nbgcrmywNBGCRMYW])(?:,([nbgcrmywNBGCRMYW]))?\}\z/) {
				my $fg = chr($color{$1} + ord '0');
				my $bg = $2 ? chr($color{$2} + ord '0') : IRSSI_COLOR_NOCHANGE;
				$x = IRSSI_ESCAPE . $fg . $bg;
			} elsif ($x =~ /^i\{,([nbgcrmywNBGCRMYW])\}\z/) {
				$x = IRSSI_ESCAPE . IRSSI_COLOR_NOCHANGE . chr($color{$1} + ord '0');
			} elsif ($x =~ /^N\{([^}]*)\}\z/) {
				my $point = $1;
				$x = charnames::vianame(uc $point);
				$x = defined $x ? chr $x : qq(\x{fffd}); # charnames::charnames($point);
				utf8::encode $x;
			} elsif (exists $tr{$x}) {
				$x = $tr{$x};
			}
			$x
		"eg;
		$data =~ s/([\r\n\0])/$pretty{$1}/g;
		($witem || $server)->command($data);
	}
);
