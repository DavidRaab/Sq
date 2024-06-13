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
    );

    is($h, { foo => 6, bar => 120, baz => 6 }, 'change 2');
}

# with
{
    my $h = Hash->new(foo => 1);
    my $i = $h->with(foo => 2, bar => 3);
    my $j = $h->with(bar => 2);
    my $k = $i->with(maz => 4);
    my $l = $k->with(bar => 2, ratatat => 1);

    is($h, {foo => 1},                                   'with 1');
    is($i, {foo => 2, bar => 3},                         'with 2');
    is($j, {foo => 1, bar => 2},                         'with 3');
    is($k, {foo => 2, bar => 3, maz => 4},               'with 4');
    is($l, {foo => 2, bar => 2, maz => 4, ratatat => 1}, 'with 5');
}

# copy
{
    my $h = Hash->new(foo => 2);
    my $i = $h->copy;

    $h->set(foo => 1);

    is($h, {foo => 1}, 'copy 1');
    is($i, {foo => 2}, 'copy 2');
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

done_testing;
