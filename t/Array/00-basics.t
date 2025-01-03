#!perl
use 5.036;
use List::Util qw(reduce);
use Scalar::Util qw(refaddr);
use Sq;
use Sq::Sig;
use Sq::Test;

# Some values, functions, ... for testing
my $range     = Array->range(1, 10);
my $rangeDesc = Array->range(10, 1);

my $add     = sub($x, $y) { $x + $y     };
my $add1    = sub($x)     { $x + 1      };
my $double  = sub($x)     { $x * 2      };
my $square  = sub($x)     { $x * $x     };
my $is_even = sub($x)     { $x % 2 == 0 };

# checks new & bless
{
    my $a = Array->new(1,2,3);
    check_isa($a, 'Array', 'new');
    is($a, [1,2,3],        'new content');

    my $b = Array->bless([1,2,3]);
    check_isa($b, 'Array', 'bless');
    is($b, [1,2,3],        'bless content');
}

# Basic checks of range and rangeDesc
ok(defined $range,                'range returns something');
check_isa($range, 'Array',        'returns an Array');
is($range, [1 .. 10],             'is an array');
is(Array->range(1,1), [1],        'range is inclusive');
is($rangeDesc, [reverse 1 .. 10], 'rangeDesc');
is($range, $rangeDesc->rev,       'reverse of rangeDesc same as range');
is($range->map($double),     [2,4,6,8,10,12,14,16,18,20], 'map');
is($range->keep($is_even), [2,4,6,8,10],                 'keep');
is($range->take(5),    [1..5], 'take 1');
is($range->take(0),        [], 'take 2');
is($range->take(-1),       [], 'take 3');
is($range->length,         10, 'length');
is($range->take(5)->length, 5, 'take & length');
is($range->map($square)->keep($is_even),        [4,16,36,64,100], 'map keep');
is($range->map($square)->keep($is_even)->take(3),      [4,16,36], 'map keep take');
is($range->map($square)->keep_e('$_ % 2 == 0'), [4,16,36,64,100], 'keep_e');

is(
    Array->range(1,3)->map(sub($x) { ($x) x 3 }),
    ["111", "222", "333"],
    'map executes lambda in scalar context');

is(
    Array->range(1,1000)->map_e('$_ < 10 ? $_*2 : undef'),
    Array->range(1,1000)->map(sub { $_ < 10 ? $_*2 : undef }),
    'map_e same as map');

is(
    Array->range(1,3)->map_e('($_) x 3'),
    ["111", "222", "333"],
    'map_e with a list');

is(
    Array->range(1,10)->map(sub($x) { $x < 5 ? $x*$x : undef }),
    [1,4,9,16],
    'map with early exit');

# choose
{
    my $data = Array->range(1,10);
    is(
        $data->choose(sub($x) {
            $x % 2 == 0 ? Some($x * $x) : None
        }),
        [4,16,36,64,100],
        'choose');
}

# to_hash
{
    my $h = Array->new(qw/Hello World One Two/)->to_hash(sub($str) { $str => length $str });

    is(
        $h,
        {"Hello" => 5, "World" => 5, "One" => 3, "Two" => 3},
        'map with multiple return values and as_hash');

    check_isa($h, 'Hash', 'Is a Hash');
}

is($range->map(sub($x) { undef }), [], 'empty array');

is(
    $range->fold(0, sub($x,$length) { $length + 1 }),
    $range->length,
    'fold with non-reftype');
is(
    $range->fold([], sub($x,$array) { push @$array, $x; $array }),
    $range,
    'fold with reftype 1');
is(
    $range->fold([], sub($x,$array) { [@$array, $x ] }),
    $range,
    'fold with reftype 2');
is(
    $range->fold    ([], sub($x,$array) { push @$array, $x; $array }),
    $range->fold_mut([], sub($x,$array) { push @$array, $x         }),
    'fold_mut');

is(
    $range->fold_mut(Array->new, sub($x,$new) { $new->push($x) }),
    [1 .. 10],
    'Array->push should be used with fold_mut');

check_isa($range->rev, 'Array', 'rev return Array');
is($range->rev, [10,9,8,7,6,5,4,3,2,1], 'rev');
is(
    $range->rev->map($add1)->rev,
    [ $range->map($add1)->expand ],
    'to_list');

is($range->sum, 55, 'sum');
is($range->sum, $range->rev->sum, 'sum 2');

# Checking wrap & rangeStep
{
    # Currently on undef it aborts, should it just skip the undef and return
    # the values from 1 to 6?
    is(Array->new(1,2,3,undef,4,5,6), [1..3], 'new containing an undef');
    is(Array->new(5), [5], 'new');
    is(
        Array->new(5)->append(Array->new(10)),
        [5, 10],
        'wrap and append');
    is(
        Array->range(1,5)->append(Array->range(6,10)),
        Array->range(1,10),
        'append two ranges');
    is(Array->range_step(1, 2, 10), [ 1,3,5,7,9], '1 .. 10 step 2');
    is(Array->range_step(10, 2, 1), [10,8,6,4,2], '10 .. 1 step 2');
}

