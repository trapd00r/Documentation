use warnings;
use strict;

use Irssi ();

our $VERSION = '0.16';

our %IRSSI = (
	authors => 'mauke',
	name => 'autovoice',
);

Irssi::settings_add_str($IRSSI{name},  "$IRSSI{name}_channels" => '');
Irssi::settings_add_time($IRSSI{name}, "$IRSSI{name}_timeout" => '6h');
Irssi::settings_add_time($IRSSI{name}, "$IRSSI{name}_fixed_delay" => '0s');
Irssi::settings_add_time($IRSSI{name}, "$IRSSI{name}_delay" => '5s');

our %blacklist;
our %pending;
our $verbose;

sub esc {
	my ($s) = @_;
	$s =~ s/%/%%/g;
	$s
}

sub flog {
	$verbose or return;
	Irssi::print(esc("[$IRSSI{name}] @_"), Irssi::MSGLEVEL_CLIENTNOTICE | Irssi::MSGLEVEL_NO_ACT);
}

sub fudge {
	my ($x) = @_;
	$x / 2 + ($x > 0 ? rand $x : 0)
}

sub timeout_once {
	my ($delay, $func) = @_;
	$delay < 10 and $delay = 10;
	Irssi::timeout_add_once($delay, $func, undef)
}

sub mk_fullname {
	my ($net, $channame) = @_;
	lc "$net/$channame"
}

sub is_watched {
	my ($fullname) = @_;
	my $watched = lc Irssi::settings_get_str("$IRSSI{name}_channels");
	$watched =~ /(?<!\S)\Q$fullname\E(?!\S)/
}

sub mk_fakeaddr {
	my ($nick, $addr) = @_;
	$nick = lc $nick;
	(my $fakeaddr = $addr) =~ s/^[^\@]*/$nick/;
	$fakeaddr
}

sub unblacklist {
	my ($context, $nick, $addr) = @_;
	flog "unblacklist($context, $nick, $addr)";
	my $fakeaddr = mk_fakeaddr $nick, $addr;
	delete $blacklist{$context, $_} for $addr, $fakeaddr;
}

sub blacklist {
	my ($context, $nick, $addr) = @_;
	my $fakeaddr = mk_fakeaddr $nick, $addr;
	flog "blacklist($context, $nick, $addr)";

	$blacklist{$context, $fakeaddr} = $blacklist{$context, $addr} = [
		timeout_once(
			Irssi::settings_get_time("$IRSSI{name}_timeout"),
			sub {
				unblacklist $context, $nick, $addr;
			},
		),
		time,
	];
}

sub blacklisted {
	my ($context, $nick, $addr) = @_;
	my $fakeaddr = mk_fakeaddr $nick, $addr;
	$blacklist{$context, $addr} || $blacklist{$context, $fakeaddr}
}

sub later_voice {
	my ($tag, $channame, $nick) = @_;
	my $target = \$pending{$tag, $channame};
	if (my $list = $$target) {
		$list->{$nick} = undef;
	} else {
		$$target = {$nick => undef};
		timeout_once(
			Irssi::settings_get_time("$IRSSI{name}_fixed_delay") + fudge(Irssi::settings_get_time("$IRSSI{name}_delay")),
			sub {
				my $list = delete $pending{$tag, $channame};
				my $server = Irssi::server_find_tag($tag) or return;
				my $channel = $server->channel_find($channame) or return;
				$channel->{chanop} or return;
				my $fullname = mk_fullname $server->{chatnet}, $channame;
				my @nicks = grep {
					my $user = $channel->nick_find($_);
					$user && !$user->{voice} && !blacklisted($fullname, $nick, lc $user->{host})
				} keys %$list or return;
				$channel->command("voice @nicks");
			}
		);
	}
}

sub someone_left {
	my ($server, $channame, $nick) = @_;
	my $channel;
	if (ref $channame) {
		$channel = $channame;
		$channame = $channel->{name};
	} else {
		$channel = $server->channel_find($channame) or return;
	}
	$channel->{mode} =~ /^\S*m/ or return;
	my $fullname = mk_fullname $server->{chatnet}, $channame;
	is_watched $fullname or return;
	my $user = $channel->nick_find($nick) or return;
	my $addr = lc $user->{host};
	#if (my $entry = $blacklist{$fullname, $addr}) {
	if (my $entry = blacklisted $fullname, $nick, $addr) {
		Irssi::timeout_remove($entry->[0]);
	}
	if ($user->{voice} || $user->{op} || $user->{halfop}) {
		unblacklist $fullname, $nick, $addr;
		#delete $blacklist{$fullname, $addr};
		return;
	}
	blacklist $fullname, $nick, $addr;
}

Irssi::signal_add(
	'nick mode changed' => sub {
		my ($channel, $user, $setby, $mode, $type) = @_;
		$mode eq '+' or return;
		$type eq '+' || $type eq '-' or return;
		my $server = $channel->{server} or return;
		my $channame = $channel->{name};
		my $fullname = mk_fullname $server->{chatnet}, $channame;
		is_watched $fullname or return;
		my $addr = lc $user->{host};
		my $nick = $user->{nick};
		# if (my $entry = $blacklist{$fullname, $addr}) {
		if (my $entry = blacklisted $fullname, $nick, $addr) {
			Irssi::timeout_remove($entry->[0]);
		}
		if ($type eq '+') {
			unblacklist $fullname, $nick, $addr;
			# delete $blacklist{$fullname, $addr};
			return;
		}
		blacklist $fullname, $nick, $addr;
	}
);

Irssi::signal_add(
	'message nick',
	sub {
		my ($server, $newnick, $oldnick, $address) = @_;
		my $tag = $server->{tag};
		for my $channel ($server->channels) {
			my $channame = lc $channel->{name};
			my $list = $pending{$tag, $channame} or next;
			exists $list->{$oldnick} or next;
			$list->{$newnick} = delete $list->{$oldnick};
		}
	}
);

Irssi::signal_add(
	'message join',
	sub {
		my ($server, $channame, $nick, $addr) = @_;
		my $channel = $server->channel_find($channame) or return;
		$channel->{chanop} or return;
		$channel->{mode} =~ /^\S*m/ or return;
		$channame = lc $channame;
		my $fullname = mk_fullname $server->{chatnet}, $channame;
		is_watched $fullname or return;
		$addr = lc $addr;
		blacklisted $fullname, $nick, $addr and return;
		# $blacklist{$fullname, $addr} and return;
		later_voice $server->{tag}, $channame, $nick;
	}
);

Irssi::signal_add('message part' => \&someone_left);
Irssi::signal_add('message kick' => \&someone_left);
Irssi::signal_add(
	'message quit',
	sub {
		my ($server, $nick, $addr, $reason) = @_;
		for my $channel ($server->channels) {
			someone_left($server, $channel, $nick);
		}
	}
);
