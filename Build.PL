use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Verse',
	license             => 'bsd',
	dist_author         => q{James Hunt <james@niftylogic.com>},
	dist_version_from   => 'lib/Verse.pm',
	build_requires => {
		'Test::More'        => 0,
		'Test::Deep'        => 0,
		'Test::Output'      => 0,
		'Test::Exception'   => 0,
	},
	configure_requires => {
		'Module::Build'     => 0.38,
	},
	requires => {
#		'File::Find'        => 0,
		'File::Temp'        => 0,
		'Hash::Merge'       => 0,
		'Template'          => 0,
#		'Time::ParseDate'   => 0,
		'YAML'              => 0,
	},
	add_to_cleanup      => [ 'Verse-*', '*.deb', '*.rpm' ],
);

$builder->create_build_script();
