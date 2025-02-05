#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Parser -sig => 1;
use Sq::Test;
use Path::Tiny qw(path);

# API not stable. Will very likely change. First concept.

# this creates a type-union. It's like an enum but instead of just a name
# to a number mapping. Every case can be of any complex type.
# Here it describes a type that either is a "File" or "Folder" and every
# case must be a Path::Tiny object.
my $fs = union(
    File   => type [ref => 'Path::Tiny'],
    Folder => type [ref => 'Path::Tiny'],
);

# Here we create cases. The cases type-check in two ways. You only can
# specify "File" or "Folder" and whatever we pass to it must be type-check
my @cases = (
    $fs->case(File   => path('/etc/fstab')),
    $fs->case(File   => path('/etc/passwd')),
    $fs->case(Folder => path('/etc')),
);

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

is($files,   2, 'one file');
is($folders, 1, 'one folder');

# Do i really need Discriminated Unions in a dynamic-typed language?
# In some cases in the past i just used [File => ...] for this.
# but it has no match() and checking in it. Or I have to re-write it again
# and again.

# Another approach would be to use a type for this. I can write.

my $fs_type = type [or =>
    [tuple => [eq => 'File'],   [ref => 'Path::Tiny']],
    [tuple => [eq => 'Folder'], [ref => 'Path::Tiny']],
];

# this describes a type of two cases. I just could create a match() function
# that takes a type and a case and it does the checking and dispatch based on
# it.

# for convenince i also could create union() that automatically is a "or"
# expecting tuples with the first one being an string. This would
# make the definition shorter, but otherwise creates the exact same type.

# Something like:

# my $fs_type = union(
#     File   => [ref => 'Path::Tiny'],
#     Folder => [ref => 'Path::Tiny'],
# );
#
# my $case = case($fs_type, File => ...);
#
# match($case,
#     File   => sub { ... },
#     Folder => sub { ... },
# );

# TODO: Some other idea i suddenly had
# sub Array;
# my $array_init1 = Array('init', 3, sub($idx) { $idx });
# my $array_init2 = Array init => 3, sub($idx) { $idx };

done_testing;
