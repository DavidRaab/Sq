#!perl
use 5.036;
use Sq;
use Sq::Gen;
use Sq::Sig;
use Sq::Test;

warn("# Testing Sq $Sq::VERSION, Perl $], $^X");
ok($Sq::VERSION >= "0.007", 'Check minimum version number');

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
    $data->map(call 'max')->filter_valid,
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
        Some(2,3),
        'sq on multiple values in option');
}

# sq with result
{
    is(
        sq(Ok([1,2,3]))->map(sub { $_[0]->length }),
        Ok(3),
        'sq on Ok');

    is(
        sq(Err([1,2,3]))->mapErr(sub { $_[0]->length }),
        Err(3),
        'sq on Err');
}

# equal
{
    my $data1 = {
        Artist => 'Artist1',
        Title  => 'Title1',
        Tracks => [
            { Title => 'What' },
            { Title => 'Not'  },
        ]
    };

    my $data2 = {
        Artist => 'Artist1',
        Title  => 'Title1',
        Tracks => [
            { Title => 'What' },
            { Title => 'Not'  },
        ]
    };

    my $data3 = {
        Artist => 'Artist1',
        Title  => 'Title1',
        Tracks => [
            { Title => 'What'    },
            { Title => 'Whoooop' },
        ]
    };

     ok(equal($data1, $data2), 'comparision of data-structures 1');
    nok(equal($data2, $data3), 'comparision of data-structures 2');
}

{
    my $first  = Seq->range(1,1_000_000_000);
    my $second = Seq->range(2,1_000_000_000);
    nok(equal($first, $second), 'seq not equal');
}

# check type functions
{
     ok(is_str("foo"),      'is_str 1');
    nok(is_str([]),         'is_str 2');
     ok(is_num(123),        'is_num 1');
    nok(is_num("foo"),      'is_num 2');
     ok(is_array(   []),    'is_array 1');
     ok(is_array(sq []),    'is_array 2');
    nok(is_array({}),       'is_array 3');
     ok(is_hash({}),        'is_hash 1');
     ok(is_hash(sq {}),     'is_hash 2');
    nok(is_hash([]),        'is_hash 3');
     ok(is_seq(seq {}),     'is_seq 1');
    nok(is_seq([]),         'is_seq 2');
     ok(is_opt(Some(10)),   'is_opt 1');
     ok(is_opt(None),       'is_opt 2');
    nok(is_opt([]),         'is_opt 3');
     ok(is_result(Ok(10)),  'is_result 1');
     ok(is_result(Err(10)), 'is_result 2');
    nok(is_result([]),      'is_result 3');
     ok(is_ref('Foo', bless([], 'Foo')), 'is_ref 1');
    nok(is_ref('Bar', bless([], 'Foo')), 'is_ref 2');
}

# type / is_type
{
    my $range = type [opt => [range => 0, 10]];
    nok(is_type($range, Some(-1)), 'type 1');
     ok(is_type($range,  Some(0)), 'type 2');
     ok(is_type($range,  Some(5)), 'type 3');
     ok(is_type($range, Some(10)), 'type 4');
    nok(is_type($range, Some(11)), 'type 5');

    my $is_sha = type [str => [match => qr/\A[0-9a-f]{128}\z/i ]];

    my $array = gen_run(gen_repeat(20, gen_sha512));
    $array->iteri(sub($sha,$idx) {
        ok(is_type($is_sha, $sha), "$idx: is_sha");
    });

    my $is_sha_tuple = type [tuple => $is_sha, $is_sha];
    my $sha_tuple    = gen_array(gen_sha512, gen_sha512);
    for ( 1 .. 20 ) {
        ok(is_type($is_sha_tuple, gen_run($sha_tuple)), "$_: sha tuple");
    }
}

done_testing;
