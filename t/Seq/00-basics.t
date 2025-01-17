#!perl
use 5.036;
use Scalar::Util qw(refaddr);
use List::Util qw(reduce);
use Sq;
use Sq::Sig;
use Sq::Test;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $add     = sub($x, $y) { $x + $y     };
my $add1    = sub($x)     { $x + 1      };
my $double  = sub($x)     { $x * 2      };
my $square  = sub($x)     { $x * $x     };
my $is_even = sub($x)     { $x % 2 == 0 };

# Basic checks of range and rangeDesc
ok(defined $range,              'range returns something');
check_isa($range, 'Seq',        'returns a Seq');
is($range->to_array, [1 .. 10], 'to_array');
is($range->to_array, [1 .. 10], 'calling to_array twice still returns the same');
is(Seq->range(1,1)->to_array, [1], 'range is inclusive');
is($rangeDesc->to_array, [reverse 1 .. 10], 'rangeDesc');
is($range->to_array,     $rangeDesc->rev->to_array, 'reverse of rangeDesc same as range');

# to_array with a limit
is($range->to_array(0),   [],      'to_array(0)');
is($range->to_array(-1),  [],      'to_array(-1)');
is($range->to_array(1),   [1],     'to_array(1)');
is($range->to_array(5),   [1..5],  'to_array(5)');
is($range->to_array(100), [1..10], 'to_array(100)');

is($range->map($double),   seq { 2,4,6,8,10,12,14,16,18,20 }, 'map');
is($range->keep($is_even), seq { 2,4,6,8,10 },               'keep');

is($range->take(5),  seq{1..5}, 'take 1');
is($range->take(0),  seq {},    'take 2');
is($range->take(-1), seq {},    'take 3');
is($range->take(5) ->to_array, $range->to_array(5),  'take(x) same as to_array(x) 1');
is($range->take(0) ->to_array, $range->to_array(0),  'take(x) same as to_array(x) 2');
is($range->take(-1)->to_array, $range->to_array(-1), 'take(x) same as to_array(x) 3');


is($range->length, 10, 'length');
is($range->take(5)->length, 5, 'take & length');
is($range->map(sub($x) { undef }), Seq->empty, 'map function returns undef');
is(
    $range->map($square)->keep($is_even),
    seq { 4,16,36,64,100 },
    'map keep');
is(
    $range->map($square)->keep($is_even)->take(3),
    seq { 4,16,36 },
    'map keep take');
is(
    $range->fold(0, sub($x,$length) { $length + 1 }),
    $range->length,
    'fold with non-reftype');
is(
    $range->fold([], sub($x,$array) { push @$array, $x; $array }),
    $range->to_array,
    'fold with reftype 1');
is(
    $range->fold([], sub($x,$array) { [@$array, $x ] }),
    $range->to_array,
    'fold with reftype 2');
is(
    $range->fold    ([], sub($x,$array) { push @$array, $x; $array }),
    $range->fold_mut([], sub($x,$array) { push @$array, $x         }),
    'fold_mut');

check_isa($range->rev, 'Seq', 'rev return Seq');
is($range->rev, Seq->range(10,1), 'rev');
is(
    $range->rev->map($add1)->rev->to_array,
    [ $range->map($add1)->expand ],
    'expand');

is($range->sum, 55, 'sum');
is($range->sum, $range->rev->sum, 'sum 2');


# Checking new & rangeStep
{
    # Currently on undef it aborts, should it just skip the undef and return
    # the values from 1 to 6?
    is(Seq->new(1,2,3,undef,4,5,6), seq {1..3}, 'new containing an undef');
    is(Seq->new(5), seq {5}, 'new');
    is(
        seq { 5 }->append(seq { 10 }),
        seq { 5, 10 },
        'new and append');
    is(
        Seq->range(1,5)->append(Seq->range(6,10)),
        Seq->range(1,10),
        'append two ranges');
    is(Seq->range_step(1, 2, 10), seq { 1,3,5,7,9  }, '1 .. 10 step 2');
    is(Seq->range_step(10, 2, 1), seq { 10,8,6,4,2 }, '10 .. 1 step 2');
}

is(
    Seq::zip(
        seq { qw/A B C D E F/ },
        Seq->range(0, 1_000_000),
    ),
    Seq->new(qw/A B C D E F/)->indexed,
    'indexed');

is(
    $range->take(3)->indexed->to_array,
    [[1,0], [2,1], [3,2]],
    'take->indexed');
is(
    Seq->init(10, \&id)->map($add1),
    $range,
    'init->map');
is(
    Seq->range(1,10)->indexed,
    Seq->init(10, sub($idx) { [$idx+1,$idx ] }),
    'range->indexed vs. init');
is(
    (reduce { $a->append($b) } map { Seq->new($_) } 1 .. 10),
    $range,
    'append a list of wrapped values');
is(
    Seq->concat(map { Seq->new($_) } 1 .. 10),
    $range,
    'concat');
