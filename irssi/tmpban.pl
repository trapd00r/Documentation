use warnings;
use strict;

use Irssi ();

our $VERSION = '0.071';
our %IRSSI = (
	authors => 'mauke',
	name => 'tmpban',
);

sub display {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	Irssi::print("$IRSSI{name}: $s");
}

sub beginning {
	my $s = shift;
	if (length $s > 10) {
		substr($s, 7) = '...';
	}
	$s
}

{
	my %units = (
		d => 60 * 60 * 24,
		h => 60 * 60,
		m => 60,
		s => 1,
	);

	sub scale {
		$_[0] * $units{$_[1]};
	}
}

sub time2buttsecs {
	my ($spec) = @_;
	my $n = 0;
	while ($spec =~ s/^(\d+)([dhms])//) {
		$n += scale $1, $2;
	}
	$n += $spec if $spec;
	$n
}

sub esc {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	$s
}

Irssi::settings_add_time $IRSSI{name}, "$IRSSI{name}_timeout", '5m';

my $reply_event = "redir $IRSSI{name} whois reply";
my $reply_end = "$IRSSI{name} whois end";
Irssi::signal_register { $reply_end => [] };

our @Queue;

sub do_ban {
	my ($chan, $timeout, $mode, @masks) = @_;
	@masks or return;

	$chan->command("mode +${\($mode x @masks)} @masks");
	defined $timeout and Irssi::timeout_add_once(
		$timeout,
		sub {
			if ($mode eq 'b') {
				my %ban;
				@ban{map $_->{ban}, $chan->bans} = ();
				#display "bans: ", join ' ', keys %ban;
				#display "args: @masks";
				@masks = grep exists $ban{$_}, @masks or return;
			}
			$chan->command("mode -${\($mode x @masks)} @masks");
		},
		undef
	);
}

sub banninate {
	my ($temp, $mode, $data, $server, $witem) = @_;
	$witem && $witem->{type} eq 'CHANNEL' or return display "you're not in a channel";

	my $chan = $server->channel_find($witem->{name}) or return display "can't find $witem->{name} on $server->{chatnet} ($server->{address})";
	#$chan->{chanop} or return display "you're not a channel operator";

	$data =~ s/^\s+//;

	my $timeout;
	if ($data =~ s/^-//) {
		$data =~ s/^(\d+(?:[dhms]\d+)*[dhms]?)\s+// or return display 'invalid timeout at ' . beginning $data;
		$timeout = 1000 * time2buttsecs $1;
	} else {
		$timeout = Irssi::settings_get_time("$IRSSI{name}_timeout");
	}

	my @masks = split ' ', $data;
	unless (@masks) {
		display 'missing ban mask';
		return;
	}

	for my $i (reverse 0 .. $#masks) {
		my $mask = $masks[$i];

		if ($mask !~ /^[\$~]/) {
			if ($server->{chatnet} =~ /^freenode/i && $mask !~ /[!\@]/) {
				push @Queue, {
					servertag => $server->{tag},
					fallback => $chan->ban_get_mask($mask, 0),
					channame => $chan->{name},
					mode => $mode,
					$temp ? (timeout => $timeout) : (),
				};
				$server->redirect_event(
					"whois",
					1,
					$mask,
					0,
					$reply_end,
					{
						"event 330" => $reply_event,
						"" => "event empty",
						"event 318" => $reply_end,
					}
				);
				$server->send_raw("WHOIS :$mask");
				splice @masks, $i, 1;
				next;
			} elsif ($mask !~ /!/) {
				$mask = $chan->ban_get_mask($mask, 0) or do {
					splice @masks, $i, 1;
					next;
				};
			} elsif ($mask !~ /!./) {
				$mask .= '*@*';
			} elsif ($mask !~ /\@/) {
				$mask .= '@*';
			} elsif ($mask !~ /\@./) {
				$mask .= '*';
			}

			$masks[$i] = $mask;
		}
	}

	do_ban $chan, $temp ? $timeout : undef, $mode, @masks;
};

Irssi::signal_add $reply_end => sub {
	my $ctx = shift @Queue or return;
	$ctx->{done} and return;
	my $server = Irssi::server_find_tag($ctx->{servertag}) or return;
	my $chan = $server->channel_find($ctx->{channame}) or return;
	do_ban $chan, $ctx->{timeout}, $ctx->{mode}, $ctx->{fallback};
};

Irssi::signal_add $reply_event => sub {
	my ($server, $args, $sender_nick, $sender_address) = @_;
	my $ctx = $Queue[0] or return;
	my ($me, $nick, $authname, $info) = $args =~ /^([^ ]+) ([^ ]+) ([^ ]+) :(.*)/ or return Irssi::print esc "$IRSSI{name}: ?wtf($args)";
	my $chan = $server->channel_find($ctx->{channame}) or return;
	$ctx->{done} = 1;
	do_ban $chan, $ctx->{timeout}, $ctx->{mode}, '$a:' . $authname;
};

Irssi::command_bind xban => sub { banninate 0, 'b', @_ };
Irssi::command_bind tmpban => sub { banninate 1, 'b', @_ };
Irssi::command_bind mute => sub { banninate 0, 'q', @_ };
Irssi::command_bind tmpmute => sub { banninate 1, 'q', @_ };
