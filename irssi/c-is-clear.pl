use warnings;
use strict;

use Irssi ();

our $VERSION = '0.02';

our %IRSSI = (
	authors => 'mauke',
	name => 'c-is-clear',
);

Irssi::signal_add_first 'send text' => sub {
	my ($line, $server, $witem) = @_;
	$line eq 'c' or return;
	Irssi::signal_stop;
	$witem->command('clear');
};

