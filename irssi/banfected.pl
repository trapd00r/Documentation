use warnings;
use strict;

use Irssi ();

use Dir::Self;
use lib __DIR__ . "/lib";

use again UtilIrssi => qw(esc later);
use again 'Data::Munge' => qw(byval);

our $VERSION = '0.02';
our %IRSSI = (
	authors => 'mauke',
	name => 'banfected',
);

my %antisign = (
	'+' => '-',
	'-' => '+',
);

my %normalize = (
	'ascii'   => sub { byval { tr[A-Z][a-z] } $_[0] },
	'rfc1459' => sub { byval { tr[A-Z\[\]\\^][a-z{}|~] } $_[0] },
	'strict-rfc1459' => sub { byval { tr[A-Z\[\]\\][a-z{}|] } $_[0] },
);

sub report_on {
	my ($channel, $protos) = @_;
	my $channame = $channel->{name};
	my $server = $channel->{server};
	my @nicks = $channel->nicks;
	for my $proto (@$protos) {
		my ($sign, $char, $mask) = @$proto;
		#Irssi::print esc "[$sign $char $mask]?";
		if ($mask =~ /^\$/) {
			next;  # XXX?
		}
		my @affected = map "$_->{nick}!$_->{host}", grep $server->mask_match_address($mask, $_->{nick}, $_->{host}), @nicks or next;
		later {
			$server->print($channame, "%K[${\esc qq($sign$char $mask)}]%n ${\esc qq(@affected)}", MSGLEVEL_CLIENTCRAP);
		};
	}
}

Irssi::signal_add 'message irc mode' => sub {
	my ($server, $channame, $nickname, $addr, $mode) = @_;
	my $channel = $server->channel_find($channame) or return;

	my $casemapping = $server->isupport('CASEMAPPING') || 'rfc1459';
	my $norm = $normalize{lc $casemapping} || $normalize{rfc1459};
	
	my $chanmodes = $server->isupport('CHANMODES') || 'b,k,l,psitnm';
	my ($group_a, $group_b, $group_c, $group_d) = split /,/, $chanmodes;
	
	my $prefix = $server->isupport('PREFIX') || '(ov)@+';
	if ($prefix =~ /^\(([a-zA-Z0-9]+)\)/) {
		$group_b .= $prefix;
	}
	
	my %seen;
	my $order = 0;
	
	my ($set, @args) = split ' ', $mode;

	while () {
		if ($set =~ s/^([+-])([a-zA-Z0-9]+)//) {
			my ($sign, $chars) = ($1, $2);
			for my $char (split //, $chars) {
				if ('bq' =~ /\Q$char/ && $group_a =~ /\Q$char/) {
					my $arg = shift @args;
					my $narg = $norm->($arg);
					my $key = "$antisign{$sign}$char $narg";
					if (exists $seen{$key}) {
						delete $seen{$key};
					} else {
						$seen{$key} = [$order++, $sign, $char, $arg]
					}
				} elsif (($group_a . $group_b . ($sign eq '+' ? $group_c : '')) =~ /\Q$char/) {
					shift @args;
				}
			}
		} else {
			if (length $set) {
				Irssi::print esc "$IRSSI{name}: unrecognized mode: $set";
			}
			last;
		}
	}

	report_on $channel, [map [@$_[1, 2, 3]], sort {$a->[0] <=> $b->[0]} values %seen];
};
