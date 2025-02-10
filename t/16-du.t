#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;
use Path::Tiny qw(path);

# TODO: Recursive DUs

# this creates a type-union. It's like an enum but instead of just a name
# to a number mapping every case can be of any complex type.
# Here it describes a type that either is a "File" or "Folder" and every
# case must be a Path::Tiny object.
my $fs = union(
    File   => [ref => 'Path::Tiny'],
    Folder => [ref => 'Path::Tiny'],
);

# dump($fs);

# Two cases of an union, and they can be equal
is(
    $fs->case(File => path('/etc/fstab')),
    $fs->case(File => path('/etc/fstab')),
    'cases can be equal');

# Here we create cases. The cases type-check in two ways. You only can
# specify "File" or "Folder" and whatever we pass to it must type-check
# against the definition
my @cases = (
    $fs->case(File   => path('/etc/fstab')),
    $fs->case(File   => path('/etc/passwd')),
    $fs->case(Folder => path('/etc')),
);

# dump(\@cases);

# "FILE" not valid case
like(
    dies { $fs->case(FILE => path('/etc/fstab')) },
    qr/\ACase 'FILE' invalid/,
    'wrong case dies');

# string not allowed for "File"
like(
    dies { $fs->case(File => '/etc/fstab') },
    qr/\AData for case 'File' invalid/,
    'wrong type for case dies');

# match
{
    my ($files, $folders) = (0,0);
    for my $case ( @cases ) {
        # Pattern matching. A case can be pattern matched. We don't know which case
        # we have and we must provide a sub-ref for every case. match() fails when
        # we do not provide a sub-ref for every defined case.
        $case->match(
            File   => sub($file)   { $files++   },
            Folder => sub($folder) { $folders++ },
        );
    }

    is($files,   2, 'two files');
    is($folders, 1, 'one folder');
}

# match() with 'file' instead of 'File' as case.
like(
    dies {
        $cases[0]->match(
            file   => sub { }, # wrong
            Folder => sub { },
        );
    },
    qr/\ACase 'File' not handled/,
    'wrong case names in match()');

# Comparison of type definition
{
    my $other = union(
        Folder => [ref => 'Path::Tiny'],
        File   => [ref => 'Path::Tiny'],
    );
    is($fs, $other, 'types are the same');

    # Even though we have two cases that are created from two different types
    # they are still considered the same/equal because the type-definition
    # of $fs and $other are the same.
    is(
        $fs   ->case(File => path('/etc/fstab')),
        $other->case(File => path('/etc/fstab')),
        'Is equal');
}

# Comparison of different types
{
    my $other = union(
        File   => [ref => 'Path::Tiny'],
        Folder => [ref => 'Path::Tiny'],
        Link   => [ref => 'Path::Tiny'],
    );
    nok(equal($fs, $other), 'types not the same');

    # The same cases but from types that are different are not considered equal
    nok(equal(
        $fs   ->case(File => path('/etc/fstab')),
        $other->case(File => path('/etc/fstab')),
    ), 'Same cases from different union types not equal');
}

# TODO: Some other idea i suddenly had
# sub Array;
# my $array_init1 = Array('init', 3, sub($idx) { $idx });
# my $array_init2 = Array init => 3, sub($idx) { $idx };

done_testing;
