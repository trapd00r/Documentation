use warnings;
use strict;

use Irssi ();

our $VERSION = '0.03';

our %IRSSI = (
	authors => 'mauke',
	name => 'hilight-umodemsg',
);

sub esc {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	$s
}

Irssi::theme_register [
	umode_g_notify => '{hilight $0} $1 $2',
];

Irssi::signal_add 'event 718' => sub {
	my ($server, $data) = @_;
	my $window = $server->window_find_item('(status)') or return;
	my $tail = '';
	$data =~ s/ :(.*)/$tail = $1; ''/e;
	my ($self, $nick, $address) = split / /, $data;
	$window->printformat(MSGLEVEL_CRAP | MSGLEVEL_HILIGHT, 'umode_g_notify', $nick, $address, $tail);
};
