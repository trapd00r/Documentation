use Test::More qw(no_plan);

our (@us, @expect);

sub capture_stuff { [ $^H, ${^WARNING_BITS} ] }

sub capture_us { push @us, capture_stuff }
sub capture_expect { push @expect, capture_stuff }

{
  use strictures 1;
  BEGIN { capture_us }
}

{
  use strict;
  use warnings FATAL => 'all';
  BEGIN { capture_expect }
}

# I'm assuming here we'll have more cases later. maybe not. eh.

foreach my $idx (0 .. $#us) {
  is($us[$idx][0], $expect[$idx][0], 'Hints ok for case '.($idx+1));
  is($us[$idx][1], $expect[$idx][1], 'Warnings ok for case '.($idx+1));
}

{
  local $0 = 't/00load.t';
  sub Foo::new { 1 }
  chdir("t/smells-of-vcs");
  my $r = eval q{
    use strictures 1;
    new Foo 1, 2, 3;
  };
  # I don't test $@ here since if indirect isn't installed we hit one
  # error and if it is we hit another; it's enough the code path's hit.
  ok(!$r, 'strictures blows up for t/00load.t');
}

ok(!eval q{use strictures 2; 1; }, "Can't use strictures 2 (this is version 1)");
