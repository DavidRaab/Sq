#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Gen;
use Sq::Parser -sig => 1;
use Sq::Sig;

# This script prints all functions in Sq, that have no type-check with
# signature added.

# Fully-Qualified-Name
sub fqn($package) {
    # Built a hash of functions to be skipped
    #
    # state only computes the value a single time. and `assign` allows us to
    # basically provide a subroutine to compute the value that then is only
    # computed once.
    state $skip = assign {
        my %skip;
        # Skip imported/exported functions by Sq
        for my $name ( @Sq::EXPORT ) {
            $skip{$name} = 1 if is_str($name);
        }
        # also skip import() function
        $skip{import} = 1;
        # skip string overload in packages
        $skip{'(""'} = 1;
        $skip{'(('}  = 1;
        return \%skip;
    };

    # get functions of package
    Sq::Reflection::funcs_of($package)
    # remove those defined in %skip
    ->remove(sub($name) { $skip->{$name}  })
    # add full package name
    ->rxs(qr/\A/, sub   { $package . '::' });
}

# Three examples that are all the same
#
# Array::concat(fqn($strA), fqn($strB));
# Array::map ($strs, \&fqn)->flatten;
# Array::bind($strs, \&fqn);
my $funcs = Array::bind(
    [
        qw/Array Hash Seq Option Result Sq::Parser Sq::Gen Sq::Fmt Sq::Fs/,
        qw/Sq::Math Sq::Bench Sq::Io/
    ],
    \&fqn);

# dump($funcs);

my $sigs = Sq::Reflection::signatures;

# dump($sigs);

say "Following functions is missing a signature:";
Array::diff($funcs, $sigs, \&id)->iter_sort(by_str, sub($func) {
    say $func;
});
