#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

# new & bless
{

    # passing a hashref
    my $d = Hash->new(foo => 1, bar => 2);
    check_isa($d, 'Hash', 'bless');
    is($d, {foo => 1, bar => 2}, 'content of $d');

    # blessing an existing ref
    my $d2 = {foo => 1, bar => 2};
    is(Scalar::Util::blessed($d2), undef, ' not blessed');
    Hash->bless($d2);
    check_isa($d2, 'Hash',           '$d2 now blessed');
    is($d2, {foo => 1, bar => 2}, 'content of $d2');

    # new without arguments
    my $d3 = Hash->new;
    $d3->set(foo => 1);
    check_isa($d3, 'Hash', '$d3 is Hash');
    is($d3, {foo => 1},    'content of $d3');

    # new with many arguments
    my $d4 = Hash->new(foo => 1, bar => 2);
    check_isa($d4, 'Hash',        '$d4 is Hash');
    is($d4, {foo => 1, bar => 2}, 'content of $d4');
}

# empty
{
    check_isa(Hash->empty, 'Hash', 'empty');
    is(Hash->empty,        {}, 'empty hash');
    is(Hash->new, Hash->empty, 'new() same as empty');
}

# set
{
    my $h = hash;

    $h->set(foo => 1);
    is($h, {foo => 1}, 'content of $h 1');

    $h->set(bar => 2, baz => 3);
    is($h, {foo => 1, bar => 2, baz => 3}, 'content of $h 2');
}

my $data = hash(
    foo => 1,
    bar => 10,
    baz => 5,
);

# keys & values
is($data->keys->sort(by_str),   [qw/bar baz foo/], 'check keys');
is($data->values->sort(by_num), [1, 5, 10],        'check values');

