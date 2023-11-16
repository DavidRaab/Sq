use Module::Build;
my $build = Module::Build->new(
    module_name => 'Foo::Bar',
    license     => 'perl',
    requires    => {
        'perl'          => '5.36',
    },
);
$build->create_build_script;