is(
    Seq->concat,
    Seq->empty,
    'concat on zero is empty');
is(
    Seq->new(Seq->range(1,10)->expand)->to_array,
    [1 .. 10],
    'expand and wrap is isomorph');
is(
    Seq->new(1..5)->append(
        Seq->new(6..10)
    ),
    Seq->concat(
        Seq->new(1..3),
        Seq->new(4..6),
        Seq->new(7..10),
    ),
    'append vs. concat');
is(
    Seq->empty->append(Seq->range(1,5))->append(Seq->range(6,10)),
    $range,
    'append on empty');
is(
    Seq->concat(
        Seq->empty,
        Seq->range(1,5),
        Seq->empty,
        Seq->range(10,12),
        Seq->empty,
        Seq->new("Hello"),
        Seq->empty
    ),
    Seq->new(1..5, 10..12, "Hello"),
    'concat with empties');
is(Seq->concat(seq { 1,2,3 }), seq { 1,2,3 }, 'concat 1');
is(
    Seq->concat(seq { 1,2,3 }, seq { 4,5,6 }),
    seq { 1 .. 6 },
    'concat 2');
is(
    Seq::zip(
        Seq->concat(
            Seq->range(1,1_000_000_000),
            Seq->range(1,1_000_000_000),
        ),
        Seq->concat(
            Seq->range(1,1_000_000_000),
            Seq->range(1,1_000_000_000),
        )
    )->chunked(10)->take(3),
    seq {
        [map { [$_,$_] }  1..10],
        [map { [$_,$_] } 11..20],
        [map { [$_,$_] } 21..30],
    },
    'concat, zip, chunked');
is(
    Seq->from_array([1..10]),
    Seq->new(1..10),
    'from_array and wrap');
is(
    Seq->unfold(10, sub($state) {
        if ( $state > 0 ) {
            return $state, $state-1;
        }
        else {
            return undef;
        }
    }),
    Seq->range(1,10)->rev,
    'unfold');
is(
    Seq->new,
    Seq->empty,
    'wrap without arguments same as empty');

# concat tests
{
    is(Seq->concat,         Seq->empty, 'Empty concat');
    is(Seq->concat($range), $range,     'concat with 1 element');
    is(
        Seq->concat(
            Seq->range(1,5),
            Seq->range(6,10),
        ),
        Seq->range(1,10),
        'concat with 2 elemets');
    is(
        Seq->concat(
            Seq->range(1,5),
            Seq->range(6,10),
            Seq->range(11,15),
        ),
        Seq->range(1,15),
        'concat with 3 elements');
}

is($range->skip(0),   seq {1..10}, 'skip(0)');
is($range->skip(-1),  seq {1..10}, 'skip(-1)');
is($range->skip(-10), seq {1..10}, 'skip(-10)');
is($range->skip(100), seq {     }, 'skip(100)');

is($range->skip(3)->take(3),  seq { 4,5,6 }, 'skip->take 1');
is($range->skip(3)->take(10), seq { 4..10 }, 'skip->take 2');
is($range->skip(10)->take(1), seq {       },  'skip->take 3');

is($range->take(0),   Seq->empty, 'take(0)');
is($range->take(-1),  Seq->empty, 'take(-1)');
is($range->take(-10), Seq->empty, 'take(-10)');
is($range->take(100), $range,     'take(100)');

is($range->take(5)->skip(2), seq {3,4,5}, 'take->skip 1');
is($range->take(5)->skip(4), seq {5    },  'take->skip 2');
is($range->take(5)->skip(6), seq {     },  'take->skip 2');

is(
    Seq->concat(
        Seq->range(1,10),
        Seq->range(10,1),
    ),
    Seq->concat(
        $range,
        $range->rev
    ),
    'concat with rev');

is(Seq->new([A => 1], [B => 2], [C => 3])->sum_by(\&snd), 6, 'sumBy');
is(
    seq{qw/H e l l o W o r l d !/}->join('-'),
    "H-e-l-l-o-W-o-r-l-d-!",
    'join 1');
is(
    seq{qw/H e l l o W o r l d !/}->join,
    "HelloWorld!",
    'join 2');

is(
    Seq->new(qw/Hello World you are awesome/)->to_hash(sub($x) { length $x => $x }),
    {
        5 => "World",
        3 => "are",
        7 => "awesome",
    },
    'to_hash 1');

is(
    Seq->new(qw/Hello World you are awesome/)->to_hash(sub($x) { $x => length $x }),
    {
        "Hello"   => 5,
        "World"   => 5,
        "you"     => 3,
        "are"     => 3,
        "awesome" => 7,
    },
    'to_hash 2');

is(
    Seq->new(qw/Hello World you are awesome/)->to_hash_of_array(sub($x) { length $x => $x }),
    {
        5 => [ "Hello",   "World" ],
        3 => [ "you",     "are"   ],
        7 => [ "awesome",         ],
    },
    'to_hash_of_array');