is(
    Array::zip(
        Array->new(qw/A B C D E F/),
        Array->range(0, 1_000),
    ),
    Array->new(qw/A B C D E F/)->indexed,
    'zip and indexed');

is(
    Array::zip([1 .. 10],['a' .. 'c']),
    [[1,'a'], [2,'b'], [3,'c']],
    'zip');

is(
    $range->take(3)->indexed,
    [[1,0], [2,1], [3,2]],
    'take->indexed');


is(Array->init(10, \&id)->map($add1), $range, 'init->map');
is(
    Array->init(5, sub($idx) { ($idx) x $idx }),
    [1,2,2,3,3,3,4,4,4,4],
    'init allows multiple return values from lambda');
is(
    Array->init(3, sub($idx) { $idx, undef }),
    [0,1,2],
    'init also skips undef');

is(
    Array->range(1,10)->indexed,
    Array->init(10, sub($idx) { [$idx+1, $idx] }),
    'range->indexed vs. init');

is(
    (reduce { $a->append($b) } map { Array->new($_) } 1 .. 10),
    $range,
    'append a list of wrapped values');
is(
    Array->concat(map { Array->new($_) } 1 .. 10),
    $range,
    'concat');

is(
    Array->concat, Array->empty,
    'concat on zero is empty');

is(
    Array->new(Array->range(1,10)->expand),
    [1 .. 10],
    'expand');

is(
    Array->new(1..5)->append(
        Array->new(6..10)
    ),
    Array->concat(
        sq [1..3],
        sq [4..6],
        sq [7..10],
    ),
    'append vs. concat');

is(
    Array->empty->append(Array->range(1,5))->append(Array->range(6,10)),
    $range,
    'append on empty');
is(
    Array->concat(
        Array->empty,
        Array->range(1,5),
        Array->empty,
        Array->range(10,12),
        Array->empty,
        Array->new("Hello"),
        Array->empty
    ),
    Array->new(1..5, 10..12, "Hello"),
    'concat with empties');
is(
    Array->from_array([1..10]),
    Array->new(1..10),
    'from_array and wrap');
is(
    Array->unfold(10, sub($state) {
        if ( $state > 0 ) {
            return $state, $state-1;
        }
        else {
            return undef;
        }
    }),
    Array->range(1,10)->rev,
    'unfold');

is(
    Array->new, Array->empty,
    'wrap without arguments same as empty');

# concat tests
{
    is(Array->concat, [], 'Empty concat');
    is(Array->concat($range), $range, 'concat with 1 element');
    is(
        Array->concat(
            Array->range(1,5),
            Array->range(6,10),
        ),
        [1..10],
        'concat with 2 elemets');
    is(
        Array->concat(
            Array->range(1,5),
            Array->range(6,10),
            Array->range(11,15),
        ),
        [1..15],
        'concat with 3 elements');
}

is($range->skip(0),   [1..10], 'skip(0)');
is($range->skip(-1),  [1..10], 'skip(-1)');
is($range->skip(-10), [1..10], 'skip(-10)');
is($range->skip(100), []     , 'skip(100)');

is($range->skip(3)->take(3),  [4,5,6], 'skip->take 1');
is($range->skip(3)->take(10), [4..10], 'skip->take 2');
is($range->skip(10)->take(1), [],      'skip->take 3');

is($range->take(0),   [],      'take(0)');
is($range->take(-1),  [],      'take(-1)');
is($range->take(-10), [],      'take(-10)');
is($range->take(100), [1..10], 'take(100)');

is($range->take(5)->skip(2),  [3,4,5], 'take->skip 1');
is($range->take(5)->skip(4),  [5],     'take->skip 2');
is($range->take(5)->skip(6),  [],      'take->skip 2');

is(
    Array->concat(
        Array->range(1,10),
        Array->range(10,1),
    ),
    Array->concat(
        $range,
        $range->rev
    ),
    'concat with rev');

is(Array->new([A => 1], [B => 2], [C => 3])->sum_by(\&snd), 6, 'sumBy');
is(
    Array->new(qw/H e l l o W o r l d !/)->join('-'),
    "H-e-l-l-o-W-o-r-l-d-!",
    'join');

is(
    Array->new(qw/Hello World you are awesome/)->to_hash(sub($x) { length $x => $x }),
    {
        3 => "are",
        5 => "World",
        7 => "awesome",
    },
    'to_hash 1');

is(
    Array->new(qw/Hello World you are awesome/)->to_hash(sub($x) { $x => length $x }),
    {
        "Hello"   => 5,
        "World"   => 5,
        "you"     => 3,
        "are"     => 3,
        "awesome" => 7,
    },
    'to_hash 2');

is(
    Array->new(qw/Hello World you are awesome/)->to_hash_of_array(sub($x) { length $x => $x }),
    {
        3 => ["you",   "are"   ],
        5 => ["Hello", "World" ],
        7 => ["awesome"],
    },
    'to_hash_of_array');

is(
    Array->new(qw/Hello World Awesome World/)->count,
    {
        Hello   => 1,
        World   => 2,
        Awesome => 1,
    },
    'count');

