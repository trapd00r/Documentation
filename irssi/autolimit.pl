use warnings;
use strict;

use Irssi ();

our $VERSION = '0.06';

our %IRSSI = (
	authors => 'mauke',
	name => 'autolimit',
);

# |                 .          |           :
# |                 cur        |           limit
# |                            \-----------/
# |                             min_delta  |
# \----------------------------------------/
#  (max_delta)                 |
# |                            |
# \-------------/\-------------/
#  comfort_zone   comfort_zone

Irssi::settings_add_str($IRSSI{name}, autolimit_channels => '');
Irssi::settings_add_time($IRSSI{name}, autolimit_interval => '5m');
Irssi::settings_add_int($IRSSI{name}, autolimit_min_delta => 3);
Irssi::settings_add_int($IRSSI{name}, autolimit_comfort_zone => 3);

sub wtf {
	return;
	my $s = join '', "[$IRSSI{name}] ", @_;
	$s =~ s/%/%%/g;
	Irssi::print $s;
}

our $checked = 0;
our %limits;

sub check_limit {
	#wtf "check_limit()";
	my $comfort_zone = Irssi::settings_get_int('autolimit_comfort_zone');
	my $min_delta = Irssi::settings_get_int('autolimit_min_delta');
	my @chanspec = split ' ', Irssi::settings_get_str('autolimit_channels');

	for my $chanspec (@chanspec) {
		my ($net, $channame) = split m{/}, $chanspec, 2;
		#wtf "[$chanspec] -> [$net] [$channame]";
		my $server = Irssi::server_find_chatnet($net) or wtf("!$net"), next;
		my $channel = $server->channel_find($channame) or wtf("!$channame"), next;
		$channel->{names_got} or wtf("!names_got"), next;
		$channel->{chanop} or wtf("!chanop"), next;

		my $saved = $limits{lc $chanspec};
		my $lim = $channel->{limit};
		if (!$lim) {
			if (!$saved) {
				wtf("!limit");
				next;
			}
			wtf("?desync $saved");
			$lim = $saved;
		}

		my $cur = () = $channel->nicks;

		my $new_lim = $cur + $comfort_zone + $min_delta;
		if (abs($new_lim - $lim) <= $comfort_zone) {
			wtf "$net $channame: $cur+$comfort_zone+$min_delta =( $lim )";
			next;
		}

		$channel->command("mode $channame +l $new_lim");
	}

	$checked = time;
	Irssi::timeout_add_once(
		Irssi::settings_get_time('autolimit_interval'),
		\&check_limit,
		undef
	);
}

Irssi::signal_add(
	'channel mode changed' => sub {
		my ($channel, $nick) = @_;
		my $server = $channel->{server};
		my $net = $server->{chatnet};
		my $channame = $channel->{name};
		my $chanspec = lc "$net/$channame";
		$limits{$chanspec} = $channel->{limit};
	}
);

Irssi::timeout_add_once(
	Irssi::settings_get_time('autolimit_interval'),
	\&check_limit,
	undef
);