is(Seq->new(1,1,2,3,1,4,5,4,3,2,6)       ->distinct, seq {1..6},               'distinct 1');
is(Seq->new(1,2,3,2,23,123,4,12,2)       ->distinct, seq {1,2,3,23,123,4,12},  'distinct 2');
is(Seq->new(1,2,3,3,4,2,1,5,6,5,4,7,10,8)->distinct, seq {1,2,3,4,5,6,7,10,8}, 'distinct 3');

# distinct_by tests
{
    my $data = seq {
        {id => 1, name => "Foo"},
        {id => 2, name => "Bar"},
        {id => 3, name => "Baz"},
        {id => 1, name => "Foo"},
    };

    is($data->length, 4, 'distinct_by starts with 4');
    is($data->distinct->length, 4, 'still 4 as HashRefs are always unequal');
    is($data->distinct_by(sub($x) { $x->{id} })->length, 3, 'one element less');
    is(
        $data->distinct_by(sub($x) { $x->{id} }),
        seq {
            {id => 1, name => "Foo"},
            {id => 2, name => "Bar"},
            {id => 3, name => "Baz"},
        },
        'check elements and order');
}

is(
    Seq->new(qw/A B C D E F/)->mapi(sub($x,$i) { [$x,$i] }),
    seq { [A => 0], [B => 1], [C => 2], [D => 3], [E => 4], [F => 5] },
    'mapi');

is(Seq->init( 0,  sub($idx) { $idx }), Seq->empty, 'init with length 0');
is(Seq->init(-1,  sub($idx) { $idx }), Seq->empty, 'init with length -1');
is(Seq->init(-10, sub($idx) { $idx }), Seq->empty, 'init with length -10');
is(Seq->range_step(1,1,1), seq { 1 }, 'range_step with 1,1,1');

# TODO
# is(
#     Seq->range_step(0,0.1,1)->to_array,
#     [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1],
#     'range_step with 0,0.1,1');

like(
    dies { Seq->range_step(0,0,1)->to_array },
    qr/^\$step is 0/,
    'range_step dies with step size of zero');

is(
    $range->map($square)->keep($is_even),
    $range->choose(sub($x) {
        my $s = $x * $x;
        $s % 2 == 0 ? Some $s : None
    }),
    'choose same as map->keep');

is(
    $range->choose(sub($x) {
        my $s = $x * $x;
        $s % 2 == 0 ? Some $s : None
    }),
    seq { grep { $_ % 2 == 0 } map { $_ * $_ } 1 .. 10 },
    'Non Lazy Perl implementation of choose');


is($range->find(sub($x) { $x > 5  }),   Some(6), 'find 1');
is($range->find(sub($x) { $x > 10 }),      None, 'find 2');
is($range->find(sub($x) { $x > 10 })->or(0),  0, 'find 3');

is(
    $range->bind(sub($x) { Seq->new($x) }),
    Seq->range(1,10),
    'bind - somehow like id');

is(
    Seq->new(
        Seq->new(1,1),
        Seq->new(2,3,5,8,13),
    )->flatten,
    seq {1,1,2,3,5,8,13},
    'flatten - flattens a seq of seq');

is(Seq->new([1,1], [1,2])->to_array, [[1,1],[1,2]], 'wrap with arrays');
is(Seq->new([1,1])       ->to_array, [[1,1]],       'wrap with array');
is(Seq->from_array([1,1]) ->to_array, [1,1],         'from_array vs. wrap');

is($range->reduce($add),           Some(55), 'reduce');
is(Seq->empty->reduce($add),           None, 'reduce on empty 1');
is(Seq->empty->reduce($add)->or(0),       0, 'reduce on empty 2');
is(Seq->new(1)->reduce($add)->or(0),     1, 'reduce on single element');

is(Seq->empty->first,       None, 'first on empty');
is(Seq->empty->first->or(0),   0, 'first on empty with option::or');
is($range->first,        Some(1), 'first on non empty');
is($range->first->or(0),       1, 'first on non empty with option::or');

is(Seq->empty->last,         None, 'last on empty');
is(Seq->empty->last->or(0),     0, 'last on empty with option:or');
is($range->last ,        Some(10), 'last on non empty');
is($range->last->or(0),        10, 'last on non empty with option::or');

is(Seq->new(1,5,-3,10,9,-2) ->sort(by_num), [ -3,-2,1,5,9,10 ],  'sort 1');
is(Seq->new(qw/B b c A a C/)->sort(by_str), [ qw/A B C a b c/ ], 'sort 2');
check_isa(seq {3,2,1}->sort(by_num), 'Array', 'sort returns Array');

