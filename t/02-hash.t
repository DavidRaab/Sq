#!perl
use 5.036;
use Sq;
use Scalar::Util qw(blessed);
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;

# Some values, functions, ... for testing
my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

# Helper functions
my $ishash = check_isa('Hash');
my $by_str = sub($x, $y) { $x cmp $y };
my $by_num = sub($x, $y) { $x <=> $y };

# new & bless
{

    # passing a hashref
    my $d = Hash->bless({foo => 1, bar => 2});
    is($d, $ishash,              'bless');
    is($d, {foo => 1, bar => 2}, 'content of $d');

    # blessing an existing ref
    my $d2 = {foo => 1, bar => 2};
    is(blessed($d2), undef, ' not blessed');
    Hash->bless($d2);
    is($d2, $ishash,              '$d2 now blessed');
    is($d2, {foo => 1, bar => 2}, 'content of $d2');

    # new without arguments
    my $d3 = Hash->new;
    $d3->set(foo => 1);
    is($d3, $ishash,    '$d3 is Hash');
    is($d3, {foo => 1}, 'content of $d3');

    # new with many arguments
    my $d4 = Hash->new(foo => 1, bar => 2);
    is($d4, $ishash,              '$d4 is Hash');
    is($d4, {foo => 1, bar => 2}, 'content of $d4');

    # one argument - not hashref
    like(
        dies { Hash->bless("foo") },
        qr/\AHash\-\>bless/,
        'one argument not hashref dies'
    );

    # new with uneven arguments
    like(
        dies { Hash->new(foo => 1, "bar") },
        qr/\AHash\-\>new/,
        'uneven arguments dies'
    );

}

# empty
{
    is(Hash->empty,   $ishash, 'empty');
    is(Hash->empty,        {}, 'empty hash');
    is(Hash->new, Hash->empty, 'new() same as empty');
}

# set
{
    my $h = Hash->empty;

    $h->set(foo => 1);
    is($h, {foo => 1}, 'content of $h 1');

    $h->set(bar => 2, baz => 3);
    is($h, {foo => 1, bar => 2, baz => 3}, 'content of $h 2');

    like(
        dies { $h->set(maz => 1, "raz") },
        qr/\AHash\-\>set/,
        'Hash->set with uneven arguments dies.'
    );
}

my $data = Hash->bless({
    foo => 1,
    bar => 10,
    baz => 5,
});

# keys & values
is($data->keys->sort($by_str),   [qw/bar baz foo/], 'check keys');
is($data->values->sort($by_num), [1, 5, 10],        'check values');

