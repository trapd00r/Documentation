use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Term::Menu::Hierarchical',
    VERSION_FROM      => 'lib/Term/Menu/Hierarchical.pm', # finds $VERSION
    PREREQ_PM         => { Term::ReadKey => 2.30 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Term/Menu/Hierarchical.pm', # retrieve abstract from module
       AUTHOR         => 'Ben Okopnik <ben@okopnik.com>') : ()),
);