# Schwartzian Transformation
{
    my $data = seq {
        { id => 1, char => 'W' },
        { id => 4, char => 'L' },
        { id => 5, char => 'D' },
        { id => 2, char => 'O' },
        { id => 3, char => 'R' },
    };

    check_isa($data->sort_by(by_num, key 'id'), 'Array', 'sort_by return Array');

    is(
        $data->sort_by(by_num, key 'id'),
        [
            { id => 1, char => 'W' },
            { id => 2, char => 'O' },
            { id => 3, char => 'R' },
            { id => 4, char => 'L' },
            { id => 5, char => 'D' },
        ],
        'sort_by 1');

    is(
        $data->sort_by(by_str, key 'char'),
        [
            { id => 5, char => 'D' },
            { id => 4, char => 'L' },
            { id => 2, char => 'O' },
            { id => 3, char => 'R' },
            { id => 1, char => 'W' },
        ],
        'sort_by 2');

    is(
        $data->sort_by(by_num, key 'id')->map(key 'char')->join(""),
        'WORLD',
        'sort_by 3');

    is(
        $data
        ->map (sub($x)    { [$x->{id} ,  $x     ] })
        ->sort(sub($x,$y) {  $x->[0] <=> $y->[0]  })
        ->map (sub($x)    {  $x->[1]              }),

        $data->sort_by(by_num, key 'id'),
        'sort_by 3');
}


my $fs = Seq->new([1,"Hi"],[2,"Foo"],[3,"Bar"],[4,"Mug"]);
is($fs->fsts->to_array, [1,2,3,4],            'fsts');
is($fs->snds->to_array, [qw/Hi Foo Bar Mug/], 'snds');

is(
    Seq->new([1,2,3], [4,5,6], [7,8,9])->merge->to_array,
    [1..9],
    'flatten_array');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->new(qw(A B C D E F))
    )->to_array,
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/],[qw/5 E/],[qw/6 F/]],
    'zip 1');

is(
    Seq::zip(
        Seq->range(1,3),
        Seq->new(qw(A B C D E F))
    )->to_array,
    [[qw/1 A/],[qw/2 B/],[qw/3 C/]],
    'zip 2');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->new(qw(A B C D))
    )->to_array,
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/]],
    'zip 3');

is(
    Seq::zip(
        Seq->empty,
        Seq->new(qw(A B C D E F))
    )->to_array,
    [],
    'zip 4');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->empty,
    )->to_array,
    [],
    'zip 5');

is(
    Seq::zip(
        seq { 1,2,3    },
        seq { 4,5,6    },
        seq { 7,8,9    },
        seq { 10,11,12 },
    ),
    seq { [1,4,7,10], [2,5,8,11], [3,6,9,12] },
    'zip 6');

is(
    Seq::zip(
        seq { 1,2,3    },
        seq { 4,5,6,7  },
        seq { 7,8,9    },
        seq { 10,11,12 },
    ),
    seq { [1,4,7,10], [2,5,8,11], [3,6,9,12] },
    'zip 7');

is(
    Seq::zip(
        seq { 1,  2, 3       },
        seq { 4,  5, 6, 7    },
        seq { 7,  8, 9       },
        seq { 10,11,12,13,14 },
    ),
    seq { [1,4,7,10], [2,5,8,11], [3,6,9,12] },
    'zip 8');

is(
    seq {
        seq { 1,2,3 },
        seq { 4,5,6 },
        seq { 7,8,9 },
    }->to_array_of_array,
    [
        [1,2,3],
        [4,5,6],
        [7,8,9],
    ],
    'to_array_of_array');

is($range->any (sub($x) { $x < 1   }), 0, 'any value smaller 0');
is($range->any (sub($x) { $x < 2   }), 1, 'any value smaller 1');
is($range->all (sub($x) { $x < 1   }), 0, 'all values smaller 1');
is($range->all (sub($x) { $x < 11  }), 1, 'all values smaller 1');
is($range->none(sub($x) { $x > 1   }), 0, 'none value greater 1');
is($range->none(sub($x) { $x > 10  }), 1, 'none value greater 10');

is(
    $range->pick(sub($x) { $x*$x > 1000 ? $x*$x : undef }),
    None,
    'pick squared element that is greater 1000');
is(
    $range->pick(sub($x) { $x*$x > 1000 ? $x*$x : undef })->or("NO"),
    "NO",
    'pick squared element that is greater 1000');
is(
    $range->pick(sub($x) { $x*$x > 50 ? $x*$x : undef }),
    Some(64),
    'pick squared element that is greater 50');
is(
    $range->pick(sub($x) { $x*$x > 50 ? $x*$x : undef })->or(0),
    64,
    'pick squared element that is greater 50');

