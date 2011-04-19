use warnings;
use strict;

use Irssi qw(signal_add_first signal_add signal_stop signal_emit command_bind);

our $VERSION = '0.972';
our %IRSSI = (
	authors => 'mauke',
	name => 'spand',
);

use utf8;

use Dir::Self;
use lib __DIR__ . "/lib";

use again UtilIrssi => qw(esc);
use again UniData => [];
use again UtilRun => [];
use again UtilList => qw(list2re);
use again RandWord => qw(randword);
use again 'Digest::MD5' => qw(md5_hex);
use again 'Digest::SHA' => qw(sha1_hex sha256_hex sha512_hex);
use again 'URI::Escape';
use again 'MIME::Base64';
use again 'Unicode::Normalize';
use again 'List::Util' => qw(min);
use again 'Module::CoreList' => [];
use again 'Encode';
use again 'POSIX' => qw(ceil);
use again 'Net::IDN::Encode' => qw(domain_to_ascii domain_to_unicode);

sub fail {
	chomp(my @cpy = @_);
	die \@cpy;
}

sub with (&) { $_[0] }

sub try (&$) {
	my ($body, $handler) = @_;
	my $ret = eval { $body->() };
	if ($@) {
		unless (ref $@) {
			chomp $@;
			$@ = [$@];
		}
		return $handler->($@);
	}
	$ret
}

sub wrcmd {
	my $r = eval { &UtilRun::wrcmd };
	$@ and fail $@;
	$r
}

sub byval (&$) {
	my ($f, $x) = @_;
	local *_ = \$x;
	$f->($x);
	$x
}

sub numcvt {
	my $x = shift;
	$x =~ s/^[Uu]\+/0x/ || $x =~ s/^0o/0/ || $x =~ /^0[xb]/ or $x =~ s/^0+//;
	$x =~ /^0/ ? oct $x : $x
}

{
	my $c_a = do {
		my @canon = (15, 1, 2, 3, 5, 5, 6, 7, 7, 3, 10, 10, 2, 6, 1, 15);
		my $randcolor = sub {
			my $fg = int rand 16;
			my $bg;
			do {
				$bg = int rand 16;
			} while $bg == $fg || $canon[$bg] == $fg;
			[$fg, $bg]
		};

		my $surround = sub {
			"\cC$_[0][0],$_[0][1]$_[1]"
		};

		sub {
			$surround->($randcolor->(), $_[0])
		}
	};

	my $c_b = do {
		my @canon = (0, 1, 2, 3, 4, 5, 6, 15, 0, 1, 2, 3, 4, 5, 6, 15);
		my $randcolor = sub {
			my $fg = int rand 16;
			my $bg;
			do {
				$bg = int rand 16;
			} while $bg == $fg || $canon[$bg] == $fg;
			[map chr($_ + ord '0'), $fg, $bg]
		};

		my $surround = sub {
			"\cD$_[0][0]$_[0][1]$_[1]"
		};

		sub {
			$surround->($randcolor->(), $_[0])
		}
	};

	sub arghcolor {
		my ($str, $flag) = @_;
		($flag ? $c_b : $c_a)->($str)
	}
}

sub my_qx {
	my $s = shift;
	my $r = `$s`;
	$? == -1 and fail "$s: $!";
	$r =~ s/^\s*\n//;
	$r =~ s/\s+\z//;
	$r eq '' && $? and fail "$s: failed:", $? & 127 ? "killed by " . ($? & 127) : $? >> 8;
	my $d = eval { decode "utf8", $r, 1 };
	defined($d) ? $d : $r
}

our $colorcode_re = qr/\cD(?:[\x60-\xff]|[\x01-\x5f]{2})|\cC[0-9]{1,2}(?:,[0-9]{1,2})?|[\cB\cV\c_\cO]/;

