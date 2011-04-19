use warnings;
use strict;

our $VERSION = '0.05';
our %IRSSI = (
	authors => 'mauke',
	name => 'channotice',
);

use Irssi qw(signal_add_first signal_stop MSGLEVEL_NOTICES);

signal_add_first 'message irc notice' => sub {
	my ($server, $msg, $nick, $address, $target) = @_;
	$nick and $address or return;
	$server->mask_match_address('ChanServ!ChanServ@services.', $nick, $address) or return;
	$msg =~ s/^\[([^\s\]]+)\] // or return;
	my $chan = $1;
	$server->channel_find($chan) or return;

	s/%/%%/ for $msg, $nick, $address;

	signal_stop;
	$server->print($chan, "%K-%M$nick%K(%m$address%K)%K-%n $msg", MSGLEVEL_NOTICES);
};
