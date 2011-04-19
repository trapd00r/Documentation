use warnings;
use strict;

our $VERSION = '0.08';
our %IRSSI = (
	authors => 'mauke',
	name => 'splitmsg',
);

#use Dir::Self; use lib __DIR__ . "/lib";
#use UtilIrssi qw(esc);

Irssi::settings_add_int $IRSSI{name}, 'splitmsg_msgmax', 400;
my $msgmax = Irssi::settings_get_int 'splitmsg_msgmax';

Irssi::signal_add 'setup changed' => sub {
	$msgmax = Irssi::settings_get_int 'splitmsg_msgmax';
};

Irssi::signal_add_first
	'server sendmsg' => sub {
		my ($server, $target, $msg, $flag) = @_;
		my $fixed = length ":$server->{nick}!$server->{userhost} PRIVMSG $target :\015\012";
		$fixed >= $msgmax and return;
		$fixed + length($msg) <= $msgmax and return;
		#Irssi::signal_stop();
		my $lim = $msgmax - $fixed;
		my $split = $lim;
		my $min = int($lim / 2);
		my $uni = $msg;
		utf8::decode $uni;
		if (bytes::length($uni) != length($uni)) {
			my $p = length $uni;
			while (
				$p > 0 && (
					substr($uni, $p, 1) =~ /^\S/ ||
					bytes::length(substr $uni, 0, $p) > $lim
				)
			) {
				--$p;
			}
			if ($p < 1) {
				$p = length $uni;
				while (
					$p > 0 &&
					bytes::length(substr $uni, 0, $p) > $lim
				) {
					--$p;
				}
			}
			if ($p > 0) {
				$split = bytes::length substr $uni, 0, $p;
			}
		} elsif ($msg =~ /^.{$min,$lim}(?!\S)/) {
			$split = $+[0];
		}
		my $fst = substr $msg, 0, $split, '';
		#Irssi::print esc "[split $split] [$fst] [$msg]";
		#Irssi::signal_emit('server sendmsg' => $server, $target, $fst, $flag);
		Irssi::signal_continue($server, $target, $fst, $flag);
		Irssi::signal_emit('server sendmsg' => $server, $target, $msg, $flag);
	}
;
