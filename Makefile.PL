use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'VeloHero',
    VERSION_FROM      => 'lib/VeloHero.pm',
    PREREQ_PM         => {
	# update debian/control, too!
	'LWP::ConnCache'	=> undef,
	'LWP::UserAgent'	=> undef,
	'XML::Simple'	=> undef,
    }, # e.g., Module::Name => 1.1
    'EXE_FILES'       => [qw(
	vheroupload
    )],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/VeloHero.pm', # retrieve abstract from module
       AUTHOR         => 'Rainer Clasen') : ()),
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
