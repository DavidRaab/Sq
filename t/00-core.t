#!perl
use 5.036;
use Sq;
use Sq::Gen qw(gen gen_run);
use Sq::Test;
use Sq::Sig;

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
    $data->map(call 'max')->keep_some,
    [3,6,9],
    'calls max on each inner array');

# but you also can specify a default, then no optional is returned anymore
is(
    $data->map(call 'max', 0),
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

# this also shows that a sequence is lazy, and only compares as much
# needed to decide if they are equal. If not, comparing two sequences
# with each of 1 billion elements would take some time. In examples/1bill.pl
# it takes multiple minutes todo so.
{
    my $first  = Seq->range(1,1_000_000_000);
    my $second = Seq->range(2,1_000_000_000);
    nok(equal($first, $second), 'seq not equal');
}

# check type functions
{
     ok(is_str("foo"),       'is_str 1');
    nok(is_str([]),          'is_str 2');
     ok(is_num(123),         'is_num 1');
    nok(is_num("foo"),       'is_num 2');
     ok(is_array(   []),     'is_array 1');
     ok(is_array(sq []),     'is_array 2');
    nok(is_array({}),        'is_array 3');
     ok(is_hash({}),         'is_hash 1');
     ok(is_hash(sq {}),      'is_hash 2');
    nok(is_hash([]),         'is_hash 3');
     ok(is_seq(seq {}),      'is_seq 1');
    nok(is_seq([]),          'is_seq 2');
     ok(is_opt(Some(10)),    'is_opt 1');
     ok(is_opt(None),        'is_opt 2');
    nok(is_opt([]),          'is_opt 3');
     ok(is_result(Ok(10)),   'is_result 1');
     ok(is_result(Err(10)),  'is_result 2');
    nok(is_result([]),       'is_result 3');
     ok(is_regex(qr/\Aasd/), 'is_regex 1');
    nok(is_regex("asd"),     'is_regex 2');
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

    # this is funny
    # I define a type, and then auto-generate data for that type that i than
    # test against that type. But this way it is really a deep complex test
    # that test a whole of stuff in one go and it tests if the type and the
    # generation in itself are correct.
    my $is_sha = type [str => [match => qr/\A[0-9a-f]{128}\z/i ]];
    ok(
        is_type(
            type([array => [of => $is_sha]]),      # type for array with 20 SHA512 strings
            gen_run gen [repeat => 20, ['sha512']] # genereates array with 20 SHA512 strings
        ),
        'array of SHA512');

    # test generation of 20 tuples.
    my $is_sha_tuple = type [tuple  => $is_sha, $is_sha];
    my $is_sha_array = type [array  => [length => 20, 20], [of => $is_sha_tuple]];
    my $sha_tuples   = gen  [repeat => 20, [array => ['sha512'], ['sha512']]];
    # now instead of 20 tests and testing every tuple 20 times, it is done
    # in a single test. Still this test is a lot more usefule and actually
    # tests more than the previous 20 tests. It's also about quality of
    # tests, not just the numbers.
    ok(is_type($is_sha_array, gen_run($sha_tuples)), " array of sha tuple");
}

# new
{
    is((new Array => (1,2,3)),     [1,2,3], 'new Array');
    is((new Seq   => (1,2,3)), seq {1,2,3}, 'new Seq');
    is(
        (new Hash  => (foo => 1, bar => 2)),
        {foo => 1, bar => 2},
        'new Hash');
}

# multi
{
    my $is_account = type [keys =>
        name  => ['str'],
        saldo => ['num'],
    ];
    my $in  = type [keys =>  in => ['num']];
    my $out = type [keys => out => ['num']];

    # this creates a multi-dispatch function based on the type
    multi(apply_change =>
        type [tuple => $is_account, $in] => sub($account,$entry) {
            my $in  = $entry->{in};
            my $new = Hash::withf($account, saldo => sub($saldo) { $saldo + $in });
            $new->{change} = "+$in";
            return $new;
        },
        type [tuple => $is_account, $out] => sub($account,$entry) {
            my $out = $entry->{out};
            my $new = Hash::withf($account, saldo => sub($saldo) { $saldo - $out });
            $new->{change} = "-$out";
            return $new;
        }
    );
}
{
    my $account = { name  => "Lilly", saldo => 10_000 };

    my sub in ($amount) { {in  => $amount } }
    my sub out($amount) { {out => $amount } }

    my $bookings = sq [
        in(2_000), out(3_000), in(500), out(6_000),  in(1_800), out(600),
          in(400), out(1_200), in(666),   out(999), in(10_000)
    ];

    is(
        Array::scan($bookings, $account, sub($entry,$account) {
            apply_change($account, $entry)
        }),
        [
            { name => "Lilly", saldo => 10000 },
            { change =>  "+2000", name => "Lilly", saldo => 12000 },
            { change =>  "-3000", name => "Lilly", saldo =>  9000 },
            { change =>   "+500", name => "Lilly", saldo =>  9500 },
            { change =>  "-6000", name => "Lilly", saldo =>  3500 },
            { change =>  "+1800", name => "Lilly", saldo =>  5300 },
            { change =>   "-600", name => "Lilly", saldo =>  4700 },
            { change =>   "+400", name => "Lilly", saldo =>  5100 },
            { change =>  "-1200", name => "Lilly", saldo =>  3900 },
            { change =>   "+666", name => "Lilly", saldo =>  4566 },
            { change =>   "-999", name => "Lilly", saldo =>  3567 },
            { change => "+10000", name => "Lilly", saldo => 13567 }
        ],
        'in/out history');
}

# static
{
    # Does not fail
    my $prime = Sq->math->is_prime;
    is(ref $prime, 'CODE', 'is function');
    is($prime->(2), 1, 'is_prime 1');
    like(
        dies { $prime->("foo") },
        qr/\ASq::Math::is_prime:/,
        'type check active');
    is(Sq->math->is_prime(2), 1, 'is_prime 2')
}

# array/hash
{
    my $array = array(1,2,3,undef,4,5,6);
    check_isa($array, 'Array', 'array');
    is($array, [1,2,3,undef,4,5,6], 'no undef handling');

    my $hash = hash(foo => 1, bar => 2);
    check_isa($hash, 'Hash', 'hash');
    is($hash, {foo => 1, bar => 2}, 'creates hash');

    # Why those functions? Because very often it happens that you want to
    # pass a lambda somewhere where all arguments are put into an array/hash.
    # Instead of writing this lambda again and again, you just can provide
    # a reference to these functions.
    one_of(
        # to_array() passes $key,$value from the hash to the lambda. By just
        # providing \&array you create an Array/Tuple out of it.
        hash(foo => 1, bar => 2, baz => 3)->to_array(\&array),
        [
            [[foo => 1], [bar => 2], [baz => 3]],
            [[foo => 1], [baz => 3], [bar => 2]],
            [[bar => 2], [foo => 1], [baz => 3]],
            [[bar => 2], [baz => 3], [foo => 1]],
            [[baz => 3], [foo => 1], [bar => 2]],
            [[baz => 3], [bar => 2], [foo => 1]],
        ],
        'array');

    # use ->as_hash instead
    is(
        hash(array(foo => 1, bar => 2, baz => 3)->expand),
             array(foo => 1, bar => 2, baz => 3)->as_hash,
        'expand with hash');

    is(
        array(foo => 1, bar => 2, baz => 3)->mapn(2, \&hash),
        [ {foo => 1}, {bar => 2}, {baz => 3} ],
        'hash with mapn');
}

is(
    array(1, "Anny", 100, 2, "Frank", 12, 3, "Peter", 33)->mapn(3, fhash(qw/id name points/)),
    [
        {id => 1, name => "Anny",  points => 100},
        {id => 2, name => "Frank", points => 12 },
        {id => 3, name => "Peter", points => 33 },
    ],
    'fhash');

done_testing;
