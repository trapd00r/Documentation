use warnings;
use strict;

use Irssi ();
use List::Util 'first';
use URI::Escape 'uri_escape';

our $VERSION = '0.16';
our %IRSSI = (
	name => 'url',
	authors => 'mauke',
);

my $uchar = qr{[[:alnum:]\$\-_.+!*'(),]|%[[:xdigit:]]{2}};
my $hsegpart = qr{$uchar|[;:\@&=~]};
my $hsegment = qr{(?>$hsegpart*)};

my $domainlabel = qr{[[:alnum:]](?>(?:[[:alnum:]-]*[[:alnum:]])?)};
my $toplabel =    qr{[[:alpha:]](?>(?:[[:alnum:]-]*[[:alnum:]])?)};
my $hostname = qr{(?:$domainlabel\.)*$toplabel};
my $digits = qr{(?>\d+)};
my $hostnumber = qr{$digits(?:\.$digits){3}};
my $host = qr{$hostname|$hostnumber};
my $port = $digits;;

my $hostport = qr{$host(?::$port)?};

my $httpurl = qr{
	https?://
	$hostport
	(?:
		/
		$hsegment
		(?>(?:
			/
			$hsegment
		)*)
		(?:
			\?
			(?>
				(?:
					$hsegpart
				|
					/
				)*
			)
		)?
		(?:
			\#
			$hsegment  # XXX?
		)?
	)?
}x;

my $fsegment = qr{(?>(?:$uchar|[?:\@&=])*)};

my $user = qr{(?>(?:$uchar|[;?&=])*)};
my $password = $user;

my $ftpurl = qr{
	ftp://
	(?:
		$user
		(?:
			:
			$password
		)?
		\@
	)?
	$hostport
	(?:
		/
		$fsegment
		(?>(?:
			/
			$fsegment
		)*)
		(?:
			;type=
			[AIDaid]
		)?
	)?
}x;

my $url = qr/$httpurl|$ftpurl/;

sub esc {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	$s
}

Irssi::settings_add_str('url', 'url_browser', 'firefox % >/dev/null &');

Irssi::command_bind(
	url => sub {
		my ($data, $server, $witem) = @_;
		$witem or return;
		my $window = $witem->window or return;
		my $view = $window->view or return;

		my $buf = '';
		for (my $line = $view->get_lines; defined $line; $line = $line->next) {
			$buf .= $line->get_text(0) . "\n";
		}

		my @urls = $buf =~ /$url/g or do {
			$witem->print("no urls found");
			return;
		};
		@urls = reverse @urls;

		my $browser = Irssi::settings_get_str('url_browser');
		
		my @args = split ' ', $data;
		@args or @args = (0);

		for my $arg (@args) {
			my $url;
			if ($arg =~ /^\d+\z/) {
				$url = $urls[$arg];
			} else {
				$arg =~ s/^\\//;
				$url = first { /\Q$arg/ } @urls;
			}

			defined $url or do {
				$witem->print(esc "no match for [$arg]");
				next;
			};
			$url = uri_escape $url, '()~*!,';
			my $cmd = $browser;
			$cmd =~ s/%/\Q$url\E/ or $cmd .= " \Q$url\E";
			#Irssi::print esc "[URL] $cmd";
			system $cmd;
		}
	}
);
