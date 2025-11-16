#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Signature;
use Sq::Reflection qw(funcs_of signatures);
# Explicitly loaded all modules because of lazy-loading
use Sq::Core::Str;
use Sq::Io;
use Sq::Fs;
use Sq::Fmt;
use Sq::Math;
use Sq::Gen;
use Sq::Bench;
use Sq::Parser;
use Sq::P;
use Sq::Rand;

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
        my %skip = (
            import         => 1,
            unimport       => 1,
            load_signature => 1,
            '(""'          => 1, # string overload
            '(('           => 1, # string overload

        );
        # Skip imported/exported functions by Sq
        for my $name ( @Sq::EXPORT ) {
            $skip{$name} = 1 if is_str($name);
        }
        return \%skip;
    };

    # get functions of package
    funcs_of($package)
    # remove those defined in %skip
    ->remove(sub($name) { $skip->{$name}  })
    # add full package name
    ->rxs(qr/\A/, sub   { $package . '::' });
}

# Following functions should be completely skipped. As no Signature
# will be added for some reasons.
my $skip = array(
    # Sq Modules Start
    'Sq::import',
    'Sq::unimport',
    'Sq::io',
    'Sq::fs',
    'Sq::math',
    'Sq::fmt',
    'Sq::bench',
    'Sq::rand',
    'Sq::p',
    'Sq::sys',
    'Sq::Str',
    # Sq Modules End
    # Functions that support $any value
    'Sq::is_array',
    'Sq::is_hash',
    'Sq::is_seq',
    'Sq::is_opt',
    'Sq::is_result',
    'Sq::is_ref',
    'Sq::is_regex',
    'Sq::is_sub',
    'Sq::is_num',
    'Sq::is_str',
    'Sq::sq',
    'Sq::array',
    'Sq::by_num',
    'Sq::by_str',
    'Sq::by_stri',
    'Sq::array',
    'Sq::hash',
    'Sq::seq',
    'Sq::id',
    'Sq::get_type',
    # just short aliases
    'Array::_copy',
    'Array::_equal',
    'Array::_is_regex',
    'Hash::_copy',
    'Seq::_copy',
    # Not needed they already have type-tests
    'Sq::Equality::du',
    'Sq::Equality::du_case',
    'Sq::Equality::path_tiny',
    'Sq::Equality::result',
    'Sq::Fmt::table',
);

# Three examples that are all the same
#
# Array::concat(fqn($strA), fqn($strB));
# Array::map ($strs, \&fqn)->flatten;
# Array::bind($strs, \&fqn);
my $funcs =
    Array::concat(
        funcs_of('Sq')->map(sub($str) { 'Sq::' . $str }),
        Array::bind([
            qw/Array Hash Seq Queue Option Result Sq::Parser Sq::Gen Sq::Fmt Sq::Fs/,
            qw/Sq::Math Sq::Bench Sq::Io Sq::Core::Str Sq::P Sq::Equality Sq::Rand/
        ], \&fqn)
    )
    ->diff($skip, \&id);

# dump($funcs);

say "Following functions is missing a signature:";
Sq->fmt->table({
    data => Array::diff($funcs, signatures(), \&id)->sort(by_str)->columns(4),
});
