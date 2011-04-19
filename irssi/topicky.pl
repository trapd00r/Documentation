use warnings;
use strict;

use Irssi ();

our $VERSION = '0.081';
our %IRSSI = (
	name => 'topicky',
	authors => 'mauke',
);

use Algorithm::Diff qw(sdiff);

sub esc {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	$s
}

sub rtrim {
	my ($s) = @_;
	$s =~ s/\s+\z//;
	$s
}

Irssi::settings_add_str $IRSSI{name}, "$IRSSI{name}_chunks", '\s+|\w+|[^\s\w]+';

our $chunk_re;

sub refresh_settings {
	my $x = Irssi::settings_get_str "$IRSSI{name}_chunks";
	$chunk_re = qr/(?:$x)|./s;
}
refresh_settings;

Irssi::signal_add 'setup changed' => \&refresh_settings;

sub hunks {
	my ($str) = @_;
	my @r;
	while ($str =~ /$chunk_re/g) {
		push @r, substr $str, $-[0], $+[0] - $-[0];
	}
	\@r
}

our %format = (
	'u' => ['', '', '', ''],
	'c' => ['%y', '%n', '%y', '%n'],
	'+' => ['', '', '%g', '%n'],
	'-' => ['%r', '%n', '', ''],
);

Irssi::signal_add_first 'message topic' => sub {
	my ($server, $channame, $newtopic, $nick, $address) = @_;
	my $channel = $server->channel_find($channame) or return;
	my $oldtopic = $channel->{topic};
	$oldtopic && $oldtopic =~ /\S/ && rtrim($oldtopic) ne rtrim($newtopic) or return;

	my $diff = sdiff hunks($oldtopic), hunks($newtopic);

	my $dp_old = '';
	my $dp_new = '';
	for my $hunk (@$diff) {
		my ($t, $x, $y) = @$hunk;
		my $fmt = $format{$t};
		$dp_old .= $fmt->[0] . esc($x) . $fmt->[1];
		$dp_new .= $fmt->[2] . esc($y) . $fmt->[3];
	}

	Irssi::signal_stop;

	$server->print($channame, ".topic %W${\esc $nick}%n %W${\esc $channame}%n:", MSGLEVEL_TOPICS);
	$server->print($channame, "%K<<%n $dp_old", MSGLEVEL_TOPICS);
	$server->print($channame, "%K>>%n $dp_new", MSGLEVEL_TOPICS);
};
