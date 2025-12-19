#!perl
use 5.036;
use Scalar::Util qw(refaddr);
use List::Util qw(reduce);
use Sq -sig => 1;
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

is($range->map($double),   seq(2,4,6,8,10,12,14,16,18,20), 'map');
is($range->keep($is_even), seq(2,4,6,8,10),               'keep');

is($range->take(5),  seq(1..5), 'take 1');
is($range->take(0),  seq(),    'take 2');
is($range->take(-1), seq(),    'take 3');
is($range->take(5) ->to_array, $range->to_array(5),  'take(x) same as to_array(x) 1');
is($range->take(0) ->to_array, $range->to_array(0),  'take(x) same as to_array(x) 2');
is($range->take(-1)->to_array, $range->to_array(-1), 'take(x) same as to_array(x) 3');


is($range->length, 10, 'length');
is($range->take(5)->length, 5, 'take & length');
is($range->map(sub($x) { undef }), Seq->empty, 'map function returns undef');
is(
    $range->map($square)->keep($is_even),
    seq(4,16,36,64,100),
    'map keep');
is(
    $range->map($square)->keep($is_even)->take(3),
    seq(4,16,36),
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

# fold tests that check behaviour that it uses Sq::init()
{
    my $empty = [];
    is(
        Seq::fold(Seq->range(1,3), $empty, sub($x,$state) {
            $state->push($x);
            $state;
        }),
        [1,2,3],
        'fold - $empty is blessed');
    is($empty, [], 'previous fold call did not change $empty');

    is(
        Seq::fold(Seq->range(1,3), sub { array }, sub($x,$state) {
            $state->push($x);
            $state;
        }),
        [1,2,3],
        'fold also accepts sub-ref for initilization');
}

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
    is(Seq->new(1,2,3,undef,4,5,6), seq(1..3), 'new containing an undef');
    is(Seq->new(5), seq(5), 'new');
    is(
        seq(5)->append(seq(10)),
        seq(5, 10),
        'new and append');
    is(
        Seq->range(1,5)->append(Seq->range(6,10)),
        Seq->range(1,10),
        'append two ranges');
    is(Seq->range_step(1, 2, 10), seq(1,3,5,7,9 ), '1 .. 10 step 2');
    is(Seq->range_step(10, 2, 1), seq(10,8,6,4,2), '10 .. 1 step 2');
}