# rxm
{
    my $lines = seq {
        '2023-11-25T15:10:00',
        '2023-11-20T10:05:29',
        'xxxx-xx-xxT00:00:00',
        '1900-01-01T00:00:01',
        '12345678901234567890',
    };

    my $matches = $lines->rxm(qr/
        \A
            (\d\d\d\d) - (\d\d) - (\d\d)  # Date
        T                                 # T
            (\d\d) : (\d\d) : (\d\d)      # Time
        \z/xms
    )
    ->map(call 'slice', 2,1,0,3,4,5)
    ->map(sub($a) { sq [
        $a->slice(0,1,2)->join('.'),
        $a->slice(3,4,5)->join(':'),
    ]});

    is(
        $matches,
        seq {
            ["25.11.2023", "15:10:00"],
            ["20.11.2023", "10:05:29"],
            ["01.01.1900", "00:00:01"],
        },
        'rxm');

    is(
        $lines->rxm(qr/\A
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
        \z/xms),
        seq { [1 .. 9, 0, 1 .. 9, 0] },
        'check 20 matches');
}

is($range->windowed(-1), Seq->empty,                   'windowed -1');
is($range->windowed(0) , Seq->empty,                   'windowed 0');
is($range->windowed(1) , seq { map { [$_] } 1 .. 10 }, 'windowed 1');
is(
    $range->windowed(2),
    seq { [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10] },
    'windowed 2');
is(
    $range->windowed(5),
    seq {
        [1,2,3,4,5], [2,3,4,5,6], [3,4,5,6,7], [4,5,6,7,8], [5,6,7,8,9], [6,7,8,9,10]
    },
    'windowed 5');

is($range->windowed(10), seq { [1 .. 10] }, 'windowed 10');
is($range->windowed(11), seq { [1 .. 10] }, 'windowed 11');

is(Seq->new()     ->intersperse(0)->to_array, [],          'intersperse 1');
is(Seq->new(1)    ->intersperse(0)->to_array, [1],         'intersperse 2');
is(Seq->new(1,2)  ->intersperse(0)->to_array, [1,0,2],     'intersperse 3');
is(Seq->new(1,2,3)->intersperse(0)->to_array, [1,0,2,0,3], 'intersperse 4');
is(
    Seq->range(1,10)->intersperse(0)->to_array,
    [1,0,2,0,3,0,4,0,5,0,6,0,7,0,8,0,9,0,10],
    'intersperse 5');

is(Seq->always(5)->take(-1)->to_array, [],         'always 1');
is(Seq->always(5)->take(0) ->to_array, [],         'always 2');
is(Seq->always(5)->take(1) ->to_array, [5],        'always 3');
is(Seq->always(5)->take(10)->to_array, [(5) x 10], 'always 4');

is(Seq->new(5)    ->infinity->take(0) ->to_array, [],                    'infinity 1');
is(Seq->new(5)    ->infinity->take(1) ->to_array, [5],                   'infinity 2');
is(Seq->new(5)    ->infinity->take(5) ->to_array, [5,5,5,5,5],           'infinity 3');
is(Seq->new(1,2,3)->infinity->take(3) ->to_array, [1,2,3],               'infinity 4');
is(Seq->new(1,2,3)->infinity->take(6) ->to_array, [1,2,3,1,2,3],         'infinity 5');
is(Seq->new(1,2,3)->infinity->take(9) ->to_array, [1,2,3,1,2,3,1,2,3],   'infinity 6');
is(Seq->new(1,2,3)->infinity->take(10)->to_array, [1,2,3,1,2,3,1,2,3,1], 'infinity 7');

is(Seq->new(5)    ->repeat(-1)->to_array, [],            'repeat 1');
is(Seq->new(5)    ->repeat(0) ->to_array, [],            'repeat 2');
is(Seq->new(5)    ->repeat(1) ->to_array, [5],           'repeat 3');
is(Seq->new(5)    ->repeat(5) ->to_array, [5,5,5,5,5],   'repeat 4');
is(Seq->new(1,2,3)->repeat(2) ->to_array, [1,2,3,1,2,3], 'repeat 5');
is(Seq->new(1,2,3)->repeat(3) ->to_array, [(1,2,3) x 3], 'repeat 6');

is(Seq->replicate(10, 'A'), seq { ('A') x 10 }, 'replicate');

is(
    Seq::zip(
        Seq->always(1),
        Seq->new(qw/A B C D E F/),
    ),
    seq { [1,'A'],[1,'B'],[1,'C'],[1,'D'],[1,'E'],[1,'F'] },
    'always with zip');

is(
    Seq::zip(
        Seq->new(1,2)->repeat(9),
        Seq->new(qw/A B C D E F/),
    ),
    seq { [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],[2,'F'] },
    'repeat with zip 1');

is(
    Seq::zip(
        Seq->new(1,2)->repeat(2),
        Seq->new(qw/A B C D E F/),
    ),
    seq { [1,'A'],[2,'B'],[1,'C'],[2,'D'] },
    'repeat with zip 2');

is(
    Seq::zip(
        Seq->new(1,2)->infinity,
        Seq->new(qw/A B C D E/)->infinity,
    )->take(12),
    seq {
        [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],
        [2,'A'],[1,'B'],[2,'C'],[1,'D'],[2,'E'],
        [1,'A'],[2,'B'],
    },
    'zip on infinities');