is(
    Array->new(qw/Hello World Awesome World/)->count_by(sub($str) { length $str }),
    {
        5 => 3,
        7 => 1,
    },
    'count_by');

is(
    Array->new(qw/Hello World Awesome World/)
    ->map(sub($x) { length $x })
    ->count,

    Array->new(qw/Hello World Awesome World/)->count_by(sub($str) { length $str }),
    'map->count same as count_by');

is(Array->new(1,1,2,3,1,4,5,4,3,2,6)->distinct, [1..6],              'distinct 1');
is(Array->new(1,2,3,2,23,123,4,12,2)->distinct, [1,2,3,23,123,4,12], 'distinct 2');
is(Array::distinct([1,2,3,2,23,123,4,12,2]),     [1,2,3,23,123,4,12], 'distinct 3');

# distinct_by tests
{
    my $data = sq [
        {id => 1, name => "Foo"},
        {id => 2, name => "Bar"},
        {id => 3, name => "Baz"},
        {id => 1, name => "Foo"},
    ];

    is($data->length, 4, 'distinct_by starts with 4');
    is($data->distinct->length, 4, 'still 4 as HashRefs are always unequal');
    is($data->distinct_by(sub($x) { $x->{id} })->length, 3, 'one element less');
    is(
        $data->distinct_by(sub($x) { $x->{id} }),
        [
            {id => 1, name => "Foo"},
            {id => 2, name => "Bar"},
            {id => 3, name => "Baz"},
        ],
        'check elements and order');
}

is(
    Array->new(qw/A B C D E F/)->mapi(sub($x,$i) { [$x,$i] }),
    [[A => 0], [B => 1], [C => 2], [D => 3], [E => 4], [F => 5]],
    'mapi');

is(
    Array->new(qw/A B C D E F/)->mapi(sub($x,$i) {
        return undef if $x eq 'D';
        return [$x,$i]
    }),
    [[A => 0], [B => 1], [C => 2]],
    'mapi with early abort');

is(
    Array->new(qw/A B C D E F/)->mapi(sub($x,$i) {
        return undef if $x eq 'D';
        return [$_,$i]
    }),
    [[A => 0], [B => 1], [C => 2]],
    'mapi with default variable');

is(Array->init( 0,  sub($idx) { $idx }), [], 'init with length 0');
is(Array->init(-1,  sub($idx) { $idx }), [], 'init with length -1');
is(Array->init(-10, sub($idx) { $idx }), [], 'init with length -10');
is(Array->range_step(1,1,1), [1], 'range_step with 1,1,1');

# TODO: floating point inaccuraccy
# is(
#     Array->range_step(0,0.1,1),
#     [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1],
#     'range_step with 0,0.1,1');

like(
    dies { Array->range_step(0,0,1) },
    qr/^\$step is 0/,
    'range_step dies with step size of zero');

is(
    $range->map($square)->keep($is_even),
    $range->choose(sub($x) {
        my $s = $x * $x;
        $s % 2 == 0 ? $s : undef
    }),
    'choose instead of map->keep');

is(
    Array
        ->range(1,5)
        ->choose(sub($x) {
            my $square = $x * $x;
            return $square % 2 == 0 ? $square : undef
        }),
    Array
        ->range(1,5)
        ->map( sub($x) { $x * $x     })
        ->keep(sub($x) { $x % 2 == 0 }),
    'square and even');

is($range->find(sub($x) { $x > 5  }),   Some(6), 'find 1');
is($range->find(sub($x) { $x > 10 }),      None, 'find 2');
is($range->find(sub($x) { $x > 10 })->or(0),  0, 'find 3');

is(
    $range->bind(sub($x) { Array->new($x) }),
    [1 .. 10],
    'bind - somehow like id');

is(
    Array->new(
        Array->new(1,1),
        [2,3],
        Array->new(5,8,13),
    )->flatten,
    [1,1,2,3,5,8,13],
    'flatten - flattens an array of array');

is(Array->new([1,1], [1,2]), [[1,1],[1,2]], 'wrap with arrays');
is(Array->new([1,1])       , [[1,1]],       'wrap with array');
is(Array->from_array([1,1]) , [1,1],         'from_array vs. wrap');

is($range->reduce($add),         Some(55), 'reduce');
is(Array->empty->reduce($add),       None, 'reduce on empty 1');
is(Array->empty->reduce($add)->or(0),   0, 'reduce on empty 2');
is(Array->new(1)->reduce($add),  Some(1), 'reduce on single element');

is(Array->empty->first,          None, 'first on empty');
is(Array->empty->first->or(0),      0, 'first and optional');
is($range->first,             Some(1), 'first on non empty');
is($range->first->or(0),            1, 'first on non empty and option::or');

is(Array->empty->last,           None, 'last on empty');
is(Array->empty->last->or(0),       0, 'last on empty with or');
is($range->last,             Some(10), 'last on non empty');
is($range->last->or(0),            10, 'last on non empty with option::or');