# map
my $data2 = $data->map(sub($k,$v) {
    return ($k . 's'), $v * 2;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data2, {foos => 2, bars => 20, bazs => 10}, 'map');
check_isa($data2, 'Hash',                       '$data2 isa Hash');

my $data3 = $data->keep(sub($k,$v) {
    $k =~ m/\A b/xms ? 1 : 0;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data3, {bar => 10, baz => 5},               'keep');
check_isa($data3, 'Hash',                       '$data3 isa Hash');

{
    my $player_points = hash(
        Anne   => 10,
        Marie  => 12,
        Ralph  => 8,
        Rudolf => 9,
    );

    is(
        $player_points->keep(sub($k,$v) { $v > 9 ? 1 : 0 }),
        { Anne => 10, Marie => 12 },
        'above 9');

    is(
        $player_points->keep(sub($k,$v) { $k =~ m/\AR/ }),
        { Ralph => 8, Rudolf => 9 },
        'players starting with R');

    is(
        $player_points->keep(sub($k,$v) { $v > 100 ? 1 : 0 }),
        { },
        'above 100');
}

# fold
is($data->fold(0, sub($k,$v,$state) { $state + $v }), 16, 'fold 1');
is($data->fold(1, sub($k,$v,$state) { $state + $v }), 17, 'fold 2');

is($data->fold_back(0, sub($state,$k,$v) { $state + $v }), 16, 'fold_back 1');
is($data->fold_back(1, sub($state,$k,$v) { $state + $v }), 17, 'fold_back 2');

is($data->length, 3, 'length');

# union, append, intersection, difference
{
    my $h = hash(foo => 1, bar => 2);
    my $i = hash(bar => 3, baz => 4);

    is(
        $h->union($i, sub($k, $v1, $v2) { $v1 + $v2 }),
        { foo => 1, bar => 5, baz => 4 },
        'union'
    );

    is(
        $h->append($i),
        { foo => 1, bar => 3, baz => 4 },
        'append'
    );

    is(
        $h->intersect($i, sub($k,$x,$y) { [$x,$y] }),
        { bar => [2,3] },
        'intersect 1'
    );

    is(
        $h->intersect($i, sub($k,$x,$y) { $x > $y ? $x : $y }),
        { bar => 3 },
        'intersect 2'
    );

    is($h->diff($i), { foo => 1 }, 'diff');
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
        hash(foo => 1, bar => 2, t => 0)->concat(
            { bar => 3, baz => 4 },
            { maz => 5, foo => 6 },
            { kaz => 7, baz => 8 },
        ),
        { foo => 6, bar => 3, baz => 8, maz => 5, kaz => 7, t => 0 },
        'concat 2'
    );
}

is(
    hash(foo => 1)->is_subset_of({ foo => 1, bar => 2 }),
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

is(Hash::diff({}, { foo => 1 })->is_empty,                       1, 'is_empty 1');
is(Hash::intersect({foo => 1}, {bar => 2}, \&array)->is_empty,   1, 'is_empty 2');
is(Hash::union({}, {}, \&array)->is_empty,                       1, 'is_empty 3');
is(Hash::append({}, {})->is_empty,                               1, 'is_empty 4');
is(Hash->empty->is_empty,                                        1, 'is_empty 5');
is(Hash->new->is_empty,                                          1, 'is_empty 6');
is(Hash->bless({})->is_empty,                                    1, 'is_empty 7');
is(Hash::diff({foo => 1}, {foo => 1})->is_empty,                 1, 'is_empty 8');
is(Hash::concat({}, {}, {})->is_empty,                           1, 'is_empty 9');

# get, set, extract
{
    my $h = hash(foo => 1, bar => 2, baz => 3);
    is($h->get("foo"), Some(1), 'get 1');
    is($h->get("bar"), Some(2), 'get 2');
    is($h->get("baz"), Some(3), 'get 3');
    is($h->get("maz"),   None, 'get 4');

    # set
    $h->set(bar => 4);
    is($h->get("bar"), Some(4), 'set');

    # extract
    is($h->extract(qw/foo latz bar/),  [Some(1), None, Some(4)], 'extract 1');
    is($h->extract(qw/foo latz bar/)->all_some,            None, 'extract 2');
    is($h->extract(qw/foo bar/)     ->all_some,    Some([1, 4]), 'extract 3');
    is($h->extract(qw/foo latz bar/)->keep_some,         [1, 4], 'extract 4');
}

# push
{
    my $h = hash;
    $h->push(foo => 1);
    $h->push(foo => 2,3);
    $h->push(bar => 1);
    $h->push(bar => 2);

    is($h, { foo => [1,2,3], bar => [1,2] }, 'push 1');

    $h->push(foo => 4, 5);
    $h->push(baz => 9, 10);

    is($h, {foo => [1..5], bar => [1,2], baz => [9,10]}, 'push 2');

    # testing with plain perl array or Array
    my $t1 = hash(id => 1, tags => ['foo']);
    my $t2 = hash(id => 2, tags => array('foo'));

    $t1->push(tags => 'bar');
    $t2->push(tags => 'bar');

    is($t1, {id => 1, tags => [qw/foo bar/]}, 'push onto plain perl array');
    is($t2, {id => 2, tags => [qw/foo bar/]}, 'push onto Sq Array');
    check_isa($t1->{tags}, 'Array', 'pushin on perl plain array adds blessing');

    # testing "upgrade"
    my $data = hash(
        id   => 1,
        tags => 'one',
    );
    $data->push(tags => 'two');

    is($data, {
        id => 1,
        tags => ['one', 'two'],
    }, 'pushing on not array, turns it into an array');

    $data->change(tags => call 'join', ',');
    is($data, {
        id => 1,
        tags => 'one,two',
    }, 'pod example');
}

# push 2
{
    my $h = hash;

    $h->push(foo => [1,2,3]);
    is($h, {foo => [[1,2,3]]}, 'push2 1');

    $h->push(foo => [1,2,3]);
    is($h, {foo => [[1,2,3],[1,2,3]]}, 'push2 2');

    my $h2 = hash;
    $h2->push(foo => [1,2,3],[1,2,3]);
    is($h2, {foo => [[1,2,3], [1,2,3]]}, 'push2 3');
}

# push with reduce
{
    # copy of the initial value, this is used because $data are mutated
    # and we can easily test when $data is reseted to initial state
    my $initial = [
        {id => 1, name => "foo", tags => "one"   },
        {id => 1, name => "foo", tags => "two"   },
        {id => 1, name => "foo", tags => "three" },
    ];

    my $data = array(
        hash(id => 1, name => "foo", tags => "one"),
        hash(id => 1, name => "foo", tags => "two"),
        hash(id => 1, name => "foo", tags => "three"),
    );

    # we can reduce and use push
    my $entry = $data->reduce(sub($x,$y) { $x->push(tags => $y->{tags}); $x });

    is($entry, Some({
        id   => 1,
        name => "foo",
        tags => [qw/one two three/],
    }), 'reducing with a push');

    # but be aware that push mutates an entry, not creates a new element
    is($data, [
        {id => 1, name => "foo", tags => [qw/one two three/]},
        {id => 1, name => "foo", tags => "two"              },
        {id => 1, name => "foo", tags => "three"            },
    ], 'push mutates');

    # reset first entry
    $data->[0] = hash(id => 1, name => "foo", tags => "one");
    is($data, $initial, 'reset');

    # otherwise it makes sense to use 'fold' to provide the initial new/empty element
    my $entry2 = $data->fold(hash(), sub($x,$state) {
        $state->set(
            id => $x->{id},
            name => $x->{name},
        );
        $state->push(tags => $x->{tags});
        return $state;
    });
    is($data, $initial, '$data does not mutate');
    is($entry2, {id => 1, name => 'foo', tags => [qw/one two three/]}, 'fold push');

    # we also could use fold_mut instead as we anyway mutate a reference. so
    # we can omit the return statement in the lambda.
    my $entry3 = $data->fold_mut(hash(), sub($x,$state) {
        $state->set(
            id   => $x->{id},
            name => $x->{name},
        );
        $state->push(tags => $x->{tags});
    });
    is($data, $initial, '$data does not mutate');
    is($entry3, {id => 1, name => 'foo', tags => [qw/one two three/]}, 'fold_mut push');

    # we also could copy those fields that we think that don't change. so we don't need
    # to call ->set in the lambda
    my $entry4 = $data->fold_mut(
        $data->[0]->slice(qw/id name/), # creates inital $state as a copy of first Hash
        sub($x,$state) {
            $state->push(tags => $x->{tags});
        }
    );
    is($data, $initial, '$data does not mutate');
    is($entry4, {id => 1, name => 'foo', tags => [qw/one two three/]}, 'fold_mut copy and push');

    # or we do the creation completely different, we compute the tags array from all data
    my $entry5 = hash(
        id   => $data->[0]->{id},
        name => $data->[0]->{name},
        tags => $data->map(key 'tags'),
    );
    is($data, $initial, '$data does not mutate');
    is($entry5, {id => 1, name => 'foo', tags => [qw/one two three/]}, 'Hash->new with $data->map');
}

# change
{
    my $h = hash(
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

# change pod example
{
    my $hash = hash(
        name   => 'Anne',
        age    => 20,
        points => 100,
    );

    $hash->change(
        name   => sub($name)   { $name . $name     },
        age    => sub($age)    { $age    + 1       },
        points => sub($points) { $points + 10      },
        what   => sub($what)   { Array::sum($what) },
    );

    is($hash, { name => 'AnneAnne', age => 21, points => 110 }, 'pod example 1');
}

# with & withf
{
    my $h = hash(foo => 1);
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

    my $points = hash(Anne => 10, Frank => 3);
    is(
        $points->withf(Anne  => sub($points) { $points + 1 }),
        { Anne => 11, Frank => 3 },
        'pod example 1');
    is(
        $points->withf(Frank => sub($points) { $points + 1 }),
        { Anne => 10, Frank => 4 },
        'pod example 2');

    my $games = hash(
        n64  => array("Mario 64", "Zelda"),
        snes => array("Super Mario Kart", "Street Fighter 2"),
    );
    is(
        $games->withf(
            n64  => call('join', ','),
            snes => call('join', ','),
        ),
        { n64 => "Mario 64,Zelda", snes => "Super Mario Kart,Street Fighter 2" },
        'pod example 3');

    is(
        $games->withf(
            n64  => call('join', ','),
            snes => call('join', ','),
            blub => call('join', ','),
        ),
        { n64 => "Mario 64,Zelda", snes => "Super Mario Kart,Street Fighter 2" },
        'not existing keys are ignored');
}

# copy
{
    my $h = hash(foo => 2);
    my $i = $h->copy;

    $h->set(foo => 1);

    is($h, {foo => 1}, 'copy 1');
    is($i, {foo => 2}, 'copy 2');
}

# slice
{
    my $h = hash(
        foo => 1, bar => 2,
        baz => 3, maz => 4,
    );

    is(
        $h->slice(qw/foo bar/),
        { foo => 1, bar => 2 },
        'copy foo & bar');

    is(
        $h->slice(qw/foo baz/),
        { foo => 1, baz => 3 },
        'copy foo & baz');

    is( $h->slice('maz'),
        { maz => 4 },
        'copy only maz');

    is(
        $h->slice(qw/foo barr/),
        { foo => 1 },
        'copy with a missing key');
}

# with - with mutable values
{
    # because with() only makes shallow copies (yet - maybe change that?)
    # values that are references stay the same across copies

    my $h = hash(foo => 1, bar => [1,2,3]);
    my $i = $h->with(foo => 2);
    $h->push(bar => 4);

    is($h, {foo => 1, bar => [1..4]}, 'with mutable 1');
    is($i, {foo => 2, bar => [1..4]}, 'with mutable 2');

    $h->get("bar")->map(sub($array) {
        $array->push(5);
    });

    is($h, {foo => 1, bar => [1..5]}, 'with mutable 3');
    is($i, {foo => 2, bar => [1..5]}, 'with mutable 4');
}

# check if some functions return blessed Array
{
    my $h = hash(c => 3, a => 1, d => 4, b => 2);
    is($h->keys  ->sort(by_str), [qw/a b c d/], 'keys sorted');
    is($h->values->sort(by_num), [1..4],        'values sorted');
}

# iter
{
    my $h = hash(foo => 1, bar => 2, maz => 3);

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
    my $h = sq {
        foo => {
            name => 'test',
            no   => 1,
        },
        bar => {
            name => 'hello',
            no   => 2,
        },
    };

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

    my $files = hash(
        etc => array(qw/fstab passwd crontab/),
        bin => array(qw/vim ls man ps/),
    );

    my $path_length = $files->bind(sub($folder,$files) {
        return $files->to_hash(sub($file) {
            my $path   = $folder . '/' . $file;
            my $length = length $path;
            return $path => $length;
        });
    });

    is(
        $path_length,
        {
            'etc/fstab'   => 9,
            'etc/passwd'  => 10,
            'etc/crontab' => 11,
            'bin/vim'     => 7,
            'bin/ls'      => 6,
            'bin/man'     => 7,
            'bin/ps'      => 6,
        },
        'bind 2');
}

# to_array / from_array
{
    my $h = hash(foo => 1, bar => 2, baz => 3);
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

    is(
        Hash->from_array([qw/Alice Anny Sola Candy Lilly/], sub($idx, $name) { $name => $idx }),
        {Alice => 0, Anny => 1, Sola => 2, Candy => 3, Lilly => 4},
        'pod example');
}

# equal
{
    my $h = hash(foo => 1);
    my $i = hash(foo => 1);

    ok($h->equal($i), 'equal');
    ok(!$h->equal($i->with(test => 1)), 'not equal');

    # set a shared array
    my $shared = [1,2,3];
    $h->set(array => $shared);
    $i->set(array => $shared);
    ok($h->equal($i), 'equal because same reference');

    # replace a shared array, but same data
    $i->set(array => [1,2,3]);
    ok($h->equal($i), 'recursive comparision');

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
    my $data = hash(
        1  => 'foo',
        2  => 'bar',
        10 => 'baz',
    );

    is(
        $data->find(sub($k,$v){ return $k >= 10 ? 1 : 0 }),
        Some([10 => 'baz']),
        'find baz');

    is(
        $data->find(sub($k,$v){ return $k < 2 ? 1 : 0 }),
        Some([ 1 => 'foo' ]),
        'find foo');

    is(
        $data->find(sub($k,$v){ return $k > 100 ? 1 : 0 }),
        None,
        'not found');

    is(
        $data
            ->find(sub($k,$v) { $k >= 10    })
            ->map(sub($array) { $array->[1] })  # Option::map
            ->or("whatever"),                   # Option::or
        'baz',
        'testing optional some case');

    is(
        $data
            ->find(sub($k,$v) { $k >= 100   })
            ->map(sub($array) { $array->[1] })  # Option::map
            ->or("whatever"),                   # Option::or
        'whatever',
        'testing optional none case');

    is(
        $data->pick(sub($k,$v){ return $k >= 10 ? Some([$k,$v]) : None}),
        Some([10 => 'baz']),
        'pick baz');

    is(
        $data->pick(sub($k,$v){ return $k < 2 ? Some [$k,$v] : None}),
        Some([ 1 => 'foo' ]),
        'pick foo');

    is(
        $data->pick(sub($k,$v){ return $k > 100 ? Some [$k,$v] : None}),
        None,
        'pick did not found anything');

    is(
        $data->pick(sub($k,$v){ $k > 9 ? Some($k * 2) : None}),
        Some(20),
        'pick returning string');
}

# on & has_keys
{
    my $data = sq {
        foo => 1,
        bar => [1..5],
        baz => [
            {name => "one"},
            {name => "two"},
        ],
        raz => undef,
    };

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
        $array->map(sub($hash) { $str_concat .= $hash->get('name')->or("") })
    });

    is(
        $str_concat,
        $data->{baz}->map(sub($h){ $h->get('name')->or("") })->join(""),
        "on baz: string concat 1");
    is(
        $str_concat,
        $data->{baz}->fold("", sub($h,$str) { $str .= $h->get('name')->or("") }),
        "on baz: string concat 2");

    my $calls = 0;
    $data->on(maz => sub($x) { $calls = 1 });
    is($calls, 0, 'on maz: lambda not called');

    $data->on(raz => sub($x) { $calls = 1 });
    is($calls, 0, 'on raz: lambda not called');
}

# on with multiple keys and functions
{
    my $movie = sq {
        title    => 'Terminator 2',
        tags     => [qw/cool/],
        liked_by => [qw/Anny/],
    };

    $movie->on(
        tags     => sub($tags)  { $tags ->push("classic") },
        liked_by => sub($liked) { $liked->push("Lilly")   },
    );

    is(
        $movie,
        {
            title    => 'Terminator 2',
            tags     => [qw/cool classic/],
            liked_by => [qw/Anny Lilly/],
        },
        'on with multiple keys');
}

# fold
{
    my $money = hash(
        Anne         => 100,
        Marie        => 50,
        Frankenstein => 250,
    );

    my $total_money = $money->fold(0, sub($name,$money,$state) {
        $state + $money;
    });
    is($total_money, 400, 'total money');

    my $player_names = $money->fold(array(), sub($name,$money,$state) {
        $state->push($name);
        $state;
    });
    is(
        $player_names->length,
        3,
        '3 names');

    my $is_name = sub($expected) { sub($got) { $got eq $expected } };
    is($player_names->find($is_name->('Anne')),         Some('Anne'),         'Contains Anne');
    is($player_names->find($is_name->('Marie')),        Some('Marie'),        'Contains Marie');
    is($player_names->find($is_name->('Frankenstein')), Some('Frankenstein'), 'Contains Frankenstein');
}

# init
{
    my $hash = Hash->init(5, sub($idx) {
        return $idx, $idx*$idx;
    });

    is(
        $hash,
        { 0 => 0, 1 => 1, 2 => 4, 3 => 9, 4 => 16 },
        'init');
}

# lock
{
    my $h = hash(
        name     => 'Anne',
        birthday => '1970-01-01',
    )->lock;

    my $orig = $h->copy;

    like(
        dies { $h->{age} = 12 },
        qr/\AAttempt to access disallowed key/,
        'setting new key dies after lock');

    is($h, $orig, 'still the same');

    like(
        dies { my $age = $h->{age} },
        qr/\AAttempt to access disallowed key/,
        'reading a not allowed key');

    $h->{name} = 'Marie';
    is($h, {name => "Marie", birthday => '1970-01-01' }, 'but mutation is allowed');

    # Second Hash
    my $j = hash(name => 'Zola')->lock(qw/hair_color/);

    $j->{hair_color} = 'black';
    is($j, {name => 'Zola', hair_color => 'black'}, 'additional key');
}

# get doesn't wrap an optional again
{
    my $movie = sq {
        title  => 'Terminator 2',
        rating => Some(5),
        descr  => None,
    };

    is($movie->get('title'),  Some('Terminator 2'), 'fetch title');
    is($movie->get('rating'), Some(5),              'fetch rating');
    is($movie->get('descr'),  None,                 'fetch descr');
}

# iter_sort
{
    my @data;
    sq({foo => 3, bar => 2, zap => 4, aaa => 1})->iter_sort(by_str, sub($k,$v) {
        push @data, [$k,$v];
    });
    is(
        \@data,
        [
            [aaa => 1],
            [bar => 2],
            [foo => 3],
            [zap => 4],
        ],
        'iter_sort');
}

# with_default()
{
    my $data = sq {
        title => "Greatest Hits",
    };

    # TODO: Consider that it doesn't make a copy of tracks for example,
    #       so re-using the same hash somewhere instead of directly inlining
    #       the hash in the function will create shared data over multiple values
    #       But i anyway plan to implement a global copy().
    my $album = $data->with_default(
        title  => "Unkown",
        desc   => "",
        artist => "Nobody",
        tracks => [
            { id => 1, duration => 10 },
        ],
    );

    is($data, { title => "Greatest Hits" }, '$data unchanged');
    is(
        $album,
        {
            title  => "Greatest Hits",
            desc   => "",
            artist => "Nobody",
            tracks => [
                { id => 1, duration => 10 },
            ],
        },
        'title stays, all other values added');

    # with() overwrites values, while with_default() keeps the values.
    my $album2 = $data->with(
        title  => "Unkown",
        desc   => "",
        artist => "Nobody",
        tracks => [
            { id => 1, duration => 10 },
        ],
    );

    is($data, { title => "Greatest Hits" }, '$data unchanged');
    is(
        $album2,
        {
            title  => "Unkown", # Now overwritten
            desc   => "",
            artist => "Nobody",
            tracks => [
                { id => 1, duration => 10 },
            ],
        },
        'title is overwritten');

    # with_default() checks for defined values. So keys that exists in a hash
    # but are undef are still overwritten. This is usually what i want. Undef
    # values are garbage
    is(
        Hash::with_default({name => "Hulu", Price => undef}, name => "Foo", Price => 10),
        {name => "Hulu", Price => 10},
        'with_default checks for defined values');

    is(
        Hash::with_default({name => "Hulu", Price => ""}, name => "Foo", Price => 10),
        {name => "Hulu", Price => 10},
        'with_default now also check types 1');

    is(
        Hash::with_default({name => "Hulu", Price => "Nope"}, name => "Foo", Price => 10),
        {name => "Hulu", Price => 10},
        'with_default now also check types 2');

    is(
        Hash::with_default(
            { name => "Hulu", Tracks => ""},
            name => "Foo", Tracks => []),
        {name => "Hulu", Tracks => []},
        'with_default now also check types 3');

    is(
        Hash::with_default(
            { name => "Hulu", Tracks => {}},
            name => "Foo", Tracks => []),
        {name => "Hulu", Tracks => []},
        'with_default now also check types 4');

    is(
        Hash::with_default(
            { name => "Hulu", Tracks => [{no => 1, name => "Yup"}]},
            name => "Foo", Tracks => []),
        {name => "Hulu", Tracks => [{no => 1, name => "Yup"}]},
        'with_default now also check types 5');
}

{
    my $data = sq {
        foo => [],
        bar => [1],
        baz => [1,2],
        maz => [1,2,3],
    };
    is(
        $data->remove(sub($k,$v) { $v->length < 2 }),
        {
            baz => [1,2],
            maz => [1,2,3],
        },
        'remove');
}

done_testing;
