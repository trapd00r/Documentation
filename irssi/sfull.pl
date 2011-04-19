use warnings;
use strict;

use Irssi ();

our $VERSION = '0.02';
our %IRSSI = (
	name => 'sfull',
	authors => 'Juerd, mauke',
);

Irssi::command_bind sfull => sub {
	my ($data, $server, $window) = @_;
	utf8::decode($data);
	$data =~ s/([\x21-\x7e])/chr 0xfee0 + ord $1/ge;
	utf8::encode($data);
	$window->command("say $data")
};
