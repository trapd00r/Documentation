use warnings;
use strict;

use Irssi ();

our $VERSION = '0.03';
our %IRSSI = (
	authors => 'mauke',
	name => 'tabmincompl',
);

Irssi::settings_add_int $IRSSI{name}, 'tabmincompl_minchars' => 2;
Irssi::settings_add_str $IRSSI{name}, 'tabmincompl_networks' => '';

our ($minchars, %networks);

sub update_settings {
	$minchars = Irssi::settings_get_int 'tabmincompl_minchars';
	%networks = ();
	@networks{map lc, split ' ', Irssi::settings_get_str 'tabmincompl_networks'} = ();
}

update_settings;
Irssi::signal_add 'setup changed' => \&update_settings;

Irssi::signal_add_first 'complete word' => sub {
	my ($complist, $window, $word, $linestart, $want_space) = @_;
	length($word) >= $minchars and return;
	my $server = $window->{active_server} or return;
	exists $networks{lc $server->{chatnet}} or return;
	Irssi::signal_stop;
};
