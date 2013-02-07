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
        'Test::More' => 0,
    },
    requires => {
        'perl' => 5.006,
    },
    add_to_cleanup      => [ 'Verse-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
