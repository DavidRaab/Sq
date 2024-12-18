#!perl
use 5.036;
use Sq;
use Sq::Parser;
use Sq::Sig;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

# Helper function to build result
sub result(@xs) { Some([@xs]) }

# Example of parsing an int array

# Regex
# \[                           # open
#    (?:                       # or
#        \s* \d+ \s*           # int
#        (?: , \s* \d+ \s* )*  # delimeter,int
#      |
#        \s* \d+ \s*           # int
#      |
#        \s*                   # whitespace
#    )
# \]                           # close

# The problem of using regex is not the matching. But we need to extract
# and transform values. Defining a regex to validate an int array is easy
# but getting the values and transforming it into an Perl array is harder.
# Then we would need to split the regex or insert perl code into the regex
# to achive the same. We also can extract regex parts into compiled regexes
# with qr// and then use those variables to create a bigger regex, this
# way also nested constructs are possible.
#
# But in that regards the Sq::Parser allows exactly todo that. You can put
# single regexes into single parser and then combine them again into a bigger
# parser. But those parsers extracts the matched parts and you can specify
# perl code to work with the extracted parts.

my $open      = p_str('[');
my $close     = p_str(']');
my $delimeter = p_str(',');
my $int       = p_match(qr/\s* (\d+) \s*/x);

# int array
my $ia = p_and(
    $open,
    p_or(
        p_and(
            $int,
            p_many0(p_and($delimeter,$int)),
        ),
        $int,
        p_match(qr/\s*/),
    ),
    $close,
);

# parse array
my $pa = p_map(sub(@xs) { sq [@xs] }, $ia);

is(p_run($pa, '[]'),             result([]), 'parse array 1');
is(p_run($pa, '[ ]'),            result([]), 'parse array 2');
is(p_run($pa, '[ 1 ]'),         result([1]), 'parse array 3');
is(p_run($pa, '[1, 2, 3]'), result([1,2,3]), 'parse array 4');
is(p_run($pa, '[1,2,3]'),   result([1,2,3]), 'parse array 5');
is(p_run($pa, '[ 1,2,3 ]'), result([1,2,3]), 'parse array 6');

done_testing;
