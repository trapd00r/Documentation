use Test::More;
use Test::Pod;
use Test::Pod::Coverage;
use strict;
use warnings FATAL => 'all';

# the all_ things attempt to plan, which we didn't want, so stop them
# from doing that
no warnings 'redefine';
local *Test::Builder::plan = sub { };

all_pod_files_ok;
all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::CountParents' });

done_testing;