is(
    Seq::zip(
        seq(qw/A B C D E F/),
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
    Seq->init(10,0),
    seq(0,0,0,0,0,0,0,0,0,0),
    'Seq->init with value');
{
    my $result = Seq->init(3, [])->to_array;

    is($result, [[],[],[]], 'Seq->init with ref');
    push $result->[0]->@*, 1;
    is($result, [[1],[],[]], 'Seq->init does not share data');
}

is(
    (reduce { $a->append($b) } map { seq($_) } 1 .. 10),
    $range,
    'append a list of wrapped values');
is(
    Seq->concat(map { seq($_) } 1 .. 10),
    $range,
    'concat');
is(
    Seq->concat,
    Seq->empty,
    'concat on zero is empty');
is(
    seq (Seq->range(1,10)->expand),
    seq (1 .. 10),
    'expand and wrap is isomorph');
is(
    Seq->new(1..5)->append(
        Seq->new(6..10)
    ),
    Seq->concat(
        seq(1..3),
        seq(4..6),
        seq(7..10),
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
is(Seq->concat(seq(1,2,3)), seq(1,2,3), 'concat 1');
is(
    Seq->concat(seq(1,2,3), seq(4,5,6)),
    seq(1 .. 6),
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
    seq(
        [map { [$_,$_] }  1..10],
        [map { [$_,$_] } 11..20],
        [map { [$_,$_] } 21..30],
    ),
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

is($range->skip(0),   seq(1..10), 'skip(0)');
is($range->skip(-1),  seq(1..10), 'skip(-1)');
is($range->skip(-10), seq(1..10), 'skip(-10)');
is($range->skip(100), seq(     ), 'skip(100)');

is($range->skip(3)->take(3),  seq(4,5,6), 'skip->take 1');
is($range->skip(3)->take(10), seq(4..10), 'skip->take 2');
is($range->skip(10)->take(1), seq(     ),  'skip->take 3');

is($range->take(0),   Seq->empty, 'take(0)');
is($range->take(-1),  Seq->empty, 'take(-1)');
is($range->take(-10), Seq->empty, 'take(-10)');
is($range->take(100), $range,     'take(100)');

is($range->take(5)->skip(2), seq(3,4,5), 'take->skip 1');
is($range->take(5)->skip(4), seq(5    ),  'take->skip 2');
is($range->take(5)->skip(6), seq(     ),  'take->skip 2');

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
    seq(qw/H e l l o W o r l d !/)->join('-'),
    "H-e-l-l-o-W-o-r-l-d-!",
    'join 1');
is(
    seq(qw/H e l l o W o r l d !/)->join,
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

is(Seq->new(1,1,2,3,1,4,5,4,3,2,6)       ->distinct, seq(1..6),               'distinct 1');
is(Seq->new(1,2,3,2,23,123,4,12,2)       ->distinct, seq(1,2,3,23,123,4,12),  'distinct 2');
is(Seq->new(1,2,3,3,4,2,1,5,6,5,4,7,10,8)->distinct, seq(1,2,3,4,5,6,7,10,8), 'distinct 3');

# distinct_by tests
{
    my $data = seq(
        {id => 1, name => "Foo"},
        {id => 2, name => "Bar"},
        {id => 3, name => "Baz"},
        {id => 1, name => "Foo"},
    );

    is($data->length, 4, 'distinct_by starts with 4');
    is($data->distinct->length, 4, 'still 4 as HashRefs are always unequal');
    is($data->distinct_by(key 'id')->length, 3, 'one element less');
    is(
        $data->distinct_by(key 'id'),
        seq(
            {id => 1, name => "Foo"},
            {id => 2, name => "Bar"},
            {id => 3, name => "Baz"},
        ),
        'check elements and order');
}

is(
    Seq->new(qw/A B C D E F/)->mapi(\&array),
    seq([A => 0], [B => 1], [C => 2], [D => 3], [E => 4], [F => 5]),
    'mapi');

is(Seq->init( 0,  sub($idx) { $idx }), Seq->empty, 'init with length 0');
is(Seq->init(-1,  sub($idx) { $idx }), Seq->empty, 'init with length -1');
is(Seq->init(-10, sub($idx) { $idx }), Seq->empty, 'init with length -10');
is(Seq->range_step(1,1,1), seq(1),                 'range_step with 1,1,1');

is(
    Seq->range_step(0,0.1,1)->to_array,
    [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1],
    'range_step with 0,0.1,1');

dies { Seq->range_step(0,0,1)->to_array }
qr/^\$step is 0/,
'range_step dies with step size of zero';

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
    seq(grep { $_ % 2 == 0 } map { $_ * $_ } 1 .. 10),
    'Non Lazy Perl implementation of choose');


is($range->find(sub($x) { $x > 5  }),   Some(6), 'find 1');
is($range->find(sub($x) { $x > 10 }),      None, 'find 2');
is($range->find(sub($x) { $x > 10 })->or(0),  0, 'find 3');

is(
    $range->bind(sub($x) { seq($x) }),
    Seq->range(1,10),
    'bind - somehow like id');

is(
    Seq->new(
        seq(1,1),
        seq(2,3,5,8,13),
    )->flatten,
    seq(1,1,2,3,5,8,13),
    'flatten - flattens a seq of seq');

is(Seq->new([1,1], [1,2]), seq([1,1],[1,2]), 'wrap with arrays');
is(Seq->new([1,1])       , seq([1,1]),       'wrap with array');
is(Seq->from_array([1,1]), seq(1,1),         'from_array vs. wrap');

is($range->reduce($add),           Some(55), 'reduce');
is(Seq->empty->reduce($add),           None, 'reduce on empty 1');
is(Seq->empty->reduce($add)->or(0),       0, 'reduce on empty 2');
is(Seq->new(1)->reduce($add)->or(0),     1, 'reduce on single element');

is(Seq->empty->first,       None, 'first on empty');
is(Seq->empty->first->or(0),   0, 'first on empty with option::or');
is(Seq->empty->first(0),       0, 'first on empty with default value');
is($range->first,        Some(1), 'first on non empty');
is($range->first->or(0),       1, 'first on non empty with option::or');

is(Seq->empty->last,         None, 'last on empty');
is(Seq->empty->last->or(0),     0, 'last on empty with option:or');
is(Seq->empty->last(0),         0, 'last on empty with default value');
is($range->last ,        Some(10), 'last on non empty');
is($range->last->or(0),        10, 'last on non empty with option::or');

is(Seq->new(1,5,-3,10,9,-2) ->sort(by_num), [ -3,-2,1,5,9,10 ],  'sort 1');
is(Seq->new(qw/B b c A a C/)->sort(by_str), [ qw/A B C a b c/ ], 'sort 2');
check_isa(seq(3,2,1)->sort(by_num), 'Array', 'sort returns Array');

# Schwartzian Transformation
{
    my $data = seq(
        { id => 1, char => 'W' },
        { id => 4, char => 'L' },
        { id => 5, char => 'D' },
        { id => 2, char => 'O' },
        { id => 3, char => 'R' },
    );

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
    Seq->new([1,2,3], [4,5,6], [7,8,9])->merge,
    seq(1..9),
    'flatten_array');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->new(qw(A B C D E F))
    ),
    seq([qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/],[qw/5 E/],[qw/6 F/]),
    'zip 1');

is(
    Seq::zip(
        Seq->range(1,3),
        Seq->new(qw(A B C D E F))
    ),
    seq([qw/1 A/],[qw/2 B/],[qw/3 C/]),
    'zip 2');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->new(qw(A B C D))
    ),
    seq([qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/]),
    'zip 3');

is(
    Seq::zip(
        Seq->empty,
        Seq->new(qw(A B C D E F))
    ),
    Seq->empty,
    'zip 4');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->empty,
    ),
    Seq->empty,
    'zip 5');

is(
    Seq::zip(
        seq(1,2,3   ),
        seq(4,5,6   ),
        seq(7,8,9   ),
        seq(10,11,12),
    ),
    seq([1,4,7,10], [2,5,8,11], [3,6,9,12]),
    'zip 6');

is(
    Seq::zip(
        seq(1,2,3   ),
        seq(4,5,6,7 ),
        seq(7,8,9   ),
        seq(10,11,12),
    ),
    seq([1,4,7,10], [2,5,8,11], [3,6,9,12]),
    'zip 7');

is(
    Seq::zip(
        seq(1,  2, 3      ),
        seq(4,  5, 6, 7   ),
        seq(7,  8, 9      ),
        seq(10,11,12,13,14),
    ),
    seq([1,4,7,10], [2,5,8,11], [3,6,9,12]),
    'zip 8');

is(
    seq(
        seq(1,2,3),
        seq(4,5,6),
        seq(7,8,9),
    )->to_array_of_array,
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
    my $lines = seq(
        '2023-11-25T15:10:00',
        '2023-11-20T10:05:29',
        'xxxx-xx-xxT00:00:00',
        '1900-01-01T00:00:01',
        '12345678901234567890',
    );

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
        seq(
            ["25.11.2023", "15:10:00"],
            ["20.11.2023", "10:05:29"],
            ["01.01.1900", "00:00:01"],
        ),
        'rxm');

    is(
        $lines->rxm(qr/\A
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
        \z/xms),
        seq([1 .. 9, 0, 1 .. 9, 0]),
        'check 20 matches');
}

