use 5.036;
use Module::Build;
Module::Build->VERSION('0.4004');

my $builder = Module::Build->new(
    module_name          => 'Sq',
    license              => 'mit',
    dist_author          => q{David Raab <davidraab83@gmail.com>},
    dist_version_from    => 'lib/Sq.pm',
    release_status       => 'stable',
    recursive_test_files => 1,
    configure_requires   => {
        'Module::Build' => '0.4004',
    },
    requires => {
        'Carp'            => '0',
        'Scalar::Util'    => '0',
        'Hash::Util'      => '0',
        'List::Util'      => '0',
    },
    test_requires => {
        'Scalar::Util'    => '0',
        'Carp'            => '0',
        'Path::Tiny'      => '0',
        'List::Util'      => '0',
        'Digest::SHA'     => '0',
        'PerlIO::gzip'    => '0',
        'JSON'            => '0',
    },
    add_to_cleanup => [ 'Sq-*' ],
);

$builder->create_build_script();