is(
    Seq::zip(
        $range->infinity,
        $range->rev->infinity,
    )->take(15),
    seq {
        [1,10],[2,9],[3,8],[4,7],[5,6],[6,5],[7,4],[8,3],[9,2],[10,1],
        [1,10],[2,9],[3,8],[4,7],[5,6],
    },
    'zip on ifinity with reverse');

is(
    Seq::zip(
        $range->infinity,
        $range->rev->infinity,
    )->take(15)->map(call 'sum'),

    Seq->always(11)->take(15),
    'zip,infinity,rev,take,map,always');

is(
    Seq
    ->new(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->take_while(sub($x) { $x < 100 })
    ->to_array,
    [1,3,20,-40,20,12],
    'take_while 1'
);

is(
    Seq
    ->new(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->take_while(sub($x) { $x > 100 })
    ->to_array,
    [],
    'take_while 2'
);

is(
    Seq
    ->new(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x < 100 })
    ->to_array,
    [100, 5, 20],
    'skip_while 1'
);

is(
    Seq
    ->new(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x > 100 })
    ->to_array,
    [1,3,20,-40,20,12,100,5,20],
    'skip_while 2'
);

# iter
{
    my @iter;    $range->iter(   sub($x) { push @iter,    $x });
    is(\@iter, [1..10],   'iter');
}

# iteri
{
    my @iteri;    $range->iteri(   sub($x,$i) { push @iteri,    [$i,$x] });
    is(\@iteri, [[0,1], [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]], 'iteri');
}

{
    my $range2 = $range->copy;
    is($range, $range2,   'Seq has ->copy');
    ok($range eq $range2, 'same reference because sequence creates iterators');
}

# as_hash
{
    my $h = Seq->new(qw/Hello World One Two/)->bind(sub($str) {
        seq { $str, length $str }
    })->as_hash;

    is(
        $h,
        {"Hello" => 5, "World" => 5, "One" => 3, "Two" => 3},
        'map with multiple return values and as_hash');

    check_isa($h, 'Hash', 'Is a Hash');

    my $h2 = Seq->new(qw/Hello World One Two/)->to_hash(sub($key) {
        $key => length $key
    });
    is($h, $h2, 'bind->as_hash vs to_hash');
}

# test order of doi
{
    my $sum = 0;
    my $seq = Seq->range(1,10)->doi(sub($x,$idx) {
        $sum += $x;
    });

    is($sum,                          0, '$sum 0 as no data was queried');
    is($seq->take(5), seq { 1,2,3,4,5 }, 'first 5 of $seq');
    is($sum,                         15, '$sum is now 15');
    is($seq->take(5), seq { 1,2,3,4,5 }, 'first 5 of $seq');
    is($sum,                         30, '$sum is now 30');
}

# split and join
{
    my $words =
        seq { "Foo+Bar+Baz", "maz+faz" }
        ->split(qr/\+/);

    is(
        $words->to_array,
        [[qw/Foo Bar Baz/], [qw/maz faz/]],
        'strings splitted into arrays');

    is(
        $words->map(sub($inner) { $inner->join('+') })->to_array,
        ["Foo+Bar+Baz", "maz+faz"],
        'joining inner arrays');
}

# map2
{
    my $words = seq { qw(foo bar baz) };
    my $one   = Seq->always(1);

    # method
    is(
        $words->map2($one, sub($word,$one) { [$word, $one] }),
        seq { ["foo",1], ["bar",1], ["baz",1] },
        'map2 - method');

    # functional
    is(
        Seq::map2($words, $one, sub($word,$one) { [$word, $one] }),
        seq { ["foo",1], ["bar",1], ["baz",1] },
        'map2 - functional');
}

# range
# {
    # TODO: floating-point
    # my $seq = Seq->range_step(1, 0.3, 2);
    # is(
    #     $seq->to_array,
    #     [1,1.3, 1.6, 1.9],
    #     'does not overshoot');
# }

# to_seq
{
    my $seq1 = Seq->range(1,3);
    my $seq2 = $seq1->to_seq;
    is(refaddr($seq1), refaddr($seq2), 'to_seq returns same $seq');
}

is(
    seq { qw/foo1bar maz2bar/ }
    ->rxs(qr/([a-z]+) \d+ ([a-z]+)/xi, sub { "$1$2" }),

    seq { qw/foobar mazbar/ },
    'rxs');

# chunked
{
    is(
        Seq->range(1,10)->chunked(1),
        seq { [1], [2], [3], [4], [5], [6], [7], [8], [9], [10] },
        'chunked 1');

    is(
        Seq->range(1,10)->chunked(2),
        seq { [1,2], [3,4], [5,6], [7,8], [9,10] },
        'chunked 2');

    is(
        Seq->range(1,10)->chunked(3),
        seq { [1,2,3], [4,5,6], [7,8,9], [10] },
        'chunked 3');

    is(
        Seq->range(1,10)->chunked(4),
        seq { [1,2,3,4], [5,6,7,8], [9,10] },
        'chunked 4');

    is(
        Seq->range(1,1_000_000_000)->chunked(10)->take(3),
        seq { [1..10], [11..20], [21..30] },
        'chunked on large Seq');

    is(
        Seq->range(1,1_000_000_000)->chunked(10)->map(sub($a) { $a->sum })->take(3),
        seq { 55, 155, 255 },
        'chunked check if array is blessed');
}

