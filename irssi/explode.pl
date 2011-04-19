use warnings;
use strict;

use Irssi ();

our $VERSION = '0.02';

our %IRSSI = (
	authors => 'mauke',
	name => 'explode',
);


sub later (&) {
	my ($f) = @_;
	Irssi::timeout_add_once(10, $f, undef);
}

Irssi::signal_add 'message irc action' => sub {
	my ($server, $msg, $nick, $addr, $target) = @_;
	$target =~ /^[#&]/ or return;
	my $me = $server->{nick};
	$msg =~ /\Q$me/ or return;
	later {
		$server->command("action $target explodes");
	};
};