is(
    Array->new(1,5,-3,10,9,-2)->sort(by_num),
    [-3,-2,1,5,9,10],
    'sort 1');

is(
    Array->new(qw/B b c A a C/)->sort(by_str),
    [qw/A B C a b c/],
    'sort 2');

# Schwartzian Transformation
{
    my $data = sq [
        { id => 1, char => 'W' },
        { id => 4, char => 'L' },
        { id => 5, char => 'D' },
        { id => 2, char => 'O' },
        { id => 3, char => 'R' },
    ];

    is(
        $data->sort_by(sub($x,$y) { $x <=> $y }, sub($x) { $x->{id} }),
        [
            { id => 1, char => 'W' },
            { id => 2, char => 'O' },
            { id => 3, char => 'R' },
            { id => 4, char => 'L' },
            { id => 5, char => 'D' },
        ],
        'sort_by 1');

    is(
        $data->sort_by(sub($x,$y) { $x cmp $y }, sub($x) { $x->{char} }),
        [
            { id => 5, char => 'D' },
            { id => 4, char => 'L' },
            { id => 2, char => 'O' },
            { id => 3, char => 'R' },
            { id => 1, char => 'W' },
        ],
        'sort_by 2');

    is(
        $data
        ->map (sub($x)    { [$x->{id} ,  $x     ] })
        ->sort(sub($x,$y) {  $x->[0] <=> $y->[0]  })
        ->map (sub($x)    {  $x->[1]              }),

        $data->sort_by(sub($x,$y) { $x <=> $y }, sub($x) { $x->{id} }),
        'sort_by 3');
}

my $fs = Array->new([1,"Hi"],[2,"Foo"],[3,"Bar"],[4,"Mug"]);
is($fs->fsts, [1,2,3,4],            'fsts');
is($fs->snds, [qw/Hi Foo Bar Mug/], 'snds');

is(
    Array->new([1,2,3], [4,5,6], [7,8,9])->flatten,
    [1..9],
    'flatten');

is(
    Array::zip(
        Array->range(1,6),
        Array->new(qw(A B C D E F))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/],[qw/5 E/],[qw/6 F/]],
    'zip 1');

is(
    Array::zip(
        Array->range(1,3),
        Array->new(qw(A B C D E F))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/]],
    'zip 2');

is(
    Array::zip(
        Array->range(1,6),
        Array->new(qw(A B C D))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/]],
    'zip 3');

is(
    Array::zip(
        Array->empty,
        Array->new(qw(A B C D E F))
    ),
    [],
    'zip 4');

is(
    Array::zip(
        Array->range(1,6),
        Array->empty,
    ),
    [],
    'zip 5');

is(
    Array::zip(
        [ 1,2,3    ],
        [ 4,5,6    ],
        [ 7,8,9    ],
        [ 10,11,12 ],
    ),
    [ [1,4,7,10], [2,5,8,11], [3,6,9,12] ],
    'zip 6');

is(
    Array::zip(
        [ 1,2,3    ],
        [ 4,5,6,7  ],
        [ 7,8,9    ],
        [ 10,11,12 ],
    ),
    [ [1,4,7,10], [2,5,8,11], [3,6,9,12] ],
    'zip 7');

is(
    Array::zip(
        [  1, 2, 3       ],
        [  4, 5, 6, 7    ],
        [  7, 8, 9       ],
        [ 10,11,12,13,14 ],
    ),
    [ [1,4,7,10], [2,5,8,11], [3,6,9,12] ],
    'zip 8');

is(
    sq([
        [1,2,3],
        [4,5,6],
        [7,8,9],
    ]),
    [
        [1,2,3],
        [4,5,6],
        [7,8,9],
    ],
    'Is array of array');

is(
    Array->new(
        Array->new(1,2,3),
        Array->new(4,5,6),
        Array->new(7,8,9),
    )->to_array_of_array,
    [
        [1,2,3],
        [4,5,6],
        [7,8,9],
    ],
    'to_array_of_array is noop');

is($range->any (sub($x) { $x < 1   }), 0, 'any value smaller 0');
is($range->any (sub($x) { $x < 2   }), 1, 'any value smaller 1');
is($range->all (sub($x) { $x < 1   }), 0, 'all values smaller 1');
is($range->all (sub($x) { $x < 11  }), 1, 'all values smaller 1');
is($range->none(sub($x) { $x > 1   }), 0, 'none value greater 1');
is($range->none(sub($x) { $x > 10  }), 1, 'none value greater 10');

{
    is(
        $range->pick(sub($x) { $x*$x > 1000 ? Some($x*$x) : None }),
        None,
        'pick squared element that is greater 1000');
    is(
        $range->pick(sub($x) { $x*$x > 1000 ? Some($x*$x) : None })->or('NO'),
        "NO",
        'pick squared element that is greater 1000');
    is(
        $range->pick(sub($x) { $x*$x > 50 ? Some($x*$x) : None }),
        Some(64),
        'pick squared element that is greater 50');
    is(
        $range->pick(sub($x) { $x*$x > 50 ? Some($x*$x) : None })->or('No'),
        64,
        'pick squared element that is greater 50');

    # pod examples
    my $r   = Array->range(1,10);
    is($r->pick(sub($x) { $x >  5 ? Some($x*$x) : None }),     Some(36), 'pod example 1');
    is($r->pick(sub($x) { $x > 10 ? Some($x*$x) : None }),         None, 'pod example 2');
    is($r->pick(sub($x) { $x > 10 ? Some($x*$x) : None })->or(100), 100, 'pod example 3');
}

