use warnings;
use strict;
use Irssi ();

our $VERSION = '0.09';
our %IRSSI = (
	authors => 'mauke',
	name => 'unip',
);

use 5.008;
use Encode qw/decode encode_utf8/;
use Unicode::UCD 'charinfo';

sub speng {
	my $x = shift;

	$x =~ /^0[0-7]+\z/ and return oct $x;

	$x =~ /^(?:[Uu]\+|0[Xx])([[:xdigit:]]+)\z/ || (
		length($x) > 1 && $x =~ /^([[:xdigit:]]*[A-Fa-f][[:xdigit:]]*)\z/
	) and return hex $1;

	$x =~ /^[0-9]+\z/ and return $x;

	return map ord, split //, $x
}

sub unip {
	my @pieces = @_;
	my @out;
	for (@pieces) {
		my $chr = chr;
		my $utf8 = join ' ', unpack '(H2)*', encode_utf8 $chr;
		my $x;
		unless ($x = charinfo $_) {
			push @out, sprintf "U+%X (%s): no match found", $_, $utf8;
			next;
		}
		push @out, "U+$x->{code} ($utf8): $x->{name} [$chr]";
	}

	@out
}

sub blort {
	my $x = shift;
	utf8::decode $x;
	my $r = join '; ', unip map speng($_), split ' ', $x;
	utf8::upgrade $r;
	$r
}

Irssi::command_bind(
	unip => sub {
		my ($data, $server, $witem) = @_;
		Irssi::command("echo " . blort $data);
	},
);
Irssi::command_bind(
	sunip => sub {
		my ($data, $server, $witem) = @_;
		$witem->command("say " . blort $data);
	},
);
