use warnings;
use strict;

use Irssi ();

our $VERSION = '0.02';

our %IRSSI = (
	authors => 'mauke',
	name => 'if_is_op',
);

Irssi::command_bind if_is_op_in => sub {
	my ($data, $server, $witem) = @_;

	$data =~ s/^\s*(\S+)\s+(\S+)\s+// or do {
		Irssi::print "if_is_op: syntax error: $data";
		return;
	};
	my $channame = $1;
	my $nickname = $2;

	$server or return;
	my $chan = $server->channel_find($channame) or return;
	my $nick = $chan->nick_find($nickname) or return;
	$nick->{op} or return;

	$chan->command($data);
};