is( $range->windowed(-1), Array->empty,           'windowed -1');
is( $range->windowed(0) , []          ,           'windowed 0');
is( $range->windowed(1) , [map { [$_] } 1 .. 10], 'windowed 1');
is(
    $range->windowed(2),
    [ [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10] ],
    'windowed 2');
is(
    $range->windowed(5),
    [
        [1,2,3,4,5], [2,3,4,5,6], [3,4,5,6,7], [4,5,6,7,8], [5,6,7,8,9], [6,7,8,9,10]
    ],
    'windowed 5');

is($range->windowed(10), [ [1,2,3,4,5,6,7,8,9,10] ], 'windowed 10');
is($range->windowed(11), [],                         'windowed 11');

is(Array->new()     ->intersperse(0), [],              'intersperse 1');
is(Array->new(1)    ->intersperse(0), [1],             'intersperse 2');
is(Array->new(1,2)  ->intersperse(0), [1,0,2],         'intersperse 3');
is(Array->new(1,2,3)->intersperse(0), [1,0,2,0,3],     'intersperse 4');
is(Array->new(1..4) ->intersperse(0), [1,0,2,0,3,0,4], 'intersperse 5');
is(
    Array->range(1,10)->intersperse(0),
    [1,0,2,0,3,0,4,0,5,0,6,0,7,0,8,0,9,0,10],
    'intersperse 6');

is(Array->new(5)    ->repeat(-1), [],            'repeat 1');
is(Array->new(5)    ->repeat(0) , [],            'repeat 2');
is(Array->new(5)    ->repeat(1) , [5],           'repeat 3');
is(Array->new(5)    ->repeat(5) , [5,5,5,5,5],   'repeat 4');
is(Array->new(1,2,3)->repeat(2) , [1,2,3,1,2,3], 'repeat 5');
is(Array->new(1,2,3)->repeat(3) , [(1,2,3) x 3], 'repeat 6');

is(Array->replicate(10, 'A'), [('A') x 10], 'replicate');

is(
    Array::zip(
        Array->replicate(10, 1),
        Array->new(qw/A B C D E F/),
    ),
    [ [1,'A'],[1,'B'],[1,'C'],[1,'D'],[1,'E'],[1,'F'] ],
    'replicate with zip');

is(
    Array::zip(
        Array->new(1,2)->repeat(9),
        Array->new(qw/A B C D E F/),
    ),
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],[2,'F'] ],
    'repeat with zip 1');

is(
    Array::zip(
        Array->new(1,2)->repeat(2),
        Array->new(qw/A B C D E F/),
    ),
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'] ],
    'repeat with zip 2');

is(
    Array::zip(
        Array->new(1,2)->repeat(20),
        Array->new(qw/A B C D E/)->repeat(20),
    )->take(12),
    [
        [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],
        [2,'A'],[1,'B'],[2,'C'],[1,'D'],[2,'E'],
        [1,'A'],[2,'B'],
    ],
    'zip on repeat');

is(
    Array::zip(
        $range->repeat(10),
        $range->rev->repeat(10),
    )->take(15),
    [
        [1,10],[2,9],[3,8],[4,7],[5,6],[6,5],[7,4],[8,3],[9,2],[10,1],
        [1,10],[2,9],[3,8],[4,7],[5,6],
    ],
    'zip on repeat with reverse');

is(
    Array::zip(
        $range->repeat(10),
        $range->rev->repeat(10),
    )->take(15)->map(sub($tuple) { fst($tuple) + snd($tuple) }),

    Array->replicate(20, 11)->take(15),
    'zip,infinity,rev,take,map,always');

is(
    sq([1, 3, 20, -40, 20, 12, 100, 5, 20])
    ->take_while(sub($x) { $x < 100 }),
    [1,3,20,-40,20,12],
    'take_while 1'
);

is(
    sq([1, 3, 20, -40, 20, 12, 100, 5, 20])
    ->take_while(sub($x) { $x > 100 }),
    [],
    'take_while 2'
);

is(
    sq([1, 3, 20, -40, 20, 12, 100, 5, 20])
    ->skip_while(sub($x) { $x < 100 }),
    [100, 5, 20],
    'skip_while 1'
);

is(
    sq([1, 3, 20, -40, 20, 12, 100, 5, 20])
    ->skip_while(sub($x) { $x > 100 }),
    [1,3,20,-40,20,12,100,5,20],
    'skip_while 2'
);

 # iter
{
    my @iter;
    $range->iter(sub($x) { push @iter, $x });
    is(\@iter, [1..10], 'iter');
}

