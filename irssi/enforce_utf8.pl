use warnings;
use strict;

use Irssi ();
use Encode;

our $VERSION = '0.04';

our %IRSSI = (
	authors => 'mauke',
	name => 'enforce_utf8',
);

sub later (&) {
	my ($f) = @_;
	Irssi::timeout_add_once 10, $f, undef;
}

sub utf8_check {
	my ($str) = @_;
	$str =~ /[^[:ascii:]]/ or return 1;
	$str = eval { decode 'utf-8', $str, Encode::FB_CROAK };
	defined $str or return 0;
	$str =~ /[^\x00-\xff]/ and return 1;
	$str = eval { decode 'shiftjis', $str, Encode::FB_CROAK };
	defined $str and return 0;
	1
}

Irssi::signal_add 'event privmsg' => sub {
	my ($server, $args, $sender_nick, $sender_address) = @_;
	(my $msg = $args) =~ s/^(\S+) +:?// or return;
	my $target = $1;
	$server->{chatnet} eq 'rizon' and $target eq '#shameimaru' or return; # XXX
	my $chan = $server->channel_find($target) or return;
	my $self = $chan->nick_find($server->{nick}) or return;
	$self->{prefixes} =~ /[\@&~]/ or return;
	check_utf8 $msg and return;
	later {
		$server->command("msg $target /kick $sender_nick bzzzt");
	};
};