is(
    Seq->range(1,1_000_000_000)->windowed(10)->take(3),
    seq { [1 .. 10], [2 .. 11], [3 .. 12] },
    'windowed on large Seq');
is(
    Seq->range(1,1_000_000_000)->windowed(10)->map(sub($a) { $a->sum })->take(3),
    seq { 55, 65, 75 },
    'windowed - check if array is blessed');
is(
    Seq->empty->windowed(3),
    Seq->empty,
    'windowed on empty');
is(
    Seq->range(1,100)->skip(1_000_000_000),
    seq {},
    'skip with large number');
{
    my $a = seq { 1,2,3 };
    my $b = seq { 4,5,6 };
    my $c = seq { 7,8,9 };

    is(
        Seq::append($a, Seq::append($b,$c)),
        Seq::append(Seq::append($a,$b), $c),
        'Seq::append in different order');
}

is(
    Seq
    ->range(1,10)
    ->remove(sub($x) { $x % 2 == 0 }), # remove even numbers
    seq { 1,3,5,7,9 },
    'remove');

is(Seq->up(10)  ->take(100),   seq { 10 .. 109 }, 'up');
is(Seq->down(10)->take(100), Seq->range(10, -89), 'down');

# trim
{
    my $data = seq {
        "   foo",
        "bar   ",
        "   f  ",
        "\nfoo\n",
        " foo  bar ",
    };

    is($data->trim, seq {
        "foo",
        "bar",
        "f",
        "foo",
        "foo  bar",
    }, 'trim 1');

    is($data, seq {
        "   foo",
        "bar   ",
        "   f  ",
        "\nfoo\n",
        " foo  bar ",
    }, '$data did not change');
}

# intersect
{
    my $data1 = seq { [qw/foo .mp4/], [qw/bar .mp4/], [qw/baz .mp4/] };
    my $data2 = seq { [qw/foo .m4v/],                 [qw/baz .m4v/] };

    is(
        Seq::intersect($data1, $data2, \&fst),
        [[qw/foo .mp4/], [qw/baz .mp4/]],
        'intersect 1');

    is(
        Seq::intersect($data2, $data1, \&fst),
        [[qw/foo .m4v/], [qw/baz .m4v/]],
        'intersect 2');
}

is(Seq->empty->permute,  seq {},        'permute 0');
is(seq { 'A' }->permute, seq { ['A'] }, 'permute 1');
is(
    seq { qw/A B/ }->permute,
    seq {
        [qw/A B/],
        [qw/B A/],
    },
    'permute 2');
is(
    seq { qw/A B C/ }->permute,
    seq {
        [qw/A B C/],
        [qw/A C B/],
        [qw/B A C/],
        [qw/B C A/],
        [qw/C A B/],
        [qw/C B A/],
    },
    'permute 3');
is(
    seq { qw/A B C D/ }->permute,
    seq {
        [ "A", "B", "C", "D" ],
        [ "A", "B", "D", "C" ],
        [ "A", "C", "B", "D" ],
        [ "A", "C", "D", "B" ],
        [ "A", "D", "B", "C" ],
        [ "A", "D", "C", "B" ],
        [ "B", "A", "C", "D" ],
        [ "B", "A", "D", "C" ],
        [ "B", "C", "A", "D" ],
        [ "B", "C", "D", "A" ],
        [ "B", "D", "A", "C" ],
        [ "B", "D", "C", "A" ],
        [ "C", "A", "B", "D" ],
        [ "C", "A", "D", "B" ],
        [ "C", "B", "A", "D" ],
        [ "C", "B", "D", "A" ],
        [ "C", "D", "A", "B" ],
        [ "C", "D", "B", "A" ],
        [ "D", "A", "B", "C" ],
        [ "D", "A", "C", "B" ],
        [ "D", "B", "A", "C" ],
        [ "D", "B", "C", "A" ],
        [ "D", "C", "A", "B" ],
        [ "D", "C", "B", "A" ],
    },
    'permute 4');
is(
    seq { qw/Foo Bar Baz/ }->permute,
    seq {
        [ "Foo", "Bar", "Baz" ],
        [ "Foo", "Baz", "Bar" ],
        [ "Bar", "Foo", "Baz" ],
        [ "Bar", "Baz", "Foo" ],
        [ "Baz", "Foo", "Bar" ],
        [ "Baz", "Bar", "Foo" ],
    },
    'permute 5');