# iteri & foreachi
{
    my @iteri;
    $range->iteri(sub($x,$i) { push @iteri, [$i,$x] });
    is(\@iteri, [[0,1], [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]], 'iteri');
}

# sort
is(Array->new(qw/1 9 10 5/)->sort(by_str), [qw/1 10 5 9/], 'sort_str');
is(Array->new(qw/1 9 10 5/)->sort(by_num), [1, 5, 9, 10],  'sort_num');

# keyed_by
{
    my $data = sq [
        {id => 1, name => "foo"},
        {id => 2, name => "foo"},
        {id => 3, name => "Whatever"},
        {id => 4, name => "But not Lena"},
    ];

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

# test sorting with by_num & by_str
{
    my $data = sq [
        { id => 2,  name => 'B' },
        { id => 3,  name => 'A' },
        { id => 1,  name => 'C' },
        { id => 10, name => 'J' },
    ];

    is(
        $data->sort_hash(by_str, 'name'),
        [
            {id =>  3, name => 'A'},
            {id =>  2, name => 'B'},
            {id =>  1, name => 'C'},
            {id => 10, name => 'J'}
        ],
        'sort_hash by_str name');

    is(
        $data->sort_hash(by_str, 'id'),
        [
            {id =>  1, name => 'C'},
            {id => 10, name => 'J'},
            {id =>  2, name => 'B'},
            {id =>  3, name => 'A'},
        ],
        'sort_hash by_str id');

    is(
        $data->sort_hash(by_num, 'id'),
        [
            {id =>  1, name => 'C'},
            {id =>  2, name => 'B'},
            {id =>  3, name => 'A'},
            {id => 10, name => 'J'},
        ],
        'sort_hash by_num id');
}

is(
    sq([qw/foo bar baz foo bar foo 1 2/])->count,
    {
        foo => 3,
        bar => 2,
        baz => 1,
        1   => 1,
        2   => 1,
    },
    'count');

# mutation
{
    my $data = Array->range(1,5);
    is($data, [1..5], 'mutation 1');

    $data->push(6,7,8);
    is($data, [1..8], 'mutation 2');

    my $first = $data->shift;
    is($first, 1, 'first element');
    is($data, [2..8], 'mutation 3');

    my $last = $data->pop;
    is($last, 8, 'last element');
    is($data, [2..7], 'mutation 4');

    $data->unshift($first, $last);
    is($data, [1,8,2..7], 'mutation 5');

    # push/unshift does undef checking
    $data->push(undef);
    is($data, [1,8,2..7], 'no undef at end');

    $data->unshift(undef);
    is($data, [1,8,2..7], 'no undef at start');

    # push that contains undef
    $data->push(11,12,undef,13);
    is($data, [1,8,2..7,11,12], 'only pushes values up to first undef');

    # unshift that contains undef
    $data->unshift(15,16,undef,17);
    is($data, [15,16,1,8,2..7,11,12], 'unshift only up to first undef');
}

# extract
{
    # index: 0 1 2 3 4 5 6 7 8 9
    # data:   1 2 3 4 5 6 7 8 9 10
    my $data = Array->range(1,10);
    is($data->extract(0,3),   [1,2,3],      'extract at beginning');
    is($data->extract(1,3),   [2,3,4],      'extract skipping first');
    is($data->extract(20,10), [],           'extract empty');
    is($data->extract(5,100), [6,7,8,9,10], 'extract to the end');
    is($data->extract(3,3),   [4,5,6],      'extract of 3');
    is($data->extract(9,1),   [10],         'extract at end');
    is($data->extract(9,10),  [10],         'extract at end');
    is($data->extract(10,1),  [],           'extract out of bound');
    is($data->extract(0,0),   [],           'extract with zero length');
    is($data->extract(0,-10), [],           'extract with negative length');
    is($data->extract(-3,3),  [8,9,10],     'extract with negative position 1');
    is($data->extract(-3,2),  [8,9],        'extract with negative position 2');
    is($data->extract(-3,0),  [],           'extract with negative position and 0 length');
    is($data->extract(-3,-3), [],           'extract both values negative');
    is($data->extract(1,3), $data->skip(1)->take(3), 'extract is like skip->take');
}

# copy of array-ref
{
    my $data = sq [1,2,3,4,5];
    my $new  = $data->copy;

    is($data, $new,         'contains same data');
    ok(not ($data eq $new), 'not same array references');

    my $new2  = Array::copy([1,2,3,undef,4,5,6]);
    is($new2, [1,2,3], 'copy only copies up to first undef');
}

is($range->keep($is_even), $range->keep_e('$_ % 2 == 0'), 'keep_e');
is(
    sq([ 7,8,9,10 ])->cartesian([ "Hearth", "Spades" ]),
    [
        [7,"Hearth"], [7,"Spades"],  [8,"Hearth"],  [8,"Spades"],
        [9,"Hearth"], [9,"Spades"], [10,"Hearth"], [10,"Spades"],
    ],
    'cartesian');

# split and join
{
    my $words = sq(["Foo+Bar+Baz", "maz+faz"])->split(qr/\+/);

    is(
        $words,
        [[qw/Foo Bar Baz/], [qw/maz faz/]],
        'strings splitted into arrays');

    is(
        $words->map(sub($inner) { $inner->join('+') }),
        ["Foo+Bar+Baz", "maz+faz"],
        'joining inner arrays');
}

# bliting
{
    my $source = Array->range(100,110);
    my $target = Array->range(1,10);

    $source->blit(0, $target, 5, 2);
    is($source, [100..110],                 '$source did not change');
    is($target, [1,2,3,4,5,100,101,8,9,10], 'new $target');

    $source->blit(20, $target, 0, 3);
    is($target, [1,2,3,4,5,100,101,8,9,10], 'blit outside of range 1');

    $source->blit(9, $target, 0, 3);
    is($target, [109,110,3,4,5,100,101,8,9,10], 'blit outside of range 2');

    $source->blit(5, $target, 10, 3);
    is($target, [109,110,3,4,5,100,101,8,9,10,105,106,107], 'blit can append 1');

    $source->blit(5, $target, 14, 1);
    is(
        $target,
        [109,110,3,4,5,100,101,8,9,10,105,106,107,undef,105],
        'blit can append 2');

    $source->blit(-3, $target, -1, 5);
    is(
        $target,
        [109,110,3,4,5,100,101,8,9,10,105,106,107,undef,108,109,110],
        'blit with negative index');

    $source->blit(-3, $target, 0, 3);
    is(
        $target,
        [108,109,110,4,5,100,101,8,9,10,105,106,107,undef,108,109,110],
        'blit with negative index 2');

    $source->blit(5, $target, -3, 4);
    is(
        $target,
        [108,109,110,4,5,100,101,8,9,10,105,106,107,undef,105,106,107,108],
        'blit with negative index 3');

    is($source, [100..110], '$source never changed');
}

{
    my $source = Array->range(100,105);
    my $target = Array->range(1,5);

    $source->blit(0,  $target, 0,    3);
    is($target, [100,101,102,4,5], 'pod example 1');

    $source->blit(-2, $target, 0,  100);
    is($target, [104,105,102,4,5], 'pod example 2');

    $source->blit(4,  $target, -3,   2);
    is($target, [104,105,104,105,5], 'pod example 3');

    $source->blit(0,  $target, -1,   100);
    is($target, [104,105,104,105,100,101,102,103,104,105], 'pod example 4');
}

# to_array
{
    my $data = Array->range(1,100);

    my $same = $data->to_array;
    is(refaddr($same), refaddr($data), 'same array/address');

    is($data->to_array(0),    [],       'zero count');
    is($data->to_array(-1),   [],       'negative count');
    is($data->to_array(10),   [1..10],  'slice of array');
    is($data->to_array(1000), [1..100], 'count bigger than array');

    is(refaddr($data->to_array(1000)), refaddr($data), 'same array/address');
}

# to_seq
{
    my $data = Array->range(1,3)->to_seq->infinity->to_array(25);
    is(
        $data,
        [1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1],
        'to_seq on array');
}

# slice
{
    my $range = Array->range(0,10);
    is($range->slice(),              [],            'slice wo args');
    is($range->slice(1,5,5,2,3,9),   [1,5,5,2,3,9], 'slice');
    is($range->slice(-1, -2, -3),    [10,9,8],      'slice with negative index');
    is($range->slice(20,30),         [],            'slice with out of bound 1');
    is($range->slice(1,20,2,-20,3),  [1,2,3],       'slice with out of bound 2');
    is($range->slice(10,-11),        [10,0],        'slice exact bounds');
}

# distinct_by POD example
{
    my $data = sq [
        {id => 1, name => "foo"},
        {id => 3, name => "foo"},
        {id => 1, name => "bar"},
        {id => 2, name => "bar"},
    ];

    is(
        $data->distinct_by(key 'id'),
        [
            {id => 1, name => "foo"},
            {id => 3, name => "foo"},
            {id => 2, name => "bar"},
        ],
        'distinct_by pod example 1');

    is(
        $data->distinct_by(key 'name'),
        [
            {id => 1, name => "foo"},
            {id => 1, name => "bar"},
        ],
        'distinct_by pod example 2');
}

# pod example
{
    my $data = sq [
        { id => 2, name => 'Frank'  },
        { id => 1, name => 'Anne'   },
        { id => 3, name => 'Zander' },
    ];

    is(
        $data->sort_by(by_num, key 'id'),
        [
            { id => 1, name => 'Anne'   },
            { id => 2, name => 'Frank'  },
            { id => 3, name => 'Zander' },
        ],
        'pod example 1. id sorted');

    is(
        $data->sort_by(by_str, key 'name'),
        [
            { id => 1, name => 'Anne'   },
            { id => 2, name => 'Frank'  },
            { id => 3, name => 'Zander' },
        ],
        'pod example 2. name sorted');

    is(
        [
            map  { $_->[0]             }
            sort { $a->[1] <=> $b->[1] }
            map  { [ $_, $_->{id} ]    }
                @$data
        ],
        [
            { id => 1, name => 'Anne'   },
            { id => 2, name => 'Frank'  },
            { id => 3, name => 'Zander' },
        ],
        'pod example. pure perl');
}

# chunked
{
    is(
        Array->range(1,10)->chunked(1),
        [[1], [2], [3], [4], [5], [6], [7], [8], [9], [10]],
        'chunked 1');

    is(
        Array->range(1,10)->chunked(2),
        [[1,2], [3,4], [5,6], [7,8], [9,10]],
        'chunked 2');

    is(
        Array->range(1,10)->chunked(3),
        [[1,2,3], [4,5,6], [7,8,9], [10]],
        'chunked 3');

    is(
        Array->range(1,10)->chunked(4),
        [[1,2,3,4], [5,6,7,8], [9,10]],
        'chunked 4');
}

is(sq([10,3,11,4,10])   ->sort(by_num),  [3,4,10,10,11],    'POD sort 1');
is(sq([qw/foo BAR baa/])->sort(by_str),  [qw/BAR baa foo/], 'POD sort 2');
is(sq([qw/foo BAR baa/])->sort(by_stri), [qw/baa BAR foo/], 'POD sort 3');

is(Array->range(1,10)->remove($is_even), [1,3,5,7,9], 'remove');

# diff
is(Array::diff([1,2,3],  [1,3],     \&id),            [2], 'diff 1');
is(Array::diff([1..10],  [1,3,7,2], \&id), [4,5,6,8,9,10], 'diff 2');

{
    my sub entry($id,$name) { {id => $id, name => $name } }
    is(
        Array::diff([
                entry(1, "hello"),
                entry(2, "world"),
                entry(3, "test"),
            ], [
                entry(2, "abba"),
                entry(3, "test"),
                entry(5, "what"),
            ],
            key 'id'
        ),
        [entry(1, "hello")],
        'diff 3');

    is(
        Array::diff([
                entry(1, "hello"),
                entry(2, "world"),
                entry(3, "test"),
            ], [
                entry(2, "abba"),
                entry(3, "test"),
                entry(5, "what"),
            ],
            key 'name'
        ),
        [entry(1, "hello"), entry(2, "world")],
        'diff 4');

    is(
        Array::diff([
                entry(2, "world"),
                entry(1, "hello"),
                entry(3, "test"),
                entry(4, "new"),
            ], [
                entry(3, "test"),
                entry(5, "what"),
                entry(2, "world"),
            ],
            key 'id'
        ),
        [entry(1, "hello"), entry(4, "new")],
        'diff 5');

    is(
        Array::diff([
                entry(4, "new"),
                entry(3, "test"),
                entry(2, "world"),
                entry(1, "hello"),
            ], [
                entry(3, "test"),
                entry(5, "what"),
                entry(2, "world"),
            ],
            key 'id'
        ),
        [entry(4, "new"), entry(1, "hello")],
        'diff 6');

    is(
        Array::diff([
                entry(2, "world"),
                entry(1, "hello"),
                entry(3, "test"),
                entry(4, "new"),
            ], [
                entry(3, "test"),
                entry(5, "what"),
                entry(2, "foo"),
            ],
            key 'name'
        ),
        [entry(2, "world"), entry(1, "hello"), entry(4, 'new')],
        'diff 7');
}

# testing shuffle
# I don't see a direct way to test if it shuffled. not even testing if they are
# not the same wouldn't work. Theoretically it could shuffle and in the end is
# the same as the input. This is extremely rare, but can happen. But instead
# i can test other properties like that the elements stay the same. The array
# that returned is a new one. And calling the same operation after shuffle
# must yield the same results.
{
    my $data    = sq [1,2,3, 1,2,3, 4,5, 6,6,6, 7,8];
    my $shuffle = $data->shuffle;

    ok(refaddr($data) != refaddr($shuffle), 'different arrays');
    is($data, [1,2,3, 1,2,3, 4,5, 6,6,6, 7,8],  "original didn't shuffle");
    is($data->count, {
        1 => 2, 2 => 2, 3 => 2, 4 => 1, 5 => 1, 6 => 3, 7 => 1, 8 => 1,
    }, 'direct check');
    is($data->count, $shuffle->count, 'count must be the same');
    is($data->sort(by_num), $shuffle->sort(by_num), 'both sorting must be the same');
}

is(
    Array::fill_blanks([
        [1,2,3],
        [4,5,6,7],
        [1,2],
        [1],
    ], sub { 0 }),
    [
        [1,2,3,0],
        [4,5,6,7],
        [1,2,0,0],
        [1,0,0,0],
    ],
    'fill_blanks');

# trim
{
    my $data = sq [
        "   foo",
        "bar   ",
        "   f  ",
        "\nfoo\n",
        " foo  bar ",
    ];

    is($data->trim, [
        "foo",
        "bar",
        "f",
        "foo",
        "foo  bar",
    ], 'trim 1');

    is($data, [
        "   foo",
        "bar   ",
        "   f  ",
        "\nfoo\n",
        " foo  bar ",
    ], '$data did not change');
}

done_testing;