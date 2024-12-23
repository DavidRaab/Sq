#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

warn("# Testing Sq $Sq::VERSION, Perl $], $^X");
ok($Sq::VERSION >= "0.006", 'Check minimum version number');

# check default imported functions

# The `sq` function blesses the data-structure recursively and adds Array/Hash
# blessing to the structure. The only reason is that you can call some methods
# on it instead of only having a function interface. Those blessed Arrays/Hashes
# are otherwise just used as a plain Array/Hash as you wish.
#
# Also in `Sq` itself care is done that those blessed Arrays/Hashes are equal
# to the plain unblessed versions. Also the reverse is true. All functions are written
# that they also except plain unblessed Arrays/Hashes.
my $data = sq [
    [1,2,3],
    [4,5,6],
    [7,8,9],
];

# call examples
is($data->map(call 'sum'),                  [6,15,24], 'call 1');
is($data->map(sub($array) { $array->sum }), [6,15,24], 'same without call');

is(
    Array::map([[1,2,3], [4,5,6], [7,8,9]], \&Array::sum),
    [6,15,24],
    'Array::map in functional style with unblessed arrays');

is(
    Array::map([[1,2,3], [4,5,6], [7,8,9]], call 'sum'),
    [6,15,24],
    'call now also supports unblessed Arrays/Hashes');

# max returns an optional value
is(
    Option->filter_valid( $data->map(call 'max') ),
    [3,6,9],
    'calls max on each inner array');

is(
    $data->map(call 'map', sub($x) { $x+1 }),
    [
        [2,3,4],
        [5,6,7],
        [8,9,10],
    ],
    'call 2');

# seq {} syntax
is(
    seq {1,2,3,undef,4,5,6},
    seq {1,2,3},
    'same with undef');

{
    # Generating it this way is not lazy. It just shows that seq {} gets a code
    # reference that is executed and you can put any code in it.
    #
    # But there is no yielding possible. It just executes the code and
    # puts its return values into a sequence.
    my $fib = seq {
        my @fibs = (1,1);
        for ( 1 .. 10 ) {
            push @fibs, $fibs[-2] + $fibs[-1];
        }
        return @fibs;
    };
    is($fib, seq { 1,1,2,3,5,8,13,21,34,55,89,144 }, 'fibs');
}

# key is a function to just select a key from a hash.
{
    my $data = sq [
        { id => 4, title => "B" },
        { id => 1, title => "D" },
        { id => 5, title => "E" },
        { id => 3, title => "A" },
        { id => 2, title => "C" },
    ];

    is($data->min_by    (key 'id'),    Some({id => 1, title => "D"}), 'min_by');
    is($data->max_by    (key 'id'),    Some({id => 5, title => "E"}), 'max_by');
    is($data->min_str_by(key 'title'), Some({id => 3, title => "A"}), 'min_str_by');
    is($data->max_str_by(key 'title'), Some({id => 5, title => "E"}), 'max_str_by');
}

# sq with option
{
    my $data = sq Some([1,2], [3,4,5]);
    is(
        $data->map(sub($x,$y) { $x->length, $y->length }),
        Some([2,3]),
        'sq on multiple values in option');
}

done_testing;