is($range->windowed(-1), Seq->empty,                'windowed -1');
is($range->windowed(0) , Seq->empty,                'windowed 0');
is($range->windowed(1) , seq(map { [$_] } 1 .. 10), 'windowed 1');
is(
    $range->windowed(2),
    seq([1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]),
    'windowed 2');
is(
    $range->windowed(5),
    seq(
        [1,2,3,4,5], [2,3,4,5,6], [3,4,5,6,7], [4,5,6,7,8], [5,6,7,8,9], [6,7,8,9,10]
    ),
    'windowed 5');

is($range->windowed(10), seq([1 .. 10]), 'windowed 10');
is($range->windowed(11), seq([1 .. 10]), 'windowed 11');

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

is(Seq->replicate(10, 'A'), seq(('A') x 10), 'replicate');

is(
    Seq::zip(
        Seq->always(1),
        Seq->new(qw/A B C D E F/),
    ),
    seq([1,'A'],[1,'B'],[1,'C'],[1,'D'],[1,'E'],[1,'F']),
    'always with zip');

is(
    Seq::zip(
        Seq->new(1,2)->repeat(9),
        Seq->new(qw/A B C D E F/),
    ),
    seq([1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],[2,'F']),
    'repeat with zip 1');

is(
    Seq::zip(
        Seq->new(1,2)->repeat(2),
        Seq->new(qw/A B C D E F/),
    ),
    seq([1,'A'],[2,'B'],[1,'C'],[2,'D']),
    'repeat with zip 2');

is(
    Seq::zip(
        Seq->new(1,2)->infinity,
        Seq->new(qw/A B C D E/)->infinity,
    )->take(12),
    seq(
        [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],
        [2,'A'],[1,'B'],[2,'C'],[1,'D'],[2,'E'],
        [1,'A'],[2,'B'],
    ),
    'zip on infinities');

is(
    Seq::zip(
        $range->infinity,
        $range->rev->infinity,
    )->take(15),
    seq(
        [1,10],[2,9],[3,8],[4,7],[5,6],[6,5],[7,4],[8,3],[9,2],[10,1],
        [1,10],[2,9],[3,8],[4,7],[5,6],
    ),
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
    ->take_while(sub($x) { $x < 100 }),
    seq(1,3,20,-40,20,12),
    'take_while 1'
);

is(
    Seq
    ->new(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->take_while(sub($x) { $x > 100 }),
    Seq->empty,
    'take_while 2'
);

is(
    Seq
    ->new(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x < 100 }),
    seq(100, 5, 20),
    'skip_while 1'
);

is(
    Seq
    ->new(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x > 100 }),
    seq(1,3,20,-40,20,12,100,5,20),
    'skip_while 2'
);

# iter
{
    my @iter; $range->iter(sub($x) { push @iter, $x });
    is(\@iter, [1..10],   'iter');
}

# iteri
{
    my @iteri; $range->iteri(sub($x,$i) { push @iteri, [$i,$x] });
    is(\@iteri, [[0,1], [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]], 'iteri');
}

{
    my $range2 = copy($range);
    is($range, $range2,   'copy on Seq');
    ok($range eq $range2, 'same reference because sequence creates iterators');
}

