use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'strictures',
  VERSION_FROM => 'lib/strictures.pm',
  ABSTRACT_FROM => 'lib/strictures.pm',
  AUTHOR => 'Matt S Trout <mst@shadowcat.co.uk>',
  LICENSE => 'perl',
);