is(
    seq { qw/Foo Bar Baz/ }->permute->map(call 'join', ""),
    seq {
        "FooBarBaz",
        "FooBazBar",
        "BarFooBaz",
        "BarBazFoo",
        "BazFooBar",
        "BazBarFoo",
    },
    'permute 6');

is(
    Seq::cartesian(
        seq { qw/A B/   }->permute,
        seq { qw/C G A/ }->permute,
    ),
    seq {
        [ ["A","B"], ["C","G","A"] ],
        [ ["A","B"], ["C","A","G"] ],
        [ ["A","B"], ["G","C","A"] ],
        [ ["A","B"], ["G","A","C"] ],
        [ ["A","B"], ["A","C","G"] ],
        [ ["A","B"], ["A","G","C"] ],
        [ ["B","A"], ["C","G","A"] ],
        [ ["B","A"], ["C","A","G"] ],
        [ ["B","A"], ["G","C","A"] ],
        [ ["B","A"], ["G","A","C"] ],
        [ ["B","A"], ["A","C","G"] ],
        [ ["B","A"], ["A","G","C"] ],
    },
    'permute 7');

is(
    Seq::cartesian(
        seq { qw/A B/   }->permute,
        seq { qw/C G A/ }->permute,
    )->map(call 'flatten'),
    seq {
        ["A","B", "C","G","A"],
        ["A","B", "C","A","G"],
        ["A","B", "G","C","A"],
        ["A","B", "G","A","C"],
        ["A","B", "A","C","G"],
        ["A","B", "A","G","C"],
        ["B","A", "C","G","A"],
        ["B","A", "C","A","G"],
        ["B","A", "G","C","A"],
        ["B","A", "G","A","C"],
        ["B","A", "A","C","G"],
        ["B","A", "A","G","C"],
    },
    'permute 8');

# bind() is like binding the inner value of a sequence to a variable
# so somehow similar like just iterating through a sequence. or like map().
# but we return another sequence that then is flattened. bind() is like just
# reversing typical code with assignment from right-to-left to a left-to-right.
#
# my $fst   = $seqA->permute;
# my $snd   = $seqB->permute;
# my $third = $seqC->permute;
# return Array->concat($fst,$snd,$third)
#
# or when those would be arrays.
#
# my @results;
# for my $fst ( @{ $seqA->permute } ) {
#     for my $snd ( @{ $seqB->permute } ) {
#         for my my $third ( @{ $seqC->permute } ) {
#             push @results, Array->concat($fst,$snd,$third);
#         }
#      }
# }
#
# But the sequence does it lazy
is(
    seq {qw/A B/  }->permute->bind(sub($fst) {
    seq {qw/C G A/}->permute->bind(sub($snd) {
    seq {qw/T K/  }->permute->bind(sub($third) {
        seq { Array->concat($fst, $snd, $third) }
    })})}),
    seq {
        ["A","B", "C","G","A", "T","K"],
        ["A","B", "C","G","A", "K","T"],
        ["A","B", "C","A","G", "T","K"],
        ["A","B", "C","A","G", "K","T"],
        ["A","B", "G","C","A", "T","K"],
        ["A","B", "G","C","A", "K","T"],
        ["A","B", "G","A","C", "T","K"],
        ["A","B", "G","A","C", "K","T"],
        ["A","B", "A","C","G", "T","K"],
        ["A","B", "A","C","G", "K","T"],
        ["A","B", "A","G","C", "T","K"],
        ["A","B", "A","G","C", "K","T"],
        ["B","A", "C","G","A", "T","K"],
        ["B","A", "C","G","A", "K","T"],
        ["B","A", "C","A","G", "T","K"],
        ["B","A", "C","A","G", "K","T"],
        ["B","A", "G","C","A", "T","K"],
        ["B","A", "G","C","A", "K","T"],
        ["B","A", "G","A","C", "T","K"],
        ["B","A", "G","A","C", "K","T"],
        ["B","A", "A","C","G", "T","K"],
        ["B","A", "A","C","G", "K","T"],
        ["B","A", "A","G","C", "T","K"],
        ["B","A", "A","G","C", "K","T"]
    },
    'permute 9');

is(
    seq { split //, "AAACGTT" }
    ->permute
    ->map(call join => "")
    ->keep(sub($str) { $str eq 'GATTACA' })
    ->distinct,
    seq { 'GATTACA' },
    'GATTACA');

is(
    seq { split //, "AACGTT" }
    ->permute
    ->map(call 'join')
    ->rx(qr/GATC/),
    seq {
        "AGATCT", "AGATCT", "ATGATC", "ATGATC", "AGATCT", "AGATCT", "ATGATC",
        "ATGATC", "GATCAT", "GATCTA", "GATCAT", "GATCTA", "GATCAT", "GATCTA",
        "GATCAT", "GATCTA", "TAGATC", "TAGATC", "TGATCA", "TGATCA", "TAGATC",
        "TAGATC", "TGATCA", "TGATCA"
    },
    'DNA');

done_testing;