# as_hash
{
    my $h = Seq->new(qw/Hello World One Two/)->bind(sub($str) {
        seq($str, length $str)
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

    is($sum,                       0, '$sum 0 as no data was queried');
    is($seq->take(5), seq(1,2,3,4,5), 'first 5 of $seq');
    is($sum,                      15, '$sum is now 15');
    is($seq->take(5), seq(1,2,3,4,5), 'first 5 of $seq');
    is($sum,                      30, '$sum is now 30');
}

# split and join
{
    my $words = seq("Foo+Bar+Baz", "maz+faz")->split(qr/\+/);

    is(
        $words,
        seq([qw/Foo Bar Baz/], [qw/maz faz/]),
        'strings splitted into arrays');

    is(
        $words->map(sub($inner) { $inner->join('+') }),
        seq("Foo+Bar+Baz", "maz+faz"),
        'joining inner arrays');
}

# map2
{
    my $words = seq(qw(foo bar baz));
    my $one   = Seq->always(1);

    # method
    is(
        $words->map2($one, sub($word,$one) { [$word, $one] }),
        seq(["foo",1], ["bar",1], ["baz",1]),
        'map2 - method');

    # functional
    is(
        Seq::map2($words, $one, sub($word,$one) { [$word, $one] }),
        seq(["foo",1], ["bar",1], ["baz",1]),
        'map2 - functional');
}

is(
    Seq->range_step(1, 0.3, 2),
    seq(1, 1.3, 1.6, 1.9),
    'does not overshoot');

# to_seq
{
    my $seq1 = Seq->range(1,3);
    my $seq2 = $seq1->to_seq;
    is(refaddr($seq1), refaddr($seq2), 'to_seq returns same $seq');
}

is(
    seq(qw/foo1bar maz2bar/)
    ->rxs(qr/([a-z]+) \d+ ([a-z]+)/xi, sub { "$1$2" }),

    seq(qw/foobar mazbar/),
    'rxs');

# chunked
{
    is(
        Seq->range(1,10)->chunked(1),
        seq([1], [2], [3], [4], [5], [6], [7], [8], [9], [10]),
        'chunked 1');

    is(
        Seq->range(1,10)->chunked(2),
        seq([1,2], [3,4], [5,6], [7,8], [9,10]),
        'chunked 2');

    is(
        Seq->range(1,10)->chunked(3),
        seq([1,2,3], [4,5,6], [7,8,9], [10]),
        'chunked 3');

    is(
        Seq->range(1,10)->chunked(4),
        seq([1,2,3,4], [5,6,7,8], [9,10]),
        'chunked 4');

    is(
        Seq->range(1,1_000_000_000)->chunked(10)->take(3),
        seq([1..10], [11..20], [21..30]),
        'chunked on large Seq');

    is(
        Seq->range(1,1_000_000_000)->chunked(10)->map(call 'sum')->take(3),
        seq(55, 155, 255),
        'chunked check if array is blessed');
}

is(
    Seq->range(1,1_000_000_000)->windowed(10)->take(3),
    seq([1 .. 10], [2 .. 11], [3 .. 12]),
    'windowed on large Seq');
is(
    Seq->range(1,1_000_000_000)->windowed(10)->map(call 'sum')->take(3),
    seq(55, 65, 75),
    'windowed - check if array is blessed');
is(
    Seq->empty->windowed(3),
    Seq->empty,
    'windowed on empty');
is(
    Seq->range(1,100)->skip(1_000_000_000),
    seq(),
    'skip with large number');
{
    my $a = seq(1,2,3);
    my $b = seq(4,5,6);
    my $c = seq(7,8,9);

    is(
        Seq::append($a, Seq::append($b,$c)),
        Seq::append(Seq::append($a,$b), $c),
        'Seq::append in different order');
}

is(
    Seq
    ->range(1,10)
    ->remove(sub($x) { $x % 2 == 0 }), # remove even numbers
    seq(1,3,5,7,9),
    'remove');

is(Seq->up(10)  ->take(100),      seq(10 .. 109), 'up');
is(Seq->down(10)->take(100), Seq->range(10, -89), 'down');

# trim
{
    my $data = seq(
        "   foo",
        "bar   ",
        "   f  ",
        "\nfoo\n",
        " foo  bar ",
    );

    is($data->trim, seq(
        "foo",
        "bar",
        "f",
        "foo",
        "foo  bar",
    ), 'trim 1');

    is($data, seq(
        "   foo",
        "bar   ",
        "   f  ",
        "\nfoo\n",
        " foo  bar ",
    ), '$data did not change');
}

# intersect
{
    my $data1 = seq([qw/foo .mp4/], [qw/bar .mp4/], [qw/baz .mp4/]);
    my $data2 = seq([qw/foo .m4v/],                 [qw/baz .m4v/]);

    is(
        Seq::intersect($data1, $data2, \&fst),
        [[qw/foo .mp4/], [qw/baz .mp4/]],
        'intersect 1');

    is(
        Seq::intersect($data2, $data1, \&fst),
        [[qw/foo .m4v/], [qw/baz .m4v/]],
        'intersect 2');
}

is(Seq->empty->permute,  seq(),   'permute 0');
is(seq('A')->permute, seq(['A']), 'permute 1');
is(
    seq(qw/A B/)->permute,
    seq(
        [qw/A B/],
        [qw/B A/],
    ),
    'permute 2');
is(
    seq(qw/A B C/)->permute,
    seq(
        [qw/A B C/],
        [qw/A C B/],
        [qw/B A C/],
        [qw/B C A/],
        [qw/C A B/],
        [qw/C B A/],
    ),
    'permute 3');
is(
    seq(qw/A B C D/)->permute,
    seq(
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
    ),
    'permute 4');
is(
    seq(qw/Foo Bar Baz/)->permute,
    seq(
        [ "Foo", "Bar", "Baz" ],
        [ "Foo", "Baz", "Bar" ],
        [ "Bar", "Foo", "Baz" ],
        [ "Bar", "Baz", "Foo" ],
        [ "Baz", "Foo", "Bar" ],
        [ "Baz", "Bar", "Foo" ],
    ),
    'permute 5');
is(
    seq(qw/Foo Bar Baz/)->permute->map(call 'join', ""),
    seq(
        "FooBarBaz",
        "FooBazBar",
        "BarFooBaz",
        "BarBazFoo",
        "BazFooBar",
        "BazBarFoo",
    ),
    'permute 6');

is(Seq->empty->cartesian(seq(1,2,3)),      Seq->empty, 'cartesian with empty 1');
is(Seq::cartesian(Seq->empty, seq(1,2,3)), Seq->empty, 'cartesian with empty 2');
is(
    seq(7,8,9,10)->cartesian(seq("Hearth", "Spades")),
    seq(
        [7,"Hearth"], [7,"Spades"],  [8,"Hearth"],  [8,"Spades"],
        [9,"Hearth"], [9,"Spades"], [10,"Hearth"], [10,"Spades"],
    ),
    'cartesian');

is(
    Seq::cartesian(
        seq(qw/A B/  )->permute,
        seq(qw/C G A/)->permute,
    ),
    seq(
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
    ),
    'permute 7');

is(
    Seq::cartesian(
        seq(qw/A B/  )->permute,
        seq(qw/C G A/)->permute,
    )->map(call 'flatten'),
    seq(
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
    ),
    'permute 8');

is(
    Seq::cartesian(seq(1,2,3), seq(qw/A B C/), seq(qw/foo bar/), seq(0,1)),
    seq(
        [1,"A","foo",0],
        [1,"A","foo",1],
        [1,"A","bar",0],
        [1,"A","bar",1],
        [1,"B","foo",0],
        [1,"B","foo",1],
        [1,"B","bar",0],
        [1,"B","bar",1],
        [1,"C","foo",0],
        [1,"C","foo",1],
        [1,"C","bar",0],
        [1,"C","bar",1],
        [2,"A","foo",0],
        [2,"A","foo",1],
        [2,"A","bar",0],
        [2,"A","bar",1],
        [2,"B","foo",0],
        [2,"B","foo",1],
        [2,"B","bar",0],
        [2,"B","bar",1],
        [2,"C","foo",0],
        [2,"C","foo",1],
        [2,"C","bar",0],
        [2,"C","bar",1],
        [3,"A","foo",0],
        [3,"A","foo",1],
        [3,"A","bar",0],
        [3,"A","bar",1],
        [3,"B","foo",0],
        [3,"B","foo",1],
        [3,"B","bar",0],
        [3,"B","bar",1],
        [3,"C","foo",0],
        [3,"C","foo",1],
        [3,"C","bar",0],
        [3,"C","bar",1]
    ),
    'cartesian on many sequences');

# bind() is like binding the inner value of a sequence to a variable
# so somehow similar like just iterating through a sequence or like map().
# But we return another sequence that then is flattened. bind() is like just
# reversing typical code with assignment from right-to-left to a left-to-right.
#
# my $fst   = $seqA->permute;
# my $snd   = $seqB->permute;
# my $third = $seqC->permute;
# return Array::concat($fst,$snd,$third)
#
# or when those would be arrays.
#
# my @results;
# for my $fst ( @{ $seqA->permute } ) {
#     for my $snd ( @{ $seqB->permute } ) {
#         for my my $third ( @{ $seqC->permute } ) {
#             push @results, Array::concat($fst,$snd,$third);
#         }
#      }
# }
#
# But the sequence does it lazy
is(
    # here calling ->bind() is like the above three inner for-loops on array
    # they are just written flat instead that every level is indented.
    # $fst is one of AB, $snd is one of CGA and so on.
    # The $f function in bind($type, $f) always must return the same $type.
    # So in Array::bind you must return an Array. In Seq::bind you must return
    # a sequence and so on.
    seq(qw/A B/  )->permute->bind(sub($fst) {
    seq(qw/C G A/)->permute->bind(sub($snd) {
    seq(qw/T K/  )->permute->bind(sub($third) {
        seq(Array::concat($fst, $snd, $third))
    })})}),
    seq(
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
    ),
    'permute 9');

# same as permute 9 but with cartesian
is(
    Seq::cartesian(
        seq(qw/A B/  )->permute,
        seq(qw/C G A/)->permute,
        seq(qw/T K/  )->permute,
    )->map(call 'flatten'),
    seq(
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
    ),
    'permute 10');

# when cartesian contains an empty we cannot compute a cartesian
is(
    Seq::cartesian(seq(1,2,3), Seq->empty, seq(qw/A B/)),
    seq(),
    'cartesian with empty seq');

{
    my $az   = seq('a' .. 'z');
    # this would generate 11_881_376 items when fully runned
    my $cart = Seq::cartesian($az, $az, $az, $az, $az)->take(10);
    is(
        $cart,
        seq(
            [ "a", "a", "a", "a", "a" ],
            [ "a", "a", "a", "a", "b" ],
            [ "a", "a", "a", "a", "c" ],
            [ "a", "a", "a", "a", "d" ],
            [ "a", "a", "a", "a", "e" ],
            [ "a", "a", "a", "a", "f" ],
            [ "a", "a", "a", "a", "g" ],
            [ "a", "a", "a", "a", "h" ],
            [ "a", "a", "a", "a", "i" ],
            [ "a", "a", "a", "a", "j" ],
        ),
        'cartesian on big sequence');
    is($cart->length, 10, '$cart is 10');
}

# A general count_up (inside Array::cartesian) could be implemented with cartesian
is(
    Seq::cartesian(seq(0..3), seq(0..4), seq(0..2)),
    seq(
        [ 0, 0, 0 ],
        [ 0, 0, 1 ],
        [ 0, 0, 2 ],
        [ 0, 1, 0 ],
        [ 0, 1, 1 ],
        [ 0, 1, 2 ],
        [ 0, 2, 0 ],
        [ 0, 2, 1 ],
        [ 0, 2, 2 ],
        [ 0, 3, 0 ],
        [ 0, 3, 1 ],
        [ 0, 3, 2 ],
        [ 0, 4, 0 ],
        [ 0, 4, 1 ],
        [ 0, 4, 2 ],
        [ 1, 0, 0 ],
        [ 1, 0, 1 ],
        [ 1, 0, 2 ],
        [ 1, 1, 0 ],
        [ 1, 1, 1 ],
        [ 1, 1, 2 ],
        [ 1, 2, 0 ],
        [ 1, 2, 1 ],
        [ 1, 2, 2 ],
        [ 1, 3, 0 ],
        [ 1, 3, 1 ],
        [ 1, 3, 2 ],
        [ 1, 4, 0 ],
        [ 1, 4, 1 ],
        [ 1, 4, 2 ],
        [ 2, 0, 0 ],
        [ 2, 0, 1 ],
        [ 2, 0, 2 ],
        [ 2, 1, 0 ],
        [ 2, 1, 1 ],
        [ 2, 1, 2 ],
        [ 2, 2, 0 ],
        [ 2, 2, 1 ],
        [ 2, 2, 2 ],
        [ 2, 3, 0 ],
        [ 2, 3, 1 ],
        [ 2, 3, 2 ],
        [ 2, 4, 0 ],
        [ 2, 4, 1 ],
        [ 2, 4, 2 ],
        [ 3, 0, 0 ],
        [ 3, 0, 1 ],
        [ 3, 0, 2 ],
        [ 3, 1, 0 ],
        [ 3, 1, 1 ],
        [ 3, 1, 2 ],
        [ 3, 2, 0 ],
        [ 3, 2, 1 ],
        [ 3, 2, 2 ],
        [ 3, 3, 0 ],
        [ 3, 3, 1 ],
        [ 3, 3, 2 ],
        [ 3, 4, 0 ],
        [ 3, 4, 1 ],
        [ 3, 4, 2 ],
    ),
    'count-up');

{
    my $digit = seq(0 .. 9, 'a' .. 'f');
    my $hex   = Seq::cartesian($digit, $digit)->map(call 'join')->cache;
    is(
        $hex,
        seq(
            "00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "0a", "0b", "0c", "0d", "0e", "0f",
            "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "1a", "1b", "1c", "1d", "1e", "1f",
            "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "2a", "2b", "2c", "2d", "2e", "2f",
            "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "3a", "3b", "3c", "3d", "3e", "3f",
            "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "4a", "4b", "4c", "4d", "4e", "4f",
            "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "5a", "5b", "5c", "5d", "5e", "5f",
            "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "6a", "6b", "6c", "6d", "6e", "6f",
            "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "7a", "7b", "7c", "7d", "7e", "7f",
            "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "8a", "8b", "8c", "8d", "8e", "8f",
            "90", "91", "92", "93", "94", "95", "96", "97", "98", "99", "9a", "9b", "9c", "9d", "9e", "9f",
            "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "aa", "ab", "ac", "ad", "ae", "af",
            "b0", "b1", "b2", "b3", "b4", "b5", "b6", "b7", "b8", "b9", "ba", "bb", "bc", "bd", "be", "bf",
            "c0", "c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "ca", "cb", "cc", "cd", "ce", "cf",
            "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "da", "db", "dc", "dd", "de", "df",
            "e0", "e1", "e2", "e3", "e4", "e5", "e6", "e7", "e8", "e9", "ea", "eb", "ec", "ed", "ee", "ef",
            "f0", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "fa", "fb", "fc", "fd", "fe", "ff"
        ),
        'hex count up');

    is($hex->index(-1),        None, "index 0");
    is($hex->index(0),   Some("00"), "index 1");
    is($hex->index(1),   Some("01"), "index 2");
    is($hex->index(15),  Some("0f"), "index 3");
    is($hex->index(16),  Some("10"), "index 4");
    is($hex->index(255), Some("ff"), "index 5");
    is($hex->index(256),       None, "index 6");

    is($hex->index(-1,  "00"), "00", "index 7");
    is($hex->index(256, "00"), "00", "index 8");
}

is(
    seq(split //, "AAACGTT")
    ->permute
    ->map(call join => "")
    ->keep(sub($str) { $str eq 'GATTACA' })
    ->distinct,
    seq('GATTACA'),
    'GATTACA');

is(
    seq(split //, "AACGTT")
    ->permute
    ->map(call 'join')
    ->rx(qr/GATC/),
    seq(
        "AGATCT", "AGATCT", "ATGATC", "ATGATC", "AGATCT", "AGATCT", "ATGATC",
        "ATGATC", "GATCAT", "GATCTA", "GATCAT", "GATCTA", "GATCAT", "GATCTA",
        "GATCAT", "GATCTA", "TAGATC", "TAGATC", "TGATCA", "TGATCA", "TAGATC",
        "TAGATC", "TGATCA", "TGATCA"
    ),
    'DNA');

is(Seq->one(1),       seq(1), 'one 1');
check_isa(Seq->one(1), 'Seq', 'one 2');

is(seq       ->is_empty, 1,        'is_empty 1');
is(seq(1)    ->is_empty, 0,        'is_empty 2');
is(seq(1,2,3)->tail,     seq(2,3), 'tail 1');

# contains
{
    my $data = seq (
        { name => 'Lilly' },
        { X => 1, Y => 2  },
        'Some Text',
        "Foo: x",
        123,
        [1,2,3],
    );

     ok($data->contains({name => 'Lilly'}),          'contains Lilly');
    nok($data->contains({name => 'Anny' }),          'no Anny');
     ok($data->contains({X => 1, Y => 2 }),          'contains Point');
    nok($data->contains({X => 1, Y => 3 }),          'Y other value');
     ok($data->contains('Some Text'),                'string 1');
    nok($data->contains('Not Found'),                'string 2');
     ok($data->contains(123),                        'num 1');
    nok($data->contains(124),                        'num 2');
     ok($data->contains([1,2,3]),                    'array 1');
    nok($data->contains([1,2,3,4]),                  'array 2');
     ok($data->contains(qr/\A\w+ \s* : \s* \w+\z/x), 'regexp 1');
    nok($data->contains(qr/\A\z/),                   'regexp 2');
}

# keyed_by
{
    my $data = seq(
        {id => 1, name => "foo"},
        {id => 2, name => "foo"},
        {id => 3, name => "Whatever"},
        {id => 4, name => "But not Lena"},
    );

    is(
        $data->keyed_by(key 'id'),
        {
            1 => {id => 1, name => "foo"},
            2 => {id => 2, name => "foo"},
            3 => {id => 3, name => "Whatever"},
            4 => {id => 4, name => "But not Lena"},
        },
        'keyed_by');

    is(
        $data->keyed_by(key 'name')->length,
        3,
        'keyed_by name only has 3 entries');

    is(
        $data->keyed_by(key 'name')->values->map(key 'name')->sort(by_str),
        $data->distinct_by(key 'name')->map(key 'name')->sort(by_str),
        'keyed_by->values is like distinct_by');
}

# itern
{
    my $data = seq(map { $_ => "foo" } 0 .. 9);
    my @tuples;
    $data->itern(2, sub($k,$v) {
        push @tuples, [$k,$v];
    });
    is(\@tuples, [
        [0 => "foo"],
        [1 => "foo"],
        [2 => "foo"],
        [3 => "foo"],
        [4 => "foo"],
        [5 => "foo"],
        [6 => "foo"],
        [7 => "foo"],
        [8 => "foo"],
        [9 => "foo"],
    ], 'itern 1');

    my @sum2;
    $data->itern(4, sub($k1,$v1,$k2,$v2) {
        push @sum2, [$k1+$k2, $v1.$v2];
    });
    is(\@sum2, [
        [1  => "foofoo"],
        [5  => "foofoo"],
        [9  => "foofoo"],
        [13 => "foofoo"],
        [17 => "foofoo"],
    ], 'itern 2');

    my @iter3;
    Seq->range(1, 1_000_000_000)->take(10)->itern(3, sub($x,$y,$z) {
        push @iter3, [$x,$y,$z]
    }),
    is(
        \@iter3,
        [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
        ],
        'itern 3');

    my $hash = {};
    seq(1,"a",2,"b",3)->itern(2, sub($k,$v) {
        $hash->{$k} = $v;
    });
    is(
        $hash,
        {
            1 => "a",
            2 => "b",
        },
        'only loops over multiple of 2');

    my $sum = array;
    Seq::itern(seq(1,2,3,4,5,6,7), 3, sub($x,$y,$z) { $sum->push($x+$y+$z) });
    is($sum, [6,15], 'only loops over multiple of 3');
}

# to_arrays
is(
    # Got
    Seq::to_arrays(seq(
        foo => seq(1,2,3),
        bar => seq(
            file1  => "whatever",
            folder1 => seq(
                file2 => "blub",
                file3 => "Whaaaagh!",
            ),
            folder2 => seq(
                folder3 => seq(
                    file4 => "For The Emporer!",
                ),
            ),
        ),
        "test",
        maz => seq(
            Ok (seq(qw/foo bar/)),
            Err(seq(qw/foo bar/)),
        ),
        folder4 => [
            seq(4,5,6),
            "foo",
            seq(7,8,9),
        ],
        {
            content1 => seq(6,6,6),
            content2 => [
                seq(1,1,1),
                seq(2,2,2),
                Some([Seq->range(1,3), Seq->range(3,1)]),
            ],
        }
    )),
    # Expected
    [
        foo => [1,2,3],
        bar => [
            file1   => "whatever",
            folder1 => [
                file2 => "blub",
                file3 => "Whaaaagh!",
            ],
            folder2 => [
                folder3 => [
                    file4 => "For The Emporer!",
                ],
            ],
        ],
        "test",
        maz => [
            Ok ([qw/foo bar/]),
            Err([qw/foo bar/]),
        ],
        folder4 => [
            [4,5,6],
            "foo",
            [7,8,9],
        ],
        {
            content1 => [6,6,6],
            content2 => [
                [1,1,1],
                [2,2,2],
                Some([[1,2,3], [3,2,1]]),
            ],
        },
    ],
    'to_arrays');

{
    # Generates Array of Hashes
    # id goes from 1..10
    # names are provided
    # points are random
    my $data = Seq::map3(
        Seq->range(1,10),
        seq(qw/Anny Lilly Lena Angel Cherry Kristel Candy Cleopatra Sweetie Crista/),
        Sq->rand->int(1,100)->take(10),
        record(qw/id name points/),
    )->cache;
    # dump($data);

    is(
        $data->find_windowed(3, key_equal(id => 4)),
        Some($data->slice(0..6)),
        'find 4 with 3 amount');
    is(
        $data->find_windowed(1, key_equal(id => 4)),
        Some($data->slice(2,3,4)),
        'find 4 with 1 amount');
    is(
        $data->find_windowed(0, key_equal(id => 4)),
        Some($data->slice(3)),
        'find 4 with 0 amount');
    is(
        $data->find_windowed(100, key_equal(id => 4)),
        Some($data->to_array),
        'find with amount bigger than $data');
    is(
        $data->find_windowed(3, key_equal(id => 1)),
        Some($data->slice(0,1,2,3)),
        'find first');
    is(
        $data->find_windowed(3, key_equal(id => 100)),
        None,
        'find not existing');
    is(
        $data->find_windowed(3, key_equal(id => 10)),
        Some($data->slice(6,7,8,9)),
        'find last');
}

# slice
{
    my $range = Seq->range(0,10);
    is($range->slice(),              [],            'slice wo args');
    is($range->slice(1,5,5,2,3,9),   [1,5,5,2,3,9], 'slice');
    is($range->slice(-1, -2, -3),    [],            'slice with negative index is not supported');
    is($range->slice(20,30),         [],            'slice with out of bound 1');
    is($range->slice(1,20,2,-20,3),  [1,2,3],       'slice with out of bound 2');
    is($range->slice(10,-11),        [10],          'slice exact bounds 1');
    is($range->slice(-11,10),        [10],          'slice exact bounds 2');
}

# average
is(Seq::average(seq(1 .. 10)), 5.5, 'average 1');
is(seq(1 .. 10)->average,      5.5, 'average 2');
is(
    Seq->init(10, sub($idx) {
        { id => $idx+1, num => $idx+1 }
    })->average_by(key 'num'),
    5.5,
    'average_by 1');
is(
    Seq->init(10, sub($idx) {
        { id => $idx,   num => $idx+1 }
    })->average_by(key 'num'),

    Seq->init(10, sub($idx) {
        { id => $idx+1, num => $idx+1 }
    })->map(key 'num')->average,

    'average_by 2');

{
    my $data = sq {
        1 => "Anny",
        2 => "Lilly",
        3 => "Zola",
    };

    my $kv = sub($k,$v) { [$k,$v] };
    one_of(
        Seq->from_hash($data, $kv),
        array([1,'Anny'], [2,'Lilly'], [3, 'Zola'])->permute->map(call 'to_seq'),
        'from_hash 1');

    # test if Hash::to_seq is the same as Seq::from_hash
    one_of(
        $data->to_seq($kv),
        array([1,'Anny'], [2,'Lilly'], [3, 'Zola'])->permute->map(call 'to_seq'),
        'to_seq');
}

# keep_some behaviour testing when Some contains multiple values
{
    is(
        Seq::keep_some(seq(Some(1,2,3), Some(4,5,6))),
        seq(1,2,3,4,5,6),
        'keep_some multi 1');

    is(
        Seq::keep_some(seq(Some([1,2,3]), Some([4,5,6]))),
        seq([1,2,3], [4,5,6]),
        'keep_some multi 2');

    is(
        Seq::keep_some(seq(Some([1,2,3]), Some([4,5,6])))->merge,
        seq(1,2,3,4,5,6),
        'keep_some multi 3');
}

# combine($f_key, @fields)
# combine works on an array of hashes. With $f_key you specify which
# hashes should be combined. And @fields combines all defined fields from
# all hashes into an array.
# returns an array of hashes again, and some hashes are combined.
{
    my $game = record(qw/id name tag comment/);
    my $data = seq(
        $game->(1, "Zelda",       "Action-Adventure", ""),
        $game->(1, "Zelda",       "Link"            , ""),
        $game->(1, "Zelda",       "Ganon"           , ""),
        $game->(2, "Mario 64",    "Mario"           , ""),
        $game->(2, "Mario 64",    "Jump N Run"      , ""),
        $game->(3, "Doom 64",     "Ego-Shooter"     , ""),
        $game->(4, "Blast Corps", "Rare"            , ""),
        $game->(4, "Blast Corps", "Destruction"     , ""),
        { name => "Turok", tag => "Ego-Shooter"}, # hash without id
    );

    is(
        $data->combine(key('id'), 'tag')->sort_by(by_num, key 'id'),
        [
            $game->(1, "Zelda",       ["Action-Adventure", "Link", "Ganon"], ""),
            $game->(2, "Mario 64",    ["Mario", "Jump N Run"]              , ""),
            $game->(3, "Doom 64",     ["Ego-Shooter"]                      , ""),
            $game->(4, "Blast Corps", ["Rare", "Destruction"]              , ""),
        ],
        'combine 1');
}

{
    my $game = record(qw/id name tag comment/);
    my $data = seq(
        $game->(1, "Zelda",       "Action-Adventure", "A"),
        $game->(1, "Zelda",       "Link",             "B"),
        $game->(1, "Zelda",       "Ganon",            "C"),
        $game->(2, "Mario 64",    "Mario",            "D"),
        $game->(2, "Mario 64",    "Jump N Run",       "E"),
        $game->(3, "Doom 64",     "Ego-Shooter",      "F"),
        $game->(4, "Blast Corps", "Rare",             "H"),
        $game->(4, "Blast Corps", "Destruction",      "I"),
        { name => "Turok", tag => "Ego-Shooter", comment => "G"}, # hash without "id"
    );

    is(
        $data->combine(key('id'), qw/tag comment/)->sort_by(by_num, key 'id'),
        [
            $game->(1, "Zelda",       ["Action-Adventure", "Link", "Ganon"], [qw/A B C/]),
            $game->(2, "Mario 64",    ["Mario", "Jump N Run"],               [qw/D E/]),
            $game->(3, "Doom 64",     ["Ego-Shooter"],                       ['F']),
            $game->(4, "Blast Corps", ["Rare", "Destruction"],               [qw/H I/]),
        ],
        'combine 2');
}

# test if combine() doesn't share data
{
    my $orig = sq [
        { id => 1, tags => ['foo']},
        { id => 1, tags => ['foo']},
        { id => 1, tags => ['foo']},
        { id => 1, tags => ['foo']},
    ];

    # we must create the sequence this way, so we can mutate something in $orig
    my $data = $orig->to_seq;

    my $new = $data->combine(key 'id', 'tags');
    is($new, [{ id => 1, tags => [['foo'],['foo'],['foo'],['foo']]}], 'combine 3');

    # mutate something on original data
    push $orig->[0]{tags}->@*, 'bar';

    # check if $new stays the same, and array-refs are not shared
    is($new, [{ id => 1, tags => [['foo'],['foo'],['foo'],['foo']]}], 'combine 4');
}


is(
    Seq::mean   (Seq->empty),
    Seq::mean_by(Seq->empty, \&id),
    'mean_by 1');

is(
    Seq::mean   (seq 100),
    Seq::mean_by(seq(100), \&id),
    'mean_by 2');
is(
    Seq->init(10, sub($i) { Seq->range(1,$i+1) })->map(call 'mean'),
    Seq->init(10, sub($i) { Seq->range(1,$i+1) })->map(call 'mean_by', \&id),
    'mean_by 3');

{
    # some values for the mean
    my $values = seq(10, 20, 30, 40, 9, 3, 12, 40);
    # this generates a seq of hashes where each value is the price, and
    # the index is used as the id field.
    my $data   = Seq::mapi($values, record(qw/price id/))->cache;

    is(
        Seq::mean   ($values),
        Seq::mean_by($data, key 'price'),
        'mean_by 4');

    is(
        Seq::mean   (Seq->range(0, Seq::length($values)-1)),
        Seq::mean_by($data, key 'id'),
        'mean_by 5');
}

# get_init on a sequence should anyway not really be used because
# it is very inefficent. It has to iterate through each element until
# it gets the index, so it can become very slow. It is still here
# because of API compatibility with Array.
#
# a real initialization also doesn't exist because there are no undef
# values for a sequence. Either there is a value for the index, or the
# index is outside the length of the sequence.
#
# The only thing a get_init() can provide is doing an initialization
# when the index is out of the sequence length. But then the value
# only can be returned. The sequence doesn't store that value.
{
    my $internal = Array->replicate(5, [0,0,0]);
    my $data     = Seq->from_array($internal);
    for my $idx ( 1,3,5,3 ) {
        my $array = $data->get_init($idx, [0,0,0]);
        $array->[0]++;
        $array->[1] += 10;
        $array->[2] += 100;
    }
    is($data, seq(
        [0,0,0],
        [1,10,100],
        [0,0,0],
        [2,20,200],
        [0,0,0],
    ), 'get_init with values');



    $data = Seq->from_array(Array->replicate(5, [0,0,0]));
    for my $idx ( 1,3,5,3 ) {
        my $array = $data->get_init($idx, sub($idx) { [$idx,0,0] });
        $array->[1] += 10;
        $array->[2] += 100;
    }
    is($data, seq(
        [0,0,0],
        [0,10,100],
        [0,0,0],
        [0,20,200],
        [0,0,0],
    ), 'get_init with function');
}

# replicate makes copies
{
    my $array = Seq->replicate(5, [0,0])->to_array;
    $array->iter2d(sub($value,$x,$y) {
        $array->[$y][$x] = "$y,$x";
    });
    is($array, [
        ["0,0", "0,1"],
        ["1,0", "1,1"],
        ["2,0", "2,1"],
        ["3,0", "3,1"],
        ["4,0", "4,1"],
    ], 'replicate does copy');
}


done_testing;
