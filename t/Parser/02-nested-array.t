#!perl
use 5.036;
use Sq;
use Sq::Parser;
use Test2::V0 ':DEFAULT';

# Helper function to build result
sub result(@xs) { Some([@xs]) }

# Example of parsing nested int array
my $open      = p_match(qr/\s* \[ \s*/x);
my $close     = p_match(qr/\s* \] \s*/x);
my $delimeter = p_match(qr/\s* ,  \s*/x);
my $int       = p_match(qr/\s* (\d+) \s*/x);

# int array
my $array;
my $a     = p_delay(sub{ $array });
my $value = p_or($int, $a);
$array    = p_map(
    p_and(
        $open,
        p_or(
            p_and(
                $value,
                p_many0(p_and($delimeter, $value)),
            ),
            $value,
            p_match(qr/\s*/),
        ),
        $close,
    ),
    sub(@xs) { sq [@xs] }
);

# same as before
is(p_run($array, '[]'),             result([]), 'parse array 1');
is(p_run($array, '[ ]'),            result([]), 'parse array 2');
is(p_run($array, '[ 1 ]'),         result([1]), 'parse array 3');
is(p_run($array, '[1, 2, 3]'), result([1,2,3]), 'parse array 4');
is(p_run($array, '[1,2,3]'),   result([1,2,3]), 'parse array 5');
is(p_run($array, '[ 1,2,3 ]'), result([1,2,3]), 'parse array 6');

# nested arrays
is(
    p_run($array, '[[[1]]]'),
    result([[[1]]]),
    'nested arrays 1');
is(
    p_run($array, '[[1,2,3], [4,5,6]]'),
    result([[1,2,3], [4,5,6]]),
    'nested arrays 2');
is(
    p_run($array, '[[1,2,3], [4,5,[6,7,8]]]'),
    result([[1,2,3], [4,5,[6,7,8]]]),
    'nested arrays 3');
is(
    p_run($array, '[[ 1, 2,3], [ 4,5, [6 ,7,8]]]'),
    result([[1,2,3], [4,5,[6,7,8]]]),
    'nested arrays 4');

done_testing;
