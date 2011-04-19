use warnings;
use strict;

use Irssi ();

our $VERSION = '0.04~';

our %IRSSI = (
	authors => 'mauke',
	name => 'ctcp-encoding',
);

sub enable {
	my ($server) = @_;
	#$server->send_raw("PROXY CTCP ON");
}

Irssi::signal_add 'ctcp msg encoding' => sub {
	my ($server, $args, $nick, $addr, $target) = @_;
	my $charset = Irssi::settings_get_str 'term_charset';
	$charset ||= 'US-ASCII';
	$server->ctcp_send_reply("NOTICE $nick :\cAENCODING $charset\cA");
};

Irssi::signal_add 'server connected' => \&enable;

for my $server (Irssi::servers) {
	enable $server;
}
