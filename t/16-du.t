#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;
use Path::Tiny qw(path);

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

for my $case ( @cases ) {
    is($fs->is_case($case), 1, 'Is case of $fs');
}

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

    # check failure of is_case
    is($fs->is_case($other->case(File => path('/etc/fstab'))), 0, 'Not a case');
}

{
# Recursive Union. Example to create an immutable list
#
# This is very inefficent, and also by far not how for example the immutable
# list in Sq is implemented. But this comes close to what you will write
# for example in F# to implement an immutable List.
#
# F#:
# type List<'a> =
#     | Empty
#     | Cons of 'a * List<'a>
    my $list;
    $list = union(
        Empty => ['void'],
        Cons  => [tuple => ['any'], [runion => sub { $list }]],
    );

    # fold for list DU
    sub fold($list, $state, $f) {
        $list->match(
            Empty => sub{$state},
            Cons  => sub($data) {
                my ($head,$tail) = @$data;
                return fold($tail, $f->($head, $state), $f);
            }
        );
    }

    # function to create immutable list
    my $empty = $list->case('Empty');
    sub list(@data) {
        my $new = $empty;
        for my $x ( reverse @data ) {
            $new = $list->case(Cons => [$x,$new]);
        }
        return $new;
    }

    # function to turn immutable list back to array
    sub to_array($list) {
        fold($list, [], sub($x,$state) { push @$state, $x; $state });
    }

    # back and forth
    is(
        to_array(list(1,2,3,4)),
        [1,2,3,4],
        'list to array');
}

# Example how to implement an Option type with an Union. In F# it's defined like this:
# type Option<'a> =
#     | None
#     | Some of 'a
#
# The Option type in Sq is more efficently implemented but also not exactly the
# same like here. In Sq it allows multiple values.
{
    my $option = union(
        'None',
        Some => ['any'],
    );

    my $option_full = union(
        None => ['void'],
        Some => ['any'],
    );

    is($option, $option_full, 'Should be the same');

    # Empty case at end
    my $option2 = union(
        Some => ['any'],
        'None',
    );
    is($option2, $option_full, 'Also the same');

    is(
        $option->case('None'),
        $option2->case('None'),
        'None is the same');

    is(
        $option ->case(Some => "Hello"),
        $option2->case(Some => "Hello"),
        'Some are the same 1');

    is(
        $option ->case(Some => [qw/Hello World/]),
        $option2->case(Some => [qw/Hello World/]),
        'Some are the same 2');

    nok(equal(
        $option ->case(Some => [qw/Hello World !/]),
        $option2->case(Some => [qw/Hello World/]),
    ), 'Not the same');
}

# TODO: Some other idea i suddenly had
# sub Array;
# my $array_init1 = Array('init', 3, sub($idx) { $idx });
# my $array_init2 = Array init => 3, sub($idx) { $idx };

done_testing;
