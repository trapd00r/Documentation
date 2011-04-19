use warnings;
use strict;

use Irssi ();

our $VERSION = '0.05';

our %IRSSI = (
	authors => 'mauke',
	name => 'dcc-zero',
);

sub esc {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	$s
}

Irssi::signal_add_first 'dcc request' => sub {
	my ($dcc, $addr) = @_;
	$dcc->{type} eq 'GET' && $dcc->{orig_type} eq 'SEND' or return;

	my $server = $dcc->{server};
	my $filename = $dcc->{arg};
	my $filesize = $dcc->{size};
	my $target = $dcc->{target};
	my $port = $dcc->{port};
	my $nick = $dcc->{nick};
	my $source = $dcc->{addr};

	if ($port == 0 && $source eq '0.0.0.0') {
		# yeah, no
		Irssi::signal_stop;
		print esc "... dropping send($filename) from $nick to $target";
		$server->command("dcc close get $nick");

		if (
			$server->{chatnet} eq 'freenode' &&
			(
				$target eq '#perl' ||
				$target eq '#haskell'
			) &&
			(my $chan = $server->channel_find($target))
		) {
			$chan->command("knockout $nick");
		}

		return;
	}
};
