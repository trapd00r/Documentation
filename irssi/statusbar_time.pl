use warnings;
use strict;

use Irssi ();

use POSIX qw(strftime);

use Dir::Self;
use lib __DIR__ . '/lib';

our $VERSION = '0.02';

our %IRSSI = (
	authors => 'mauke',
	name => 'statusbar_time',
);

use again 'IrssiX::Util' => qw(timer_add);
use again 'IrssiX::Settings' => (
	'format' => '%H:%M',
);

sub draw_item {
	my ($item, $size_only, $txt) = @_;

	$item->default_handler($size_only, '', $txt, 1);
}

sub get_time2 {
	strftime $format, localtime
}

sub draw_time2 {
	my ($item, $size_only) = @_;

	draw_item $item, $size_only, get_time2;
}

Irssi::statusbar_item_register 'time2', '{sb $0-}', 'draw_time2';
Irssi::statusbars_recreate_items;

timer_add 1_000, do {
	my $prev = '';
	sub {
		my $txt = get_time2;
		if ($txt ne $prev) {
			$prev = $txt;
			Irssi::statusbar_items_redraw 'time2';
		}
	}
};
