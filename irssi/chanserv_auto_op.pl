use warnings;
use strict;

use Irssi ();

use Dir::Self;
use lib __DIR__ . '/lib';

use again UtilIrssi => qw(esc timer_add_once on_settings_change);

our $VERSION = '0.26';
our %IRSSI = (
	authors => 'mauke',
	name => 'chanserv_auto_op',
);

use constant {
	ZUPDOG => 0,
	REQUESTING_OPS => 1,
	LINGERING => 2,
};

sub fix (&) {
	my $f = shift;
	sub { $f->(&fix($f), @_) }
}

sub itime () { time * 1000 }

Irssi::settings_add_str $IRSSI{name}, "$IRSSI{name}_channels", '';
Irssi::settings_add_time $IRSSI{name}, "$IRSSI{name}_linger", '2m';
Irssi::settings_add_time $IRSSI{name}, "$IRSSI{name}_wait", '10s';

our %channels;
our $linger;
our $wait;

on_settings_change {
	%channels = ();
	@channels{map lc, split ' ', Irssi::settings_get_str "$IRSSI{name}_channels"} = ();
	$linger = Irssi::settings_get_time "$IRSSI{name}_linger";
	$wait = Irssi::settings_get_time "$IRSSI{name}_wait";
};

our %pending;

sub hook_op_signal {
	my ($sig, $win) = @_;

	Irssi::signal_add_first $sig => sub {
		my ($server, $channel) = $win->(@_) or return;
		$channel->{type} eq 'CHANNEL' or return;
		my $name = lc "$server->{tag}/$channel->{name}";
		exists $channels{$name} or return;

		my $pendant = $pending{$name} ||= {state => ZUPDOG};
		
		if ($channel->{chanop}) {
			if ($pendant->{state} == REQUESTING_OPS) {
				warn "[$IRSSI{name}] internal error: $name: requesting ops while already opped\n";
			} elsif ($pendant->{state} == LINGERING) {
				# prolong suffering
				$pendant->{limit} = itime + $linger;
			}
			return;
		}

		Irssi::signal_stop;

		if ($pendant->{state} == LINGERING) {
			Irssi::timeout_remove delete $pendant->{timer};
			$pendant->{state} = ZUPDOG;
		}
		
		push @{$pendant->{signals}}, [$sig, @_];
		if ($pendant->{state} != REQUESTING_OPS) {
			$pendant->{state} = REQUESTING_OPS;
			$server->command("^msg ChanServ op $channel->{name}");
			$pendant->{timer} = timer_add_once $wait, sub {
				delete $pending{$name};
				print esc "[$IRSSI{name}] couldn't get ops in $channel->{name}";
			};
		}
	};
}

sub hook_op_cmd {
	my ($cmd, $win) = @_;
	hook_op_signal "command $cmd" => sub {
		my ($args, $server, $witem) = @_;
		my $channel = $win->(@_);
		$channel ? ($server, $channel) : ()
	};
}

Irssi::signal_add_last 'nick mode changed' => sub {
	my ($channel, $nick, $setby, $mode, $type) = @_;
	#print esc "[MODE] $channel->{name} $nick->{nick} $setby $mode $type";
	
	$mode eq '@' or return;
	
	my $server = $channel->{server};
	my $srv_tag = $server->{tag};
	my $channame = $channel->{name};
	my $name = lc "$srv_tag/$channame";
	
	my $pendant = $pending{$name} or return;
	$pendant->{state} == ZUPDOG and return;

	#print esc "[STATE] $channel->{name} = $pendant->{state}";
	
	if ($pendant->{state} == LINGERING && !$channel->{chanop}) {
		Irssi::timeout_remove delete $pendant->{timer};
		$pendant->{state} = ZUPDOG;
		return;
	}

	if ($pendant->{state} == REQUESTING_OPS && $channel->{chanop}) {
		# paydirt
		Irssi::timeout_remove delete $pendant->{timer};
		$pendant->{state} = LINGERING;
		$pendant->{limit} = itime + $linger;
		$pendant->{timer} = timer_add_once
			$linger,
			fix {
				my ($self) = @_;
				my $pendant = $pending{$name};
				my $d = $pendant->{limit} - itime;
				if ($d >= 10) {
					timer_add_once $d, $self;
					return;
				}
				delete $pending{$name};
				my $server = Irssi::server_find_tag($srv_tag) or return;
				my $channel = $server->channel_find($channame) or return;
				$channel->{chanop} or return;
				$channel->command("deop $server->{nick}");
			},
		;
		
		&Irssi::signal_emit(@$_) for @{delete $pendant->{signals}};
	}
};

hook_op_signal 'knockout ban remove' => sub {
	my ($chan, $ban) = @_;
	$chan->{server}, $chan
};

hook_op_cmd 'ban' => sub {
	my ($args, $server, $witem) = @_;
	$args =~ /^\s*(?:([#&!]\S+)\s*)?\S/ && ($1 ? $server->channel_find($1) : $witem)
};

hook_op_cmd 'kick' => sub {
	my ($args, $server, $witem) = @_;
	$args =~ /^\s*([#&!]\S+)/ ? $server->channel_find($1) : $witem
};

hook_op_cmd 'invite' => sub {
	my ($args, $server, $witem) = @_;
	$args =~ /^\s*\S+\s+([#&!]\S+)/ ? $server->channel_find($1) : $witem
};

hook_op_cmd 'topic' => sub {
	my ($args, $server, $witem) = @_;
	$args =~ /^\s*(-delete(?!\S))?\s*([#&!]\S+(?!\S))?\s*(\S)?/ or return;
	$1 || defined $3 or return;
	my $channel = $2 ? $server->channel_find($2) : $witem;
	$channel->{mode} =~ /^[^ t]*t/ or return;
	$channel
};

hook_op_cmd 'mode' => sub {
	my ($args, $server, $witem) = @_;
	$args =~ /^\s*(?:([#&!]\S+)\s*)?[+-](?:\S*[cegimnpQrRstz]|\S+\s+\S)/ && ($1 ? $server->channel_find($1) : $witem)
};

hook_op_cmd 'quote' => sub {
	my ($args, $server, $witem) = @_;
	$args =~ /^\s*REMOVE\s+([#&!]\S+)/ && $server->channel_find($1)
};

for my $blargh (qw{op deop voice devoice unban}) {
	hook_op_cmd $blargh => sub { $_[2] };
}
