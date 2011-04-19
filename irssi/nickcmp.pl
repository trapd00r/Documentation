use strict;
use warnings;

use Irssi ();

our $VERSION = '0.02';
our %IRSSI = (
	authors => 'mauke',
	name => 'nickcmp',
);

sub esc {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	$s
}

Irssi::command_bind nickcmp => sub {
	my ($args, $server, $witem) = @_;
	my @channels = split ' ', $args or return;

	my %seen;

	for my $channame (@channels) {
		my $chan = $server->channel_find($channame) or do {
			$witem->print(esc "$IRSSI{name}: $channame: no such channel on $server->{chatnet}");
			return;
		};
		for my $nick ($chan->nicks) {
			++$seen{$nick->{nick}};
		}
	}

	my @common = sort grep $seen{$_} == @channels, keys %seen;
	$witem->print(esc "@common");
};
