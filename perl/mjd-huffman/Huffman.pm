
package Huffman;

# Optional: Get `Memoize' from CPAN or from
# http://www.plover.com/~mjd/perl/Memoize/
# Then uncomment these to make the program go faster:
# use Memoize;
# memoize 'b8_to_char';
# memoize 'char_to_b8';

# compresstab:
# Input: a hash that maps input symbols to relative frequencies
# Output: a hash that maps input symbols to codes
sub tabulate {
  my $f = shift;
  my %r = ();
  while (keys %$f > 1) {
    my @k = least2($f);
    my $total_freq = 0;
    for my $i (0, 1) {
      $total_freq += $f->{$k[$i]};
      delete $f->{$k[$i]};
      foreach my $basekey (split(/$;/o, $k[$i])) {
	push @{$r{$basekey}}, $i;
      }
    }
    $f->{join $; => @k} = $total_freq;
  }
  foreach my $symbol (keys %r) {
    @{$r{$symbol}} = reverse @{$r{$symbol}};
  }
  wantarray ? %r : \%r;
}

sub least2 {
  my $h = shift;
  my ($k, $v);
  die "Asked for smallest 2 items from a hash with <2 items!  Aborting"
    if keys %$h < 2;

  my ($least1k, $least1v) = each %$h;
  my ($least2k, $least2v) = each %$h;
  ($least1k, $least1v, $least2k, $least2v) = 
  ($least2k, $least2v, $least1k, $least1v) 
    if $least2v < $least1v;
  
  while (($k, $v) = each %$h) {
    next unless $v < $least2v;
    if ($v < $least1v) {
      ($least2k, $least2v) = ($least1k, $least1v);
      ($least1k, $least1v) = ($k, $v);
    } else {
      ($least2k, $least2v) = ($k, $v);
    }
  }

  ($least1k, $least2k);
}

sub histogram {
  my $a = shift;
  my $r;
  foreach (@$a) {
    $r->{$_}++;
  }
  delete $r->{''};
  $r;
}

sub decode {
  my $cx = shift;
  my $d = shift;
  my ($length, $data) = split /:/, $d, 2;
  my $c = codetab_reverse($cx);
  my $result = '';
  my $tokens = 0;
  my $t = $c;
  my @bits = ();
  my @chars = split //, $data;
  my $b;
  while (@chars || @bits || defined($b)) {
    if (ref $t eq '') {
      $result .= $t;
      $tokens++;
      $t = $c;
      $b = undef;
      return $result if $length == $tokens;
      next;
    }
    unless (@bits) {
      @bits = char_to_b8(shift @chars);
    }
    $b = shift @bits;
    $t = $t->[$b];
  }
  $result;
}

sub encode {
  local *FH = shift;
  my $c = shift;
  my $d = shift;
  my $token_count = grep {$_ ne ''} @$d;
  print FH $token_count, ':';
  while (@$d) {
    while (@output < 8) {
      my $symbol =  shift @$d;
      if (defined $symbol) {
	next if $symbol eq '';  # Don't bother to write out encodings of empty symbol
	push @output, @{$c->{$symbol}};
      } else {
	push @output, (0) x 8;
      }
    }
    my $i;
    # pack out to a full byte
    push @output, (0) x scalar @output % 8;
    while (@output >= 8) {
      my @bits = splice @output, 0, 8;
      my $char = pack 'B8', (join '', @bits);
      print FH $char;
    }
  }

}

sub b8_to_char {
  my $s = 0;
  while (@_) {
    $s = $s * 2 + shift;
  }
  chr($s);
}

sub char_to_b8 {
#  my $b = unpack 'B8', pack 'c', ord(shift());
  my $b = unpack 'B8', shift();
  split //, $b;
}

sub save_code_table {
  local *FH = shift;
  my $table = shift;
  my ($k, $v);
  print FH (scalar(keys %$table), "\0");
  while (($k, $v) = each %$table) {
    my $code = join '', @$v;
    write_netstrings(*FH, $k, $code);
  }
}

sub load_code_table {
  my %ct;
  local *FH = shift;
  my $num_entries;
  { local $/ = "\0";
    chomp($num_entries = <FH>);
  }
  my $i;
  for ($i=0; $i<$num_entries; $i++) {
    my $k = read_netstring(*FH);
    my $v = read_netstring(*FH);
    if (exists $ct{$k}) {
      $ERROR = "Code table for item `$k' appears twice";
      return undef;
    } else {
      $ct{$k} = [split //, $v];
    }
  }
  \%ct;
}

sub codetab_reverse {
  my $r = [];
  my $c = shift;
  my ($s, $b);
  while (($s, $b) = each %$c) {
    my $bit;
    my $t = $r;
    my ($prev, $lastbit);
    foreach $bit (@$b) {
      unless (ref $t eq 'ARRAY') {
	require Carp;
	Carp::croak("Failed to create reverse code table for symbol `$s': \$t was `$t' instead of array ref.\n");
      }
      $prev = $t;
      $lastbit = $bit;
      if (defined $t->[$bit]) {
	$t = $t->[$bit];
      } else {
	$t = $t->[$bit] = [];
      }
    }
    $prev->[$lastbit] = $s;
  }
  1;
  1;
  $r;
}

sub a2s {
  my $a = shift;
  return '' unless defined $a;
  return $a unless ref $a eq 'ARRAY';
  my $q = join ',', map {a2s($_)} @$a;
  "($q)";
}

sub read_netstring {
  my $s;
  local *FH = shift;
  local $/ = ':';		# LOD
  my $length = <FH>;
  my $br = read(FH, $s, $length);
  unless ($br == $length) {
    $ERROR ="Premature end of file: Only $br out of $length bytes read";
    return undef;
  }
  return $s;
}

sub write_netstrings {
  local *FH = shift;
  my $s;
  foreach $s (@_) {
    my $L = length $s;
    print FH $L, ':', $s;
  }
}

1;