# map
my $data2 = $data->map(sub($k,$v) {
    return ($k . 's'), $v * 2;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data2, {foos => 2, bars => 20, bazs => 10}, 'map');
is($data2, $ishash,                             '$data2 isa Hash');

# filter
my $data3 = $data->filter(sub($k,$v) {
    $k =~ m/\A b/xms ? 1 : 0;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data3, {bar => 10, baz => 5},               'filter');
is($data3, $ishash,                             '$data3 isa Hash');

# fold
is($data->fold(0, sub($state, $k, $v) { $state + $v }), 16, 'fold 1');
is($data->fold(1, sub($state, $k, $v) { $state + $v }), 17, 'fold 2');

is($data->count, 3, 'count');

# union, append, intersection, difference
{
    my $h = Hash->new(foo => 1, bar => 2);
    my $i = Hash->new(bar => 3, baz => 4);

    is(
        $h->union($i, sub($v1, $v2) { $v1 + $v2 }),
        { foo => 1, bar => 5, baz => 4 },
        'union'
    );

    is(
        $h->append($i),
        { foo => 1, bar => 3, baz => 4 },
        'append'
    );

    is(
        $h->intersection($i, sub($x,$y) { [$x,$y] }),
        { bar => [2,3] },
        'intersection'
    );

    is(
        $h->difference($i),
        { foo => 1 },
        'difference'
    );
}

# concat
{
    # as constructor
    is(
        Hash::concat(
            { foo => 1, bar => 2, t => 0 },
            { bar => 3, baz => 4 },
            { maz => 5, foo => 6 },
            { kaz => 7, baz => 8 },
        ),
        { foo => 6, bar => 3, baz => 8, maz => 5, kaz => 7, t => 0 },
        'concat 1'
    );

    # as method call
    is(
        Hash->new(foo => 1, bar => 2, t => 0)->concat(
            { bar => 3, baz => 4 },
            { maz => 5, foo => 6 },
            { kaz => 7, baz => 8 },
        ),
        { foo => 6, bar => 3, baz => 8, maz => 5, kaz => 7, t => 0 },
        'concat 2'
    );
}

is(
    Hash->new(foo => 1)->is_subset_of({ foo => 1, bar => 2 }),
    1,
    'is_subset_of 1'
);

is(
    Hash::is_subset_of(
        { foo => 1           },
        { foo => 1, bar => 2 }
    ),
    1,
    'is_subset_of 2'
);

is(
    Hash::is_subset_of(
        { foo => 1           },
        { bar => 1, baz => 2 }
    ),
    0,
    'is_subset_of 3'
);

my $tuple = sub($x,$y) { [$x,$y] };
is(Hash::difference({}, { foo => 1 })->is_empty,                 1, 'is_empty 1');
is(Hash::intersection({foo => 1}, {bar => 2}, $tuple)->is_empty, 1, 'is_empty 2');
is(Hash::union({}, {}, $tuple)->is_empty,                        1, 'is_empty 3');
is(Hash::append({}, {})->is_empty,                               1, 'is_empty 4');
is(Hash->empty->is_empty,                                        1, 'is_empty 5');
is(Hash->new->is_empty,                                          1, 'is_empty 6');
is(Hash->bless({})->is_empty,                                    1, 'is_empty 7');
is(Hash::difference({foo => 1}, {foo => 1})->is_empty,           1, 'is_empty 8');
is(Hash::concat({}, {}, {})->is_empty,                           1, 'is_empty 9');

# get, set, extract
{
    my $h = Hash->new(foo => 1, bar => 2, baz => 3);
    is($h->get(foo => 0), 1, 'get 1');
    is($h->get("bar", 0), 2, 'get 2');
    is($h->get("baz", 0), 3, 'get 3');
    is($h->get("maz", 0), 0, 'get 4');

    # set
    $h->set(bar => 4);
    is($h->get("bar", 0), 4, 'set');

    # extract
    is($h->extract(0, qw/foo latz bar/), [1, 0, 4], 'extract');
}

# push
{
    my $h = Hash->new;
    $h->push(foo => 1);
    $h->push(foo => 2);
    $h->push(foo => 3);
    $h->push(bar => 1);
    $h->push(bar => 2);

    is($h, { foo => [1,2,3], bar => [1,2] }, 'push 1');

    $h->push(foo => 4, 5);
    $h->push(baz => 9, 10);

    is($h, {foo => [1..5], bar => [1,2], baz => [9,10]}, 'push 2');
}

# push 2
{
    my $h = Hash->new;

    $h->push(foo => [1,2,3]);
    is($h, {foo => [[1,2,3]]}, 'push2 1');

    $h->push(foo => [1,2,3]);
    is($h, {foo => [[1,2,3],[1,2,3]]}, 'push2 2');

    my $h2 = Hash->new;
    $h2->push(foo => [1,2,3],[1,2,3]);
    is($h2, {foo => [[1,2,3], [1,2,3]]}, 'push2 3');
}

# change
{
    my $h = Hash->new(
        foo => [1,2,3],
        bar => [4,5,6],
        baz => "string",
    );

    $h->change(
        foo => sub($value) { Array::sum($value) }
    );

    is($h, { foo => 6, bar => [4,5,6], baz => "string" }, 'change 1');

    $h->change(
        bar => sub($value) { Array::fold($value, 1, sub($s,$x) { $s * $x }) },
        baz => sub($value) { length $value },
        xxx => sub($value) { $value + 1    },
    );

    is($h, { foo => 6, bar => 120, baz => 6 }, 'change 2');
}

# with & withf
{
    my $h = Hash->new(foo => 1);
    my $i = $h->with(foo => 2, bar => 3);
    my $j = $h->with(bar => 2);
    my $k = $i->with(maz => 4);
    my $l = $k->with(bar => 2, ratatat => 1);
    my $m = $l->withf(
        bar => sub($x) { "x" x $x },
        maz => sub($x) { $x + 1   },
        xxx => sub($x) { $x + 1   },
    );

    is($h, {foo => 1},                                      'with 1');
    is($i, {foo => 2, bar => 3},                            'with 2');
    is($j, {foo => 1, bar => 2},                            'with 3');
    is($k, {foo => 2, bar => 3, maz => 4},                  'with 4');
    is($l, {foo => 2, bar => 2, maz => 4, ratatat => 1},    'with 5');
    is($m, {foo => 2, bar => "xx", maz => 5, ratatat => 1}, 'withf');
}

# copy
{
    my $h = Hash->new(foo => 2);
    my $i = $h->copy;

    $h->set(foo => 1);

    is($h, {foo => 1}, 'copy 1');
    is($i, {foo => 2}, 'copy 2');
}

# copy with limited keys
{
    my $h = Hash->new(
        foo => 1, bar => 2,
        baz => 3, maz => 4,
    );

    is(
        $h->copy(qw/foo bar/),
        { foo => 1, bar => 2 },
        'copy foo & bar');

    is(
        $h->copy(qw/foo baz/),
        { foo => 1, baz => 3 },
        'copy foo & baz');

    is( $h->copy('maz'),
        { maz => 4 },
        'copy only maz');
}

# with - with mutable values
{
    # because with() only makes shallow copies (yet - maybe change that?)
    # values that are references stay the same across copies

    my $h = Hash->new(foo => 1, bar => [1,2,3]);
    my $i = $h->with(foo => 2);
    $h->push(bar => 4);

    is($h, {foo => 1, bar => [1..4]}, 'with mutable 1');
    is($i, {foo => 2, bar => [1..4]}, 'with mutable 2');

    my $aref = $h->get(bar => []);
    push @$aref, 5;

    is($h, {foo => 1, bar => [1..5]}, 'with mutable 3');
    is($i, {foo => 2, bar => [1..5]}, 'with mutable 4');
}

# check if some functions return blessed Array
{
    my $h = Hash->new(c => 3, a => 1, d => 4, b => 2);
    is($h->keys->sort_str,   [qw/a b c d/], 'keys sorted');
    is($h->values->sort_num, [1..4],        'values sorted');
}

# iter
{
    my $h = Hash->new(foo => 1, bar => 2, maz => 3);

    my $key;
    my $sum = 0;
    $h->iter(sub($k,$v) {
        $key .= $k;
        $sum += $v;
    });

    is($sum, 6, 'iter 1');

    # as a hash has random order, we don't know which key gets appended
    # in which order. The regex just lists all possible combinations that
    # are possible and checks for it
    my $key_re = qr/
        \A
        foobarmaz | foomazbar |
        barfoomaz | barmazfoo |
        mazfoobar | mazbarfoo
        \z
    /xms;

    like($key, $key_re, 'iter 2');
}

# bind
{
    my $h = Hash->new(
        foo => {
            name => 'test',
            no   => 1,
        },
        bar => {
            name => 'hello',
            no   => 2,
        },
    );

    my $i = $h->bind(sub($key, $value){
        my ($name, $no) = ($value->{name}, $value->{no});
        return {
            $key . '_name' => $name,
            $key . '_no'   => $no,
        }
    });

    is(
        $i,
        {
            foo_name => 'test',
            foo_no   => 1,
            bar_name => 'hello',
            bar_no   => 2.
        },
        'bind'
    );
}

# to_array / from_array
{
    my $h = Hash->new(foo => 1, bar => 2, baz => 3);
    my $a =
        $h
        ->to_array(sub($k,$v) { [$k,$v] })
        ->sort(sub($x,$y) { $x->[0] cmp $y->[0] });

    is($a, [["bar",2],["baz",3],["foo",1]], 'to_array');

    my $j = Hash->from_array($a, sub($i,$v) {
        return $v->[0], $v->[1];
    });
    is($j, $h, 'from_array 1');

    my $k = Hash->from_array($a, sub($i,$v) {
        return $i, $v;
    });
    is($k, {0 => [bar=>2], 1 => [baz=>3], 2 => [foo=>1]}, 'from_array 2');
}

# equal
{
    my $h = Hash->new(foo => 1);
    my $i = Hash->new(foo => 1);

    ok($h->equal($i), 'equal');
    ok(!$h->equal($i->with(test => 1)), 'not equal');

    # set a shared array
    my $shared = [1,2,3];
    $h->set(array => $shared);
    $i->set(array => $shared);
    ok($h->equal($i), 'equal because same reference');

    # replace a shared array, but same data
    $i->set(array => [1,2,3]);
    ok(!$h->equal($i), 'no recursive comparision yet');

    # same keys, but different data
    $h->set(array => "foo");
    $i->set(array => "foo");
    ok($h->equal($i), 'same again');

    # one has one more key
    $h->set(new => 1);
    ok(!$h->equal($i), 'not equal because $h has one more key');

    # delete additional keys
    $h->delete(qw/array new/);
    $i->delete('array');
    ok($h->equal($i), 'same after delete');

    # comparing with plain hash
    ok($h->equal({foo => 1}), 'equal perl hash');

    # two perl hashes
    ok(Hash::equal({foo => 1}, {foo => 1}), 'two perl hashes');
}

# find
{
    my $data = Hash->new(
        1  => 'foo',
        2  => 'bar',
        10 => 'baz',
    );

    is(
        [ $data->find("not found", sub($k,$v){ return $k >= 10 ? 1 : 0 }) ],
        [ 10 => 'baz' ],
        'find baz');

    is(
        [ $data->find("not found", sub($k,$v){ return $k < 2 ? 1 : 0 }) ],
        [ 1 => 'foo' ],
        'find foo');

    is(
        [ $data->find("not found", sub($k,$v){ return $k > 100 ? 1 : 0 }) ],
        ["not found"],
        'not found');

    is(
        $data->pick(sub($k,$v){ return $k >= 10 ? [$k,$v] : undef}),
        [10 => 'baz'],
        'pick baz');

    is(
        $data->pick(sub($k,$v){ return $k < 2 ? [$k,$v] : undef}),
        [ 1 => 'foo' ],
        'pick foo');

    is(
        $data->pick(sub($k,$v){ return $k > 100 ? [$k,$v] : undef}),
        undef,
        'pick did not found anything');
}

# on & has_keys
{
    my $data = Hash->new(
        foo => 1,
        bar => Array->new(1..5),
        baz => Array->new(
            Hash->new(name => "one"),
            Hash->new(name => "two"),
        ),
        raz => undef,
    );

    is($data->has_keys(qw/foo/),             1, 'has_keys foo');
    is($data->has_keys(qw/foo bar baz/),     1, 'has_keys foo,bar,baz');
    is($data->has_keys(qw/foo bar baz raz/), 0, 'has_keys foo,bar,baz,raz');
    is($data->has_keys(qw/foo bar maz/),     0, 'has_keys foo,bar,maz');

    my $extract_foo;
    $data->on(foo => sub($x) { $extract_foo = $x });
    is($extract_foo, 1, 'on foo: is 1');

    my $sum_bar;
    $data->on(bar => sub($array) { $sum_bar = $array->sum });
    is($sum_bar, 15, 'on bar: sum of array');

    my $str_concat;
    $data->on(baz => sub($array) {
        $array->map(sub($hash) { $str_concat .= $hash->get('name',"") })
    });

    is(
        $str_concat,
        $data->{baz}->map(sub($h){ $h->get('name',"") })->str_join(""),
        "on baz: string concat 1");
    is(
        $str_concat,
        $data->{baz}->fold("", sub($str,$h) { $str .= $h->get('name',"") }),
        "on baz: string concat 2");

    my $calls = 0;
    $data->on(maz => sub($x) { $calls = 1 });
    is($calls, 0, 'on maz: lambda not called');

    $data->on(raz => sub($x) { $calls = 1 });
    is($calls, 0, 'on raz: lambda not called');
}

done_testing;