our %cmd = (
	amarok => sub {
		wrcmd '', qw(dcop amarok player), (qw(nowPlaying artist title))[min 2, $_[0] || 0]
	},
	ausschreib => sub {
		wrcmd '', 'ausschreib', $_[0]
	},
	b => sub { "\cB$_[0]\cB" },
	b64enc => sub { encode_base64 $_[0], '' },
	b64dec => \&decode_base64,
	c => do {
		my %color = (
			black   => 1,
			blue    => 2,
			green   => 3,
			cyan    => 10,
			red     => 5,
			magenta => 6,
			yellow  => 7,
			white   => 15,
			BLACK   => 14,
			BLUE    => 12,
			GREEN   => 9,
			CYAN    => 11,
			RED     => 4,
			MAGENTA => 13,
			YELLOW  => 8,
			WHITE   => 0,
		);
		$color{none} = '';

		my $core = list2re keys %color;

		sub {
			my $s = shift;
			$s =~ s/^($core),// or fail "c: invalid color code";
			my $fg = $color{$1};
			my $bg = $color{none};
			$s =~ s/^($core),// and $bg = $color{$1};
			$fg || $bg or return $s;
			my $cc = "$fg,$bg";
			$s =~ /^,/ or $cc =~ s/,\z//;
			"\cC$cc$s\cC"
		}
	},
	calc => sub { wrcmd $_[0], 'hax-wcalc' },
	cap => sub {
		my $s = shift;
		$s =~ tr[abcdefghijklmnopqrstuvwxyz]
		        [ᴀʙᴄᴅᴇfɢʜɪᴊᴋʟᴍɴᴏᴘqʀsᴛᴜᴠᴡxʏᴢ];
		        #     ^          ^ ^    ^
		$s
	},
	cdecl => sub { wrcmd $_[0], 'hax-explain' },
	chr => sub { join '', map chr numcvt($_), split ' ', $_[0] },
	colors => sub {
		my $s = shift;
		$s =~ s/(.)/arghcolor $1/ge;
		"$s\cO"
	},
	core => do {
		my $coremoved = Module::CoreList->can('removed_from') || sub {};
		my $vrange = sub {
			my ($s) = @_;
			$s =~ /^5(?:\.[0-9.]+)?\z/
			? do {
				my $t = $s;
				$t =~ /^5\.[0-9]+\z/ and $t =~ s/0+\z//;
				$t =~ /^5\.?\z/ and $t = '5.000';
				$t =~ s{^5\.([6-9]|1[0-9])(?:\.([0-9]{1,2}))?\z}{
					join '', '5.', map sprintf('%03u', $_), $1, $2 || ()
				}e;
				$t
			} : (
				Module::CoreList->first_release($s),
				Module::CoreList->$coremoved($s) || ()
			)
		};
		sub {
			my $s = shift;
			s/^\s+//, s/\s+\z// for $s;
			my ($v, $r) = $vrange->($s);
			$v or return "<not in core: $s>";
			my $d = $Module::CoreList::released{$v} or return "<not found: $v>";
			my $e = $r && $Module::CoreList::released{$r};
			for ($v, $r || ()) {
				if ($_ >= 5.006 && /^([0-9]+)\.([0-9]{1,3})([0-9]{0,3})\z/) {
					$_ = join '.', map 0 + ($_ || 0), $1, $2, $3;
				}
			}
			"$v [$d]" . ($r ? " - $r [$e]" : '')
		}
	},
	def => sub { qq{define "$_[0]"} },
	depdef => sub { qq{depends on your definition of "$_[0]"} },
	dnsip => sub { my_qx "dnsip $_[0]" },
	dnsipname => sub { my_qx "dnsipname $_[0]" },
	dnsname => sub { my_qx "dnsname $_[0]" },
	eval => sub {
		my $s = shift;
		my $r = eval "my \$win = Irssi::active_win(); my \$srv = Irssi::active_server(); my \$witem = \$win->{active}; my \$chan = \$witem && \$witem->{type} eq 'CHANNEL' ? \$witem : undef;\n$s";
		fail $@ if $@;
		defined $r ? $r : ''
	},
	f => sub {
		my $s = shift;
		my $n = $s =~ s/^([0-9]+),// ? $1 : 0;
		my @f = split ' ', $s;
		$n < @f ? $f[$n] : ''
	},
	flip => do {
		my %table = (
			6 => '9',
			a => "\x{250}",
			b => "q",
			c => "\x{254}",
			d => "p",
			e => "\x{1dd}",
			f => "\x{25f}",
			g => "\x{183}",
			h => "\x{265}",
			i => "\x{131}\x{323}",
			j => "\x{27e}",
			k => "\x{29e}",
			l => "\x{5df}",
			m => "\x{26f}",
			n => "u",
			r => "\x{279}",
			t => "\x{287}",
			v => "\x{28c}",
			w => "\x{28d}",
			y => "\x{28e}",
			"." => "\x{2d9}",
			"[" => "]",
			"(" => ")",
			"{" => "}",
			"?" => "\x{bf}",
			"!" => "\x{a1}",
			"'" => ",",
			"<" => ">",
			"_" => "\x{203e}",
			";" => "\x{61b}",
			"\x{203f}" => "\x{2040}",
			"\x{2045}" => "\x{2046}",
			"\x{2234}" => "\x{2235}",
		);
		@table{values %table} = keys %table;
		my $re = list2re keys %table;
		sub {
			my $s = shift;
			$s = lc reverse $s;
			$s =~ s/($re)/$table{$1}/g;
			$s
		}
	},
	fst => sub {
		my $s = shift;
		length $s ? substr $s, 0, 1 : "\x{fffd}"
	},
	full => sub {
		my $s = NFD shift;
		$s =~ s/([\x21-\x7e])/chr(0xfee0 + ord $1)/eg;
		NFC $s
	},
	grep => sub {
		my $data = shift;
		my $pat;
		$data =~ s/^\s*(\S+)\s*/$pat = $1/e or return '';
		my $re = qr/$pat/;
		join ' ', grep /$re/, split ' ', $data
	},
	how => sub { qq{how is that a $_[0] question} },
	i => sub { "\cV$_[0]\cV" },
	ib => sub { "\cDc$_[0]\cDc" },
	iblink => sub { "\cDa$_[0]\cDa" },
	ic => do {
		my %color = (
			none    => -1,
			black   => 0,
			blue    => 1,
			green   => 2,
			cyan    => 3,
			red     => 4,
			magenta => 5,
			yellow  => 6,
			white   => 7,
			BLACK   => 8,
			BLUE    => 9,
			GREEN   => 10,
			CYAN    => 11,
			RED     => 12,
			MAGENTA => 13,
			YELLOW  => 14,
			WHITE   => 15,
		);
		$_ = chr($_ + ord '0') for values %color;

		my $core = list2re keys %color;

		sub {
			my $s = shift;
			$s =~ s/^($core),// or fail "ic: invalid color code";
			my $fg = $color{$1};
			my $bg = $color{none};
			$s =~ s/^($core),// and $bg = $color{$1};
			"\cD$fg$bg$s\cDg"
		}
	},
	icolors => sub {
		my $s = shift;
		$s =~ s/(.)/arghcolor $1, 1/ge;
		"$s\cDg"
	},
	id => sub { $_[0] },
	ii => sub { "\cDd$_[0]\cDd" },
	irainbow => do {
		my @rainbow = map chr($_ + ord '0'), qw(12 6 4 14 10 2 3 11 9 1 5 13);
		sub {
			my $s = shift;
			my $start = rand @rainbow;
			$s =~ s{(.{1,2})}{
				"\cD$rainbow[$start++ % @rainbow]/$1"
			}esg;
			"$s\cDg"
		}
	},
	iu => sub { "\cDb$_[0]\cDb" },
	lc => sub { lc $_[0] },
	length => sub { length $_[0] },
	letter => sub { join '', map chr(ord("a") - 1 + numcvt $_), split ' ', $_[0] },
	mask2nick => sub {
		my $s = shift;
		$s =~ s/!\S*//g;
		$s
	},
	masks => sub {
		my $win = Irssi::active_win;
		my $witem = $win->{active};
		$witem && $witem->{type} eq 'CHANNEL' or return '';
		join ' ', map "$_->{nick}!$_->{host}", $witem->nicks
	},
	matrix => sub {
		my $s = shift;
		my $prefix = $s =~ s/^($colorcode_re+)// ? $1 : '';
		$s =~ s/$colorcode_re+\z//;
		my $len = length $s;
		my $h = ceil sqrt($len) * 8 / 9;
		my $w = ceil $len / $h;
		$s .= ' ' x ($h * $w - $len);
		my @p = $s =~ /.{$h}/sg;
		my $r = '';
		for my $i (0 .. length($p[0]) - 1) {
			my $line = join '  ', map substr($_, $i, 1), @p;
			$r .= "$prefix$line\n";
		}
		$r
	},
	md5 => sub { md5_hex $_[0] },
	mean => sub { qq{what do you mean by "$_[0]"} },
	nicks => sub {
		my $win = Irssi::active_win;
		my $witem = $win->{active};
		$witem && $witem->{type} eq 'CHANNEL' or return '';
		join ' ', map $_->{nick}, $witem->nicks
	},
	ord => sub { ord $_[0] },
	punyenc => sub { domain_to_ascii $_[0] },
	punydec => sub { domain_to_unicode $_[0] },
	Q => sub { quotemeta $_[0] },
	qq => do {
		my %esc = (
			a => "\a",
			b => "\b",
			e => "\e",
			f => "\f",
			n => "\n",
			r => "\r",
			t => "\t",
			v => "\x0b",
		);
		sub {
			my $s = shift;
			$s =~ s<\\(x(?:[[:xdigit:]]{1,2}|\{[[:xdigit:]]+\})|[0-7]{1,3}|c.|.)><
				my $x = $1;
				if ($x =~ /^x\{?([[:xdigit:]]+)/) {
					$x = chr hex $1;
				} elsif ($x =~ /^[0-7]+\z/) {
					$x = chr oct $1;
				} elsif ($x =~ s/^c(?=.)//) {
					$x = '@' ^ uc $x;
				} elsif ($esc{$x}) {
					$x = $esc{$x};
				}
				$x
			>eg;
			$s
		},
	},
	qx => \&my_qx,
	rainbow => do {
		my @rainbow = qw(04 07 05 08 09 03 10 11 12 02 06 13);
		sub {
			my $s = shift;
			my $start = rand @rainbow;
			$s =~ s{(.{1,2})}{
				(my $tmp = $1) =~ s/^,/,,/;
				"\cC" . $rainbow[$start++ % @rainbow] . $tmp
			}esg;
			$s
		}
	},
	randword => sub {
		my $n = shift;
		$n =~ s/^\s+//;
		$n =~ s/[^0-9].*//s;
		$n =~ /^[0-9]/ or $n = 1;
		join ' ', map randword(), 1 .. $n
	},
	reverse => sub {
		my $s = shift;
		scalar reverse $s
	},
	rhythmbox => sub {
		my $fmt = ('%ta - %tt', '%ta', '%tt')[$_[0] || 0];
		my_qx "rhythmbox-client --print-playing-format \Q$fmt\E"
	},
	rot13 => sub {
		my $s = shift;
		$s =~ tr/a-zA-Z/n-za-mN-ZA-M/;
		$s
	},
	sha1 => sub { sha1_hex $_[0] },
	sha256 => sub { sha256_hex $_[0] },
	sha512 => sub { sha512_hex $_[0] },
	sperr => sub {
		my $s = shift;
		my $d = $s =~ s/^((?:[^,\\]|\\.)*),//s ? $1 : ' ';
		$d =~ s/\\(.)/$1/sg;
		join $d, split //, $s
	},
	substr => sub {
		my $s = shift;
		my $o = $s =~ s/^\s*([-+]?[0-9]+)\s*,// ? $1 : 0;
		my $n = $s =~ s/^\s*([-+]?[0-9]+)\s*,// ? $1 : length $s;
		substr $s, $o, $n
	},
	suff => sub {
		my $num = 0 + shift;
		my $mod = $num % 5;
		my $st = $mod == 1 ? 'st' : $mod == 2 ? 'rd' : 'th';
		"$num$st"
	},
	think => sub {
		".oO( $_[0] )"
	},
	u => sub { "\c_$_[0]\c_" },
	uc => sub { uc $_[0] },
	uni => sub {
		my $s = shift;
		my @v = UniData::lookup $s;
		join('', map chr, @{$v[0]})
	},
	unis => sub {
		my $s = shift;
		my @v = UniData::lookup $s;
		join('', map +(map chr, @$_), @v)
	},
	urldec => sub { uri_unescape $_[0] },
	urlenc => sub { uri_escape $_[0] },
	w => sub {
		my $s = shift;
		my $n = $s =~ s/^([0-9]+),// ? $1 : 0;
		my @w = $s =~ /\w+/g;
		$n < @w ? $w[$n] : ''
	},
	wat => sub { "has anyone really been far even as decided to use even go want to do look more like?" },
	wcalc => sub {
		my $s = shift;
		wrcmd $s, 'hax-wcalc'
	},
	do {
		my %enz = (
			'(' => 'ZL',
			')' => 'ZR',
			'[' => 'ZM',
			']' => 'ZN',
			':' => 'ZC',
			'Z' => 'ZZ',

			'z' => 'zz',
			'&' => 'za',
			'|' => 'zb',
			'^' => 'zc',
			'$' => 'zd',
			'=' => 'ze',
			'>' => 'zg',
			'#' => 'zh',
			'.' => 'zi',
			'<' => 'zl',
			'-' => 'zm',
			'!' => 'zn',
			'+' => 'zp',
			"'" => 'zq',
			'\\' => 'zr',
			'/' => 'zs',
			'*' => 'zt',
			'_' => 'zu',
			'%' => 'zv',
		);
		my %dez = reverse %enz;
		my $dere = list2re keys %dez;

		my $enhex = sub {
			my $c = shift;
			my $h = sprintf "%x", ord $1;
			'z' . ($h =~ /^[0-9]/ ? $h : "0$h") . 'U'
		};

		zenc => sub {
			my $s = shift;
			$s =~ s/([^a-yA-Y0-9])/$enz{$1} || $enhex->($1)/eg;
			$s
		},
		zdec => sub {
			my $s = shift;
			$s =~ s/($dere)|z([[:xdigit:]]+)U/defined $2 ? chr hex $2 : $dez{$1}/eg;
			$s
		},
	},
);
$cmd{wide} ||= $cmd{full};

my $command_re = qr/[a-zA-Z_0-9]+/;
my $compound_re = qr/$command_re(?:\.$command_re)*/;

sub subparse; sub subparse {
	my ($pstr) = @_;

	my $nesting = 0;
	my @chunks;
	while (length $$pstr && ($nesting > 0 || $$pstr !~ /^\}/)) {

		if ($$pstr =~ s/^([^`{}]+)//) {
			push @chunks, $1;
			next;
		}

		if ($$pstr =~ s/^`($compound_re)\{//) {
			my $cmds = $1;
			my $arg = subparse $pstr;
			$$pstr =~ s/^\}// or fail "missing }";
			for my $cmd (reverse split /\./, $cmds) {
				$arg = [[$cmd, $arg]];
			}
			push @chunks, @$arg;
			next;
		}

		if ($$pstr =~ s/^`([{}])//) {
			push @chunks, $1;
			next;
		}

		if ($$pstr =~ s/^\{//) {
			++$nesting;
			push @chunks, '{';
			next;
		}

		if ($$pstr =~ s/^\}//) {
			--$nesting;
			push @chunks, '}';
			next;
		}

		if ($$pstr =~ s/^`(?:`(?=`*$compound_re\{))?//) {
			push @chunks, '`';
			next;
		}

		fail "wtf";
	}

	\@chunks
}

sub parse {
	my ($pstr) = @_;

	my @chunks;
	while (length $$pstr) {

		if ($$pstr =~ s/^([^`]+)//) {
			push @chunks, $1;
			next;
		}

		if ($$pstr =~ s/^`($compound_re)\{//) {
			my $cmds = $1;
			my $arg = subparse $pstr;
			$$pstr =~ s/^\}// or fail "missing }";
			for my $cmd (reverse split /\./, $cmds) {
				$arg = [[$cmd, $arg]];
			}
			push @chunks, @$arg;
			next;
		}

		if ($$pstr =~ s/^`(?:`(?=`*$compound_re\{))?//) {
			push @chunks, '`';
			next;
		}

		fail "wtf";
	}

	\@chunks
}

sub execute; sub execute {
	my ($chunks) = @_;
	my $out = '';
	for my $chunk (@$chunks) {
		unless (ref $chunk) {
			$out .= $chunk;
			next;
		}
		my ($instr, $arg) = @$chunk;
		my $func = $cmd{$instr} or fail "unknown command '$instr'";
		$out .= $func->(execute $arg);
	}
	$out
}

sub macroexpand {
	my ($line, $err) = @_;
	utf8::decode $line;
	utf8::upgrade $line;
	my $x = try { parse \$line } with {
		$err->("@{$@} at " . (length $line ? "-> $line" : "EOF"));
		undef
	} or return;
	defined(
		my $r = try { execute $x } with {
			$err->("@{$@}");
			undef
		}
	) or return;
	$r =~ s/^\s*\n//;
	$r =~ s/\s+\z//;
	$r
}

sub mkerr {
	my ($witem) = @_;
	sub {
		my ($msg) = @_;
		my @args = (esc("$IRSSI{name}: $msg"), MSGLEVEL_CLIENTERROR);
		$witem ? $witem->print(@args) : &Irssi::print(@args)
	}
}

sub spand {
	my ($line, $server, $witem) = @_;
	my ($r) = macroexpand $line, mkerr($witem) or return;
	if ($r =~ m!^/!) {
		$r =~ tr/\n/ /;
		signal_emit 'send command', $r, $server, $witem;
	} else {
		for my $line (split /\n/, $r) {
			signal_emit 'send command', "/ $line", $server, $witem;
		}
	}
}

signal_add_first 'gui line entered' => sub {
	my ($line, $server, $witem) = @_;
	$line =~ /`/ or return;
	signal_stop;
	spand $line, $server, $witem;
};

command_bind 'spand' => \&spand;

command_bind 'inline_spand' => sub {
	my ($line, $server, $witem) = @_;
	$line = Irssi::parse_special('$L');
	my ($r) = macroexpand $line, mkerr($witem) or return;
	$r =~ tr/\n/ /;
	Irssi::gui_input_set($r);
};

signal_add 'complete word' => sub {
	my ($complist, $window, $word, $linestart, $want_space) = @_;
	my ($init, $prefix) = $word =~ /^(.*(?<!`)(?:``)*`(?:$command_re\.)*)($command_re?)\z/ or return;
	$$want_space = 0;
	push @$complist, map "$init$_", sort grep /^\Q$prefix/, keys %cmd;
};
