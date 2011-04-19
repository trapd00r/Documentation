use warnings;
use strict;

use Irssi ();

our $VERSION = '0.04';
our %IRSSI = (
	authors => 'mauke',
	name => 'latex-complete',
);

use Data::Munge qw(list2re);

our %mappings = (
	'forall' => "\x{2200}",
	'exists' => "\x{2203}",
	'in' => "\x{2208}",
	'ni' => "\x{220b}",
	'empty' => "\x{2205}",
	'prod' => "\x{220f}",
	'sum' => "\x{2211}",
	'le' => "\x{2264}",
	'ge' => "\x{2265}",
	'pm' => "\x{b1}",
	'subset' => "\x{2282}",
	'subseteq' => "\x{2286}",
	'supset' => "\x{2283}",
	'supseteq' => "\x{2287}",
	'setminus' => "\x{2216}",
	'cap' => "\x{2229}",
	'cup' => "\x{222a}",
	'int' => "\x{222b}",
	'therefore' => "\x{2234}",
	'qed' => "\x{220e}",
	'1' => "\x{1d7d9}",
	'N' => "\x{2115}",
	'Z' => "\x{2124}",
	'C' => "\x{2102}",
	'Q' => "\x{211a}",
	'R' => "\x{211d}",
	'E' => "\x{1d53c}",
	'F' => "\x{1d53d}",
	'to' => "\x{2192}",
	'mapsto' => "\x{21a6}",
	'infty' => "\x{221e}",
	'cong' => "\x{2245}",
	':=' => "\x{2254}",
	'=:' => "\x{2255}",
	'ne' => "\x{2260}",
	'approx' => "\x{2248}",
	'perp' => "\x{22a5}",
	'not' => "\x{337}",
	'ldots' => "\x{2026}",
	'cdots' => "\x{22ef}",
	'cdot' => "\x{22c5}",
	'circ' => "\x{25e6}",
	'times' => "\x{d7}",
	'oplus' => "\x{2295}",
	'langle' => "\x{27e8}",
	'rangle' => "\x{27e9}",

	'alpha' => "\x{3b1}",
	'beta' => "\x{3b2}",
	'gamma' => "\x{3b3}",
	'delta' => "\x{3b4}",
	'epsilon' => "\x{3b5}",
	'zeta' => "\x{3b6}",
	'nu' => "\x{3b7}",
	'theta' => "\x{3b8}",
	'iota' => "\x{3b9}",
	'kappa' => "\x{3ba}",
	'lambda' => "\x{3bb}",
	'mu' => "\x{3bc}",
	'nu' => "\x{3bd}",
	'xi' => "\x{3be}",
	'omicron' => "\x{3bf}",
	'pi' => "\x{3c0}",
	'rho' => "\x{3c1}",
	'stigma' => "\x{3c2}",
	'sigma' => "\x{3c3}",
	'tau' => "\x{3c4}",
	'upsilon' => "\x{3c5}",
	'phi' => "\x{3d5}",
	'varphi' => "\x{3c6}",
	'chi' => "\x{3c7}",
	'psi' => "\x{3c8}",
	'omega' => "\x{3c9}",

	'Alpha' => "\x{391}",
	'Beta' => "\x{392}",
	'Gamma' => "\x{393}",
	'Delta' => "\x{394}",
	'Epsilon' => "\x{395}",
	'Zeta' => "\x{396}",
	'Nu' => "\x{397}",
	'Theta' => "\x{398}",
	'Iota' => "\x{399}",
	'Kappa' => "\x{39a}",
	'Lambda' => "\x{39b}",
	'Mu' => "\x{39c}",
	'Nu' => "\x{39d}",
	'Xi' => "\x{39e}",
	'Omicron' => "\x{39f}",
	'Pi' => "\x{3a0}",
	'Rho' => "\x{3a1}",
	'Sigma' => "\x{3a3}",
	'Tau' => "\x{3a4}",
	'Upsilon' => "\x{3a5}",
	'Phi' => "\x{3a6}",
	'Chi' => "\x{3a7}",
	'Psi' => "\x{3a8}",
	'Omega' => "\x{3a9}",
);

our $symbol_re;

sub update_list {
	$symbol_re = list2re keys %mappings;
}

update_list;

sub esc {
	my $s = join '', @_;
	$s =~ s/%/%%/g;
	$s
}

Irssi::signal_add 'complete word' => sub {
	my ($complist, $window, $word, $linestart, $want_space) = @_;
	utf8::decode $word;
	my $whole_line = Irssi::parse_special('$L');
	utf8::decode $whole_line;
	my $pos = Irssi::gui_input_get_pos;
	my $before = substr $whole_line, 0, $pos;
	#utf8::decode $before;
	my $after = substr $whole_line, $pos;
	#utf8::decode $after;
	my $before_part = ($before =~ /([^, ]*)\z/)[0];
	my $after_part = ($after =~ /^([^, ]*)/)[0];
	my $my_word = $before_part . $after_part;
	if ($word ne $my_word) {
		Irssi::print esc "internal error: [${\sprintf '%vd',$word}] ne [${\sprintf '%vd',$my_word}] nee [${\sprintf'%vd %vd',$before,$after}]";
		return;
	}
	$before_part =~ s/\\($symbol_re)\z/$mappings{$1}/ or return;
	$$want_space = 0;
	push @$complist, $before_part . $after_part, $word;
	#my ($prefix, $symbol, $suffix) = $word =~ /^(.*)\\($symbol_re)(.*)\z/s or return;
	#$$want_space = 0;
	#push @$complist, map { $prefix . $_ . $suffix } $mappings{$symbol}, "\\$symbol";
};
