#!perl
use 5.036;
use List::Util qw(reduce);
use builtin qw(refaddr);
use Sq -sig => 1;
use Sq::Gen qw(gen_run gen);
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
is($range->keep($is_even),   [2,4,6,8,10],               'keep');
is($range->take(5),    [1..5], 'take 1');
is($range->take(0),        [], 'take 2');
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
    is(array(5), [5], 'new');
    is(
        array(5)->append(array 10),
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
    ["", "1", "22" , "333", "4444"],
    'lambda in init is evaluated in scalar context');
is(
    Array->init(5, sub($idx) { $idx == 2 ? undef : $idx }),
    [0,1],
    'init aborts on undef');
is(
    Array->range(1,10)->indexed,
    Array->init(10, sub($idx) { [$idx+1, $idx] }),
    'range->indexed vs. init');
is(
    (reduce { $a->append($b) } map { array($_) } 1 .. 10),
    $range,
    'append a list of wrapped values');
is(
    Array->concat(map { array($_) } 1 .. 10),
    $range,
    'concat');
is(
    Array->concat, Array->empty,
    'concat on zero is empty');
is(
    array(Array->range(1,10)->expand),
    [1 .. 10],
    'expand');
is(
    array(1..5)->append(array(6..10)),
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
        array(),
        Array->range(10,12),
        sq([]),
        Array->new("Hello"),
        Array->empty,
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
is($range->skip(100), []     , 'skip(100)');

is($range->skip(3)->take(3),  [4,5,6], 'skip->take 1');
is($range->skip(3)->take(10), [4..10], 'skip->take 2');
is($range->skip(10)->take(1), [],      'skip->take 3');

is($range->take(0),   [],      'take(0)');
is($range->take(100), [1..10], 'take(100)');

is($range->take(5)->skip(2),  [3,4,5], 'take->skip 1');
is($range->take(5)->skip(4),  [5],     'take->skip 2');
is($range->take(5)->skip(6),  [],      'take->skip 2');

{
    my $data1 = array(
        array(1,1),
        array(2,3,5,8,13),
    );

    # test both calling styles
    is(
        Array::flatten($data1),
        $data1->flatten,
        'flatten');

    ## Implementing bind with map->flatten
    my $bind = sub($s, $f) {
        return $s->map($f)->flatten;
    };

    # check if bind is same as map->flatten
    is(
        $data1->bind(\&id),
        $bind->($data1, \&id),
        'bind implemented with map and flatten');
}

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
    'join 1');
is(
    Array->new(qw/H e l l o W o r l d !/)->join,
    "HelloWorld!",
    'join 2');
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
    Array->new(qw/Hello World Awesome World/)->count_by(Str->length),
    {
        5 => 3,
        7 => 1,
    },
    'count_by');

is(
    Array->new(qw/Hello World Awesome World/)
    ->map(sub($x) { length $x })
    ->count,

    Array->new(qw/Hello World Awesome World/)->count_by(Str->length),
    'map->count same as count_by');

is(Array->new(1,1,2,3,1,4,5,4,3,2,6)->distinct, [1..6],              'distinct 1');
is(Array->new(1,2,3,2,23,123,4,12,2)->distinct, [1,2,3,23,123,4,12], 'distinct 2');
is(Array::distinct([1,2,3,2,23,123,4,12,2]),    [1,2,3,23,123,4,12], 'distinct 3');

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
    is($data->distinct_by(key 'id')->length, 3, 'one element less');
    is(
        $data->distinct_by(key 'id'),
        [
            {id => 1, name => "Foo"},
            {id => 2, name => "Bar"},
            {id => 3, name => "Baz"},
        ],
        'check elements and order');
}

is(
    Array->new(qw/A B C D E F/)->mapi(\&array),
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

is(Array->init(0, \&id),      [], 'init with length 0');
is(Array->range_step(1,1,1), [1], 'range_step with 1,1,1');

# TODO: floating point inaccuraccy
# is(
#     Array->range_step(0,0.1,1),
#     [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1],
#     'range_step with 0,0.1,1');

dies { Array->range_step(0,0,1) }
qr/^\$step is 0/,
'range_step dies with step size of zero';

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
    # turns every single element into an array - than flattens it again
    $range->bind(\&array),
    [1 .. 10],
    'bind - somehow like id');

is(
    array(
        array(1,1),
        [2,3],
        array(5,8,13),
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
is(Array->empty->first(0),          0, 'first with default passed');
is($range->first,             Some(1), 'first on non empty');
is($range->first->or(0),            1, 'first on non empty and option::or');

is(Array->empty->last,           None, 'last on empty');
is(Array->empty->last->or(0),       0, 'last on empty with or');
is(Array->empty->last(0),           0, 'last on empty and provided a default');
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
        $data
        ->map (sub($x)    { [$x->{id} ,  $x     ] })
        ->sort(sub($x,$y) {  $x->[0] <=> $y->[0]  })
        ->map (sub($x)    {  $x->[1]              }),

        $data->sort_by(by_num, key 'id'),
        'sort_by 3');
}

my $fs = Array->new([1,"Hi"],[2,"Foo"],[3,"Bar"],[4,"Mug"]);
is($fs->fsts, [1,2,3,4],            'fsts');
is($fs->snds, [qw/Hi Foo Bar Mug/], 'snds');

is(
    array([1,2,3], [4,5,6], [7,8,9])->flatten,
    [1..9],
    'flatten');

is(
    Array::zip(
        Array->range(1,6),
        array(qw(A B C D E F))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/],[qw/5 E/],[qw/6 F/]],
    'zip 1');

is(
    Array::zip(
        Array->range(1,3),
        array(qw(A B C D E F))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/]],
    'zip 2');

is(
    Array::zip(
        Array->range(1,6),
        array(qw(A B C D))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/]],
    'zip 3');

is(
    Array::zip(
        Array->empty,
        array(qw(A B C D E F))
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

{
    my $data = sq([
        [1,2,3],
        [4,5,6],
        [7,8,9],
    ]);
    my $aoa = $data->to_array_of_array;
    is(refaddr($data), refaddr($aoa), 'to_array_of_array is noop');
}

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

is(Array->new(5)    ->repeat(0) , [],            'repeat 1');
is(Array->new(5)    ->repeat(1) , [5],           'repeat 2');
is(Array->new(5)    ->repeat(5) , [5,5,5,5,5],   'repeat 3');
is(Array->new(1,2,3)->repeat(2) , [1,2,3,1,2,3], 'repeat 4');
is(Array->new(1,2,3)->repeat(3) , [(1,2,3) x 3], 'repeat 5');

is(Array->replicate(10, 'A'), [('A') x 10], 'replicate');
is(
    Some(10, 'A')->map(Array->replicate),
    Some([ "A", "A", "A", "A", "A", "A", "A", "A", "A", "A" ]),
    'replicate is static');

is(
    Array::zip(
        Array->replicate(10, 1),
        array(qw/A B C D E F/),
    ),
    [ [1,'A'],[1,'B'],[1,'C'],[1,'D'],[1,'E'],[1,'F'] ],
    'replicate with zip');

is(
    Array::zip(
        array(1,2)->repeat(9),
        array(qw/A B C D E F/),
    ),
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],[2,'F'] ],
    'repeat with zip 1');

is(
    Array::zip(
        array(1,2)->repeat(2),
        array(qw/A B C D E F/),
    ),
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'] ],
    'repeat with zip 2');

is(
    Array::zip(
        array(1,2)->repeat(20),
        array(qw/A B C D E/)->repeat(20),
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

# iter_sort
{
    my $data = sq [10,5,3,6,2,8,4,3,23];
    my @sorted;
    $data->iter_sort(by_num, sub($x) {
        push @sorted,$x;
    });
    is(
        \@sorted,
        [2, 3, 3, 4, 5, 6, 8, 10, 23],
        'iter_sort');
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
        $words->map(call join => '+'),
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
    is($range->slice(-1, -2, -3),    [],            'slice with negative index is not supported');
    is($range->slice(20,30),         [],            'slice with out of bound 1');
    is($range->slice(1,20,2,-20,3),  [1,2,3],       'slice with out of bound 2');
    is($range->slice(10,-11),        [10],          'slice exact bounds 1');
    is($range->slice(-11,10),        [10],          'slice exact bounds 2');
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
        Array::diff(
            [
                entry(1, "hello"),
                entry(2, "world"),
                entry(3, "test"),
            ],
            [
                entry(2, "abba"),
                entry(3, "test"),
                entry(5, "what"),
            ],
            key 'id'
        ),
        [entry(1, "hello")],
        'diff 3');

    is(
        Array::diff(
            [
                entry(1, "hello"),
                entry(2, "world"),
                entry(3, "test"),
            ],
            [
                entry(2, "abba"),
                entry(3, "test"),
                entry(5, "what"),
            ],
            key 'name'
        ),
        [entry(1, "hello"), entry(2, "world")],
        'diff 4');

    is(
        Array::diff(
            [
                entry(2, "world"),
                entry(1, "hello"),
                entry(3, "test"),
                entry(4, "new"),
            ],
            [
                entry(3, "test"),
                entry(5, "what"),
                entry(2, "world"),
            ],
            key 'id'
        ),
        [entry(1, "hello"), entry(4, "new")],
        'diff 5');

    is(
        Array::diff(
            [
                entry(4, "new"),
                entry(3, "test"),
                entry(2, "world"),
                entry(1, "hello"),
            ],
            [
                entry(3, "test"),
                entry(5, "what"),
                entry(2, "world"),
            ],
            key 'id'
        ),
        [entry(4, "new"), entry(1, "hello")],
        'diff 6');

    is(
        Array::diff(
            [
                entry(2, "world"),
                entry(1, "hello"),
                entry(3, "test"),
                entry(4, "new"),
            ],
            [
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
# I don't see a direct way to test if something is shuffled. Not even testing
# if they are not the same wouldn't work. Theoretically it could shuffle and
# in the end is the same as the input. This is extremely rare, but can happen. But instead
# i can test other properties like that counting the elements is the same because
# the result don't depent on the order of the elements in the array.
# The array must be a new one. Sorting the original and the shuffled
# still must be the same.
{
    my $data    = sq [1,2,3, 1,2,3, 4,5, 6,6,6, 7,8];
    my $shuffle = $data->shuffle;

    ok(refaddr($data) != refaddr($shuffle),     'different arrays');
    is($data, [1,2,3, 1,2,3, 4,5, 6,6,6, 7,8],  "original didn't shuffle");
    is($data->count, {
        1 => 2, 2 => 2, 3 => 2, 4 => 1, 5 => 1, 6 => 3, 7 => 1, 8 => 1,
    }, 'count must be the same on any shuffled array');
    is($data->count,        $shuffle->count,        'count must be the same');
    is($data->sort(by_num), $shuffle->sort(by_num), 'both arrays sorted must be the same');
}

is(
    Array::fill2d([
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
    'fill2d 1');

is(
    Array::fill2d([
        [1,2,3],
        [4,5,6,7],
        [1,2],
        [1],
    ], sub($x,$y) { ($y*10) + $x }),
    [
        [1, 2, 3, 3],
        [4, 5, 6, 7],
        [1, 2,22,23],
        [1,31,32,33],
    ],
    'fill2d 2');

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

# init2d
{
    is(
        Array->init2d(4, 4, sub { 0 }),
        [
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
            [0,0,0,0],
        ],
        'init2d 1');

    is(
        Array->init2d(4, 4, sub($x,$y) { "$y,$x" }),
        [
            ["0,0", "0,1", "0,2", "0,3"],
            ["1,0", "1,1", "1,2", "1,3"],
            ["2,0", "2,1", "2,2", "2,3"],
            ["3,0", "3,1", "3,2", "3,3"],
        ],
        'init2d 2');

    is(
        Array->init2d(4, 4, sub($x,$y) { [$y,$x] }),
        [
            [[0,0], [0,1], [0,2], [0,3]],
            [[1,0], [1,1], [1,2], [1,3]],
            [[2,0], [2,1], [2,2], [2,3]],
            [[3,0], [3,1], [3,2], [3,3]],
        ],
        'init2d 3');

    is(
        Array
        ->init2d(4, 4, sub($x,$y) { [$y,$x] })
        ->map(call 'map', call 'sum'),
        [
            [0, 1, 2, 3],
            [1, 2, 3, 4],
            [2, 3, 4, 5],
            [3, 4, 5, 6],
        ],
        'init2d 4');

    # same as "init2d 4" but expanded the "call" functions
    is(
        Array
        ->init2d(4, 4, sub($x,$y) { [$y,$x] })
        ->map(sub($array) { $array->map(sub($tuple) { Array::sum($tuple) }) }),
        [
            [0, 1, 2, 3],
            [1, 2, 3, 4],
            [2, 3, 4, 5],
            [3, 4, 5, 6],
        ],
        'init2d 5');



    my @iter;
    Array
    ->init2d(4, 4, sub($x,$y) { [$y,$x] })
    ->map(call 'map', call 'sum')
    ->iter2d(sub($value,$x,$y) {
        push @iter, "$x,$y,$value";
    });
    is(
        \@iter,
        [
            "0,0,0", "1,0,1", "2,0,2", "3,0,3",
            "0,1,1", "1,1,2", "2,1,3", "3,1,4",
            "0,2,2", "1,2,3", "2,2,4", "3,2,5",
            "0,3,3", "1,3,4", "2,3,5", "3,3,6",
        ],
        'iter2d');
}

# transpose
is(
    Array->init2d(4,4, sub($x,$y) { [$x,$y] })->transpose,
    Array->init2d(4,4, sub($x,$y) { [$y,$x] }),
    'transpose 1');

is(
    sq([
        [1,2,3,4],
        [1,2],
        [1,2,3,4,5,6],
        [1,2,3,4],
    ])->transpose,
    sq([
        [1,1,1,1],
        [2,2,2,2],
        [3,3,3],
        [4,4,4],
        [5],
        [6],
    ]),
    'transpose 2');

is(
    Array::transpose_map([
        [qw/foo bar/],
        [qw/length what hoop/],
        [qw/one/],
        [qw/a b c/],
    ], sub ($str,$x,$y) { length $str }),
    [
        [3,6,3,1],
        [3,4,1],
        [4,1]
    ],
    'transpose_map 1');

is(
    Array::transpose_map([
        [qw/foo bar/],
        [qw/length what hoop/],
        [qw/one/],
        [qw/a b c/],
    ], sub ($str,$x,$y) { [$x,$y,$str] }),
    [
        [ [0,0,  "foo"], [0,1, "length"], [0,2, "one"], [0,3, "a"] ],
        [ [1,0,  "bar"], [1,1,   "what"], [1,3,   "b"] ],
        [ [2,1, "hoop"], [2,3,      "c"] ],
    ],
    'transpose_map 2');

# average
is(Array::average([1 .. 10]), 5.5, 'average 1');
is(array(1 .. 10)->average,   5.5, 'average 2');
is(
    Array->init(10, sub($idx) {
        { id => $idx+1, num => $idx+1 }
    })->average_by(key 'num'),
    5.5,
    'average_by 1');
is(
    Array->init(10, sub($idx) {
        { id => $idx,   num => $idx+1 }
    })->average_by(key 'num'),

    Array->init(10, sub($idx) {
        { id => $idx+1, num => $idx+1 }
    })->map(key 'num')->average,

    'average_by 2');

# cache
{
    my $data  = Array->init(10, \&id);
    my $cache = $data->cache;
    is(refaddr($data), refaddr($cache), 'same references');
}

# map2
{
    my $words = sq [qw(foo bar baz)];
    my $ones  = sq [1,1,1];

    # method
    is(
        $words->map2($ones, \&array),
        [ ["foo",1], ["bar",1], ["baz",1] ],
        'map2 - method');

    # functional
    is(
        Array::map2($words, $ones, \&array),
        [ ["foo",1], ["bar",1], ["baz",1] ],
        'map2 - functional');
    is(
        Array::map2($words, $ones, \&array)->merge->as_hash,
        { "foo" => 1, "bar" => 1, "baz" => 1 },
        'map2 - merge->as_hash');
    is(
        Array::map2($words, $ones, sub($word,$one) { $one, $word }),
        [ "foo", "bar", "baz"],
        'map2 - behaviour when lambda returns multiple things');
    is(
        Array::map2([qw/foo bar baz maz hatz/], [1,2,3], \&array),
        [
            ["foo",  1],
            ["bar",  2],
            ["baz",  3],
            ["maz",  3],
            ["hatz", 3],
        ],
        'map2 - array with different lengths');
    is(
        Array::map3([qw/foo bar/], [1,2,3,4], [10], \&array),
        [
            ["foo", 1, 10],
            ["bar", 2, 10],
            ["bar", 3, 10],
            ["bar", 4, 10],
        ],
        'map3 with different lengths');
    is(
        Array::map4(
            [1,2,3,4],
            [1,2],
            [1],
            [1,2,3],
            sub($x,$y,$z,$w) { $x + $y + $z + $w }
        ),
        [4,7,9,10],
        'map4');
}

# itern
{
    my $data = array(map { $_ => "foo" } 0 .. 9);
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

    my $hash = {};
    Array::itern([1,"a",2,"b",3], 2, sub($k,$v) {
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
    Array::itern([1,2,3,4,5,6,7], 3, sub($x,$y,$z) { $sum->push($x+$y+$z) });
    is($sum, [6,15], 'only loops over multiple of 3');
}

# scan
{
    my $account = {
        name  => "Lilly",
        saldo => 10_000,
    };

    my sub in ($amount) { {in  => $amount } }
    my sub out($amount) { {out => $amount } }

    my sub apply_change($account, $entry) {
        if ( defined $entry->{in} ) {
            my $new = Hash::withf($account,
                saldo => sub($saldo) { $saldo + $entry->{in} }
            );
            $new->{change} = '+' . $entry->{in};
            return $new;
        }
        elsif ( defined $entry->{out} ) {
            my $new = Hash::withf($account,
                saldo => sub($saldo) { $saldo - $entry->{out} }
            );
            $new->{change} = '-' . $entry->{out};
            return $new;
        }
        Carp::croak (sprintf "Not In/Out: %s", dumps($entry));
    }

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

# intersect
{
    my $data1 = sq [[qw/foo .mp4/], [qw/bar .mp4/], [qw/baz .mp4/]];
    my $data2 = sq [[qw/foo .m4v/],                 [qw/baz .m4v/]];

    is(
        Array::intersect($data1, $data2, \&fst),
        [[qw/foo .mp4/], [qw/baz .mp4/]],
        'intersect 1');

    is(
        Array::intersect($data2, $data1, \&fst),
        [[qw/foo .m4v/], [qw/baz .m4v/]],
        'intersect 2');
}

# TODO: Add a map_any?
# map2d
{
    my $aoa = sq [
        [qw/foo bar hazelnut/],
        [qw/Lilly Anny/],
        [qw/Batman Spider-Man/],
        [qw/Ricewind Two-Flowers/],
    ];

    is(
        Array::map2d($aoa, sub($str,$x,$y) { length $str }),
        [
            [3,3,8],
            [5,4],
            [6,10],
            [8,11],
        ],
        'map2d 1');

    is(
        Array::map2d($aoa, sub($str,$x,$y) { [$x,$y] }),
        [
            [ [0,0], [1,0], [2,0] ],
            [ [0,1], [1,1]        ],
            [ [0,2], [1,2]        ],
            [ [0,3], [1,3]        ],
        ],
        'map2d 2');
}

# columns
{
    is(
        Array->range(1,10)->columns(1),
        [
            [1],
            [2],
            [3],
            [4],
            [5],
            [6],
            [7],
            [8],
            [9],
            [10],
        ],
        'columns 1');

    is(
        Array->range(1,10)->columns(2),
        [
            [1,6],
            [2,7],
            [3,8],
            [4,9],
            [5,10],
        ],
        'columns 2');

    is(
        Array->range(1,10)->columns(3),
        [
            [1,5, 9],
            [2,6,10],
            [3,7   ],
            [4,8   ],
        ],
        'columns 3');

    is(
        Array->range(1,10)->columns(4),
        [
            [1,4,7,10],
            [2,5,8   ],
            [3,6,9   ],
        ],
        'columns 4');

    is(Array::columns([1], 1), [[1]], 'columns 5');
    is(Array::columns([], 1),     [], 'columns 6');

    is(
        Array->range(1,4)->columns(4),
        [
            [1,2,3,4],
        ],
        'columns 7');

    is(
        Array->range(1,10)->columns(10),
        [
            [1,2,3,4,5,6,7,8,9,10],
        ],
        'columns 8');

    # TODO: Correct or not?
    is(
        Array->range(1,11)->columns(10),
        [
            [ 1, 3, 5, 7,  9, 11 ],
            [ 2, 4, 6, 8, 10     ]
        ],
        'columns 9');

    is(
        Array->range(1,5)->columns(10),
        [
            [1,2,3,4,5],
        ],
        'columns 10');

    is(
        Array->range(1,50)->columns(10),
        [
            [ 1,  6, 11, 16, 21, 26, 31, 36, 41, 46 ],
            [ 2,  7, 12, 17, 22, 27, 32, 37, 42, 47 ],
            [ 3,  8, 13, 18, 23, 28, 33, 38, 43, 48 ],
            [ 4,  9, 14, 19, 24, 29, 34, 39, 44, 49 ],
            [ 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 ]
        ],
        'columns 11');
}

# contains
{
    my $data = sq [
        { name => 'Lilly' },
        { X => 1, Y => 2  },
        'Some Text',
        "Foo: x",
        123,
        [1,2,3],
    ];

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
     ok($data->contains(1,2,[1,2,3]),                'contains with many');
}

{
    # Let's say i want to repeatedly call this code,
    #
    #    Array->range(1,11)->columns(10),
    #
    # but with different values for range() and columns(). I could create
    # an array of array just for the values. For example.
    #
    #    my @args = (
    #        [1,10,10],
    #        [2,20,20],
    #    );
    #
    # and use that to call the above code.
    #
    #    for my $args ( @args ) {
    #        my ($start,$stop,$col) = @$args;
    #        Array->range($start,$stop)->columns($col);
    #    }
    #
    # then for every call there is one such line. Another approach would be
    # to have one array just for the @starts, another for @stops and another for
    # @columns. Then iterate with an index above all three and always pick
    # the one from every array with the same index. But this is what map2, map3,
    # map_v does.
    my $cols = Array::map3(
        [1  .. 10],
        [11 .. 20],
        [1  .. 10],
        sub($start,$stop,$col) {
            Array->range($start, $stop)->columns($col);
        });

    is($cols,[
        [[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11]],
        [[2,8],[3,9],[4,10],[5,11],[6,12],[7]],
        [[3,7,11], [4,8,12],[5,9,13],[6,10]],
        [[4,7,10,13], [5,8,11,14], [6,9,12]],
        [[5,8,11,14], [6,9,12,15], [7,10,13]],
        [[6,8,10,12,14,16],  [7,9,11,13,15]],
        [[7,9,11,13,15,17],  [8,10,12,14,16]],
        [[8,10,12,14,16,18], [9,11,13,15,17]],
        [[9,11,13,15,17,19], [10,12,14,16,18]],
        [[10,12,14,16,18,20],[11,13,15,17,19]]
    ], 'map3');
}

is(
    Array::map([1..15], sub($col) {
        Array->range(1,10)->columns($col)
    }),
    [
        [[1],[2],[3],[4],[5],[6],[7],[8],[9],[10]], # 1
        [[1,6],[2,7],[3,8],[4,9],[5,10]],           # 2
        [[1,5,9],[2,6,10],[3,7],[4,8]],             # 3
        [[1,4,7,10],[2,5,8],[3,6,9]],               # 4
        [[1,3,5,7,9],[2,4,6,8,10]],                 # 5
        [[1,3,5,7,9],[2,4,6,8,10]],                 # 6
        [[1,3,5,7,9],[2,4,6,8,10]],                 # 7
        [[1,3,5,7,9],[2,4,6,8,10]],                 # 8
        [[1,3,5,7,9],[2,4,6,8,10]],                 # 9
        [[1,2,3,4,5,6,7,8,9,10]],                   # 10
        [[1,2,3,4,5,6,7,8,9,10]],                   # 11
        [[1,2,3,4,5,6,7,8,9,10]],                   # 12
        [[1,2,3,4,5,6,7,8,9,10]],                   # 13
        [[1,2,3,4,5,6,7,8,9,10]],                   # 14
        [[1,2,3,4,5,6,7,8,9,10]],                   # 15
    ],
    'columns 1..15');

is(
    Array::map([1..20], sub($stop) {
        Array->range(1,$stop)->columns(10)
    }),
    [
        [[1]],
        [[1,2]],
        [[1,2,3]],
        [[1,2,3,4]],
        [[1,2,3,4,5]],
        [[1,2,3,4,5,6]],
        [[1,2,3,4,5,6,7]],
        [[1,2,3,4,5,6,7,8]],
        [[1,2,3,4,5,6,7,8,9]],
        [[1,2,3,4,5,6,7,8,9,10]],
        [[1,3,5,7,9,11],[2,4,6,8,10]], # ok?
        [[1,3,5,7,9,11],[2,4,6,8,10,12]], # ok?
        [[1,3,5,7,9,11,13], [2,4,6,8,10,12]], # ok?
        [[1,3,5,7,9,11,13], [2,4,6,8,10,12,14]], # ok?
        [[1,3,5,7,9,11,13,15], [2,4,6,8,10,12,14]], # ok?
        [[1,3,5,7,9,11,13,15], [2,4,6,8,10,12,14,16]], # ok?
        [[1,3,5,7,9,11,13,15,17], [2,4,6,8,10,12,14,16]], # ok?
        [[1,3,5,7,9,11,13,15,17], [2,4,6,8,10,12,14,16,18]], # ok?
        [[1,3,5,7,9,11,13,15,17,19], [2,4,6,8,10,12,14,16,18]],
        [[1,3,5,7,9,11,13,15,17,19], [2,4,6,8,10,12,14,16,18,20]],
    ],
    'columns 1..15');

# static checks
{
    is(
        Array::map2([1,5,8],[\&id],Array->init),
        [
            [ 0 ],
            [ 0, 1, 2, 3, 4 ],
            [ 0, 1, 2, 3, 4, 5, 6, 7 ]
        ],
        'check static init');
    is(
        Array::map3([1,5,8],[1,3,6],[\&array],Array->init2d),
        [
            # 1,1
            [
                [[0,0]]
            ],

            # 5,3
            [
                [[0,0],[1,0],[2,0],[3,0],[4,0]],
                [[0,1],[1,1],[2,1],[3,1],[4,1]],
                [[0,2],[1,2],[2,2],[3,2],[4,2]],
            ],

            # 8,6
            [
                [[0,0],[1,0],[2,0],[3,0],[4,0],[5,0],[6,0],[7,0]],
                [[0,1],[1,1],[2,1],[3,1],[4,1],[5,1],[6,1],[7,1]],
                [[0,2],[1,2],[2,2],[3,2],[4,2],[5,2],[6,2],[7,2]],
                [[0,3],[1,3],[2,3],[3,3],[4,3],[5,3],[6,3],[7,3]],
                [[0,4],[1,4],[2,4],[3,4],[4,4],[5,4],[6,4],[7,4]],
                [[0,5],[1,5],[2,5],[3,5],[4,5],[5,5],[6,5],[7,5]],
            ],
        ],
        'check static init2d');
}

is(sq([1,2,3])->fill(1,  sub { 0 }), [1,2,3],               'fill 1');
is(sq([1,2,3])->fill(3,  sub { 0 }), [1,2,3],               'fill 2');
is(sq([1,2,3])->fill(4,  sub { 0 }), [1,2,3,0],             'fill 3');
is(sq([1,2,3])->fill(10, sub { 0 }), [1,2,3,0,0,0,0,0,0,0], 'fill 4');
is(sq([1,2,3])->fill(10, \&id),      [1,2,3,3,4,5,6,7,8,9], 'fill 5');
is(Array->empty->fill(100, \&id), Array->init(100, \&id),   'fill 6');

# chunked_size
#
# like chunked, chunked_size creates an array of array. But instead of creating a
# fixed amount of elements it pushes items into chunks as long a maximum size
# is not reached. You provide a function for every element to determine it's
# size.
{
    my $str = "The quick brown fox jumps over the lazy dog. " x 5;
    my $cs  = array(split /\s+/, $str)->chunked_size(100, sub($word) { length $word });
    is (
        $cs,
        [
            [
                "The", "quick", "brown", "fox", "jumps", "over", "the", "lazy",
                "dog.", "The", "quick", "brown", "fox", "jumps", "over", "the",
                "lazy", "dog.", "The", "quick", "brown", "fox", "jumps", "over", "the"
            ],
            [
                "lazy", "dog.", "The", "quick", "brown", "fox", "jumps",
                "over", "the", "lazy", "dog.", "The", "quick", "brown", "fox",
                "jumps", "over", "the", "lazy", "dog."
            ]
        ],
        'chunked_size');
    is(
        $cs->map(call 'sum_by', Str->length),
        [100, 80],
        'chunked_size str length added');
    is(
        array(split /\s+/, "The quick brown fox jumps over the lazy dog.")->chunked_size(1, Str->length),
        [['The'], ['quick'], ['brown'], ['fox'], ['jumps'], ['over'], ['the'], ['lazy'], ['dog.']],
        'chunked_size 2');
    is(
        array(1..50)->chunked_size(100, \&id),
        [
            [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 ],
            [ 14, 15, 16, 17, 18, 19 ],
            [ 20, 21, 22, 23 ],
            [ 24, 25, 26 ],
            [ 27, 28, 29 ],
            [ 30, 31, 32 ],
            [ 33, 34 ],
            [ 35, 36 ],
            [ 37, 38 ],
            [ 39, 40 ],
            [ 41, 42 ],
            [ 43, 44 ],
            [ 45, 46 ],
            [ 47, 48 ],
            [ 49, 50 ]
        ],
        'chunked_size 3');

    check(
        array(1..50)->chunked_size(100, \&id)->map(call 'sum'),
        sub($array) { $array->all(sub($x) { $x <= 100 }) },
        'chunked_size 4');

    # same as the above
    check(
        array(1..50)->chunked_size(100, \&id)->map(call 'sum'),
        call(all => sub($x) { $x <= 100 }),
        'chunked_size 4');

    # Easily generate 20 tests -- but also could be just one
    for ( 1 .. 20 ) {
        # Generates array with 100 random strings with 3-10 characters
        my $words = gen_run gen [repeat => 100, [str => 3, 10]];
        check(
            $words->chunked_size(100, \&CORE::length),
            call(all => sub($array) { $array->sum_by(Str->length) <= 100 }),
            'all chunks <= 100');
    }
}

is(
    array("foo", 2, "baz", 3, "tidy", 4)->mapn(2, sub($str,$num) { $str x $num }),
    ["foofoo", "bazbazbaz", "tidytidytidytidy"],
    'mapn 1');

is(
    array(1, "Anny", 100, 2, "Frank", 12, 3, "Peter", 33)->mapn(3, sub($id,$name,$points) {
        hash(id => $id, name => $name, points => $points);
    }),
    [
        {id => 1, name => "Anny",  points => 100},
        {id => 2, name => "Frank", points => 12 },
        {id => 3, name => "Peter", points => 33 },
    ],
    'mapn 2');

is(
    array(1, "Anny", 100, 2, "Frank", 12, 3, "Peter", 33)->mapn(3, record(qw/id name points/)),
    [
        {id => 1, name => "Anny",  points => 100},
        {id => 2, name => "Frank", points => 12 },
        {id => 3, name => "Peter", points => 33 },
    ],
    'mapn 3');

is(
    array(1, "Anny", 100, 2, "Frank", 12, 3, "Peter", 33, "Cherry")->mapn(3, record(qw/id name points/)),
    [
        {id => 1, name => "Anny",  points => 100},
        {id => 2, name => "Frank", points => 12 },
        {id => 3, name => "Peter", points => 33 },
    ],
    'mapn 4 - mapn(3) on not multiple of three just cuts off');

is(Array::permute([]),    [],      'permute 0');
is(Array::permute(['A']), [['A']], 'permute 1');
is(
    Array::permute([qw/A B/]),
    [
        [qw/A B/],
        [qw/B A/]
    ],
    'permute 2');
is(
    Array::permute([qw/A B C/]),
    [
        [qw/A B C/],
        [qw/A C B/],
        [qw/B A C/],
        [qw/B C A/],
        [qw/C A B/],
        [qw/C B A/],
    ],
    'permute 3');
is(
    Array::permute([qw/A B C D/]),
    [
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
    ],
    'permute 4');

is(
    array(qw/A B/  )->permute->bind(sub($fst) {
    array(qw/C G A/)->permute->bind(sub($snd) {
    array(qw/T K/  )->permute->bind(sub($third) {
        array(Array->concat($fst, $snd, $third))
    })})}),
    [
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
    ],
    'permute 5');

# same as permute 5, just written differently
is(
    Array::cartesian(
        array(qw/A B/  )->permute,
        array(qw/C G A/)->permute,
        array(qw/T K/  )->permute,
    )->map(call 'flatten'),
    [
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
    ],
    'permute 6');

is(
    Array::cartesian(
        array(qw/A B/  )->permute,
        array(qw/C G A/)->permute,
        array(qw/T K/  )->permute,
    ),
    [
        [["A","B"], ["C","G","A"], ["T","K"]],
        [["A","B"], ["C","G","A"], ["K","T"]],
        [["A","B"], ["C","A","G"], ["T","K"]],
        [["A","B"], ["C","A","G"], ["K","T"]],
        [["A","B"], ["G","C","A"], ["T","K"]],
        [["A","B"], ["G","C","A"], ["K","T"]],
        [["A","B"], ["G","A","C"], ["T","K"]],
        [["A","B"], ["G","A","C"], ["K","T"]],
        [["A","B"], ["A","C","G"], ["T","K"]],
        [["A","B"], ["A","C","G"], ["K","T"]],
        [["A","B"], ["A","G","C"], ["T","K"]],
        [["A","B"], ["A","G","C"], ["K","T"]],
        [["B","A"], ["C","G","A"], ["T","K"]],
        [["B","A"], ["C","G","A"], ["K","T"]],
        [["B","A"], ["C","A","G"], ["T","K"]],
        [["B","A"], ["C","A","G"], ["K","T"]],
        [["B","A"], ["G","C","A"], ["T","K"]],
        [["B","A"], ["G","C","A"], ["K","T"]],
        [["B","A"], ["G","A","C"], ["T","K"]],
        [["B","A"], ["G","A","C"], ["K","T"]],
        [["B","A"], ["A","C","G"], ["T","K"]],
        [["B","A"], ["A","C","G"], ["K","T"]],
        [["B","A"], ["A","G","C"], ["T","K"]],
        [["B","A"], ["A","G","C"], ["K","T"]],
    ],
    'permute 7');

is(
    Array::cartesian([1,2,3], [qw/A B C/], [qw/foo bar/], [0,1]),
    [
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
    ],
    'cartesian on many arrays');

{
    my $digit = [0 .. 9, 'a' .. 'f'];
    my $hex   = Array::cartesian($digit, $digit)->map(call 'join');
    is(
        $hex,
        [
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
        ],
        'hex count up');

    is($hex->index(-1),        None, "index 0");
    is($hex->index(0),   Some("00"), "index 1");
    is($hex->index(1),   Some("01"), "index 2");
    is($hex->index(15),  Some("0f"), "index 3");
    is($hex->index(16),  Some("10"), "index 4");
    is($hex->index(255), Some("ff"), "index 5");
    is($hex->index(256),       None, "index 6");

    is($hex->index(-1, "00"),   "00", "index 7");
    is($hex->index(256,"00"),   "00", "index 8");
}

is(
    array(1,2,3,4)->fold_rec(sub{0}, sub($x,$state) { $state + $x }),
    10,
    'fold_rec 1');
is(
    sq([
        [1,2,3,4], # 10 * 2 -> 20 * 2 ->  40
        [5,6,7,8], # 26 * 2 -> 52 * 2 -> 104
    ])->fold_rec(sub{0}, sub($x,$state) { $state + ($x*2) }),
    144,
    'fold_rec 2');
is(
    sq([
        ["foo", "bar", "baz"],
        ["whatever", "lena"],
    ])->fold_rec(sub{""}, sub($x,$state) { $state eq "" ? $x : "$state $x" }),
    "foo bar baz whatever lena",
    'fold_rec 3');

is(
    sq([
        [1,2,[3,4]],
        [5,[6],7,[8, [9,10,11]]],
    ])->map_rec(sub($x) { $x * 2 }),
    [
        [2,4,[6,8]],
        [10,[12],14,[16,[18,20,22]]],
    ],
    'map_rec 1');


is(
    sq([
        [1,2,3,4], # 10 * 2 -> 20
        [5,6,7,8], # 26 * 2 -> 52
    ])->map_array(sub($x) { $x * 2 }, sub($array) { $array->sum }),
    72,
    'map_array 1');
is(
    sq([
        ["foo", "bar", "baz"],
        ["whatever", "lena"],
    ])->map_array(\&id, call join => " "),
    "foo bar baz whatever lena",
    'map_array 2');
{
    my $got = sq [
        "body",
        [a => {href => "www.heise.de"}, "Click Me!"],
        [a => {href => "www.cool.de"},  "No Me!"],
    ];
    my $expected = [
        "body",
        {},
        [a => {href => "www.heise.de"}, "Click Me!"],
        [a => {href => "www.cool.de"},  "No Me!"],
    ];
    is(
        $got->map_array(\&id, sub($tag) {
            if ( is_type(type [tuplev => ['str'],['hash'],['array']], $tag) ) {
                return $tag;
            }
            return [$tag->[0], {}, $tag->@[1..$tag->$#*]];
        }),
        $expected,
        'map_array 3');
}
{
    my $got = sq [
        "body",
        [a => {href => "www.heise.de"}, "Click Me!"],
        [a => {href => "www.cool.de"},  "No Me!"],
    ];
    my $expected = [
        "body",
        {},
        [a => {href => "www.heise.de"}, "Click Me!"],
        [a => {href => "www.cool.de"},  "No Me!"],
    ];
    my $f = type_cond(
        type [tuplev => ['str'],['hash'],['array']] => sub($tag) {
            $tag
        },
        type ['any'] => sub($tag) {
            [$tag->[0], {}, $tag->@[1..$tag->$#*]];
        },
    );
    is(
        $got->map_array(\&id, $f),
        $expected,
        'map_array 4');
}

{
    my $data = array(1,2,3,4,5);
    is($data->head, 1,             'head 1');
    is($data->tail, [2,3,4,5],     'tail 1');
    is($data->tail->head, 2,       'head 2');
    is($data->tail->tail->head, 3, 'head 3');
    is($data, [1,2,3,4,5],         '$data unchanged');
}

is(Array->one(1),      [1], 'one 1');
is(Array->one(1), array(1), 'one 2');
check_isa(Array->one(1), 'Array', 'one 3');

is(array() ->is_empty, 1, 'is_empty 1');
is(array(1)->is_empty, 0, 'is_empty 2');

# to_arrays
is(
    # Got
    Array::to_arrays(seq {
        foo => seq {1,2,3},
        bar => seq {
            file1  => "whatever",
            folder1 => seq {
                file2 => "blub",
                file3 => "Whaaaagh!",
            },
            folder2 => seq {
                folder3 => seq {
                    file4 => "For The Emporer!",
                },
            },
        },
        "test",
        maz => seq {
            Ok (seq{qw/foo bar/}),
            Err(seq{qw/foo bar/}),
        },
        folder4 => [
            seq {4,5,6},
            "foo",
            seq {7,8,9},
        ],
        {
            content1 => seq {6,6,6},
            content2 => [
                seq {1,1,1},
                seq {2,2,2},
                Some([Seq->range(1,3), Seq->range(3,1)]),
            ],
        }
    }),
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
    my $data = Array::map3(
        Array->range(1,10),
        [qw/Anny Lilly Lena Angel Cherry Kristel Candy Cleopatra Sweetie Crista/],
        Sq->rand->int(1,100)->to_array(10),
        record(qw/id name points/),
    );
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
        Some($data),
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

{
    my $data = sq {
        1 => "Anny",
        2 => "Lilly",
        3 => "Zola",
    };

    my $kv = sub($k,$v) { [$k,$v] };
    one_of(
        Array->from_hash($data, $kv),
        array([1,'Anny'], [2,'Lilly'], [3, 'Zola'])->permute,
        'from_hash 1');

    # test if Hash::to_array is the same as Array::from_hash
    one_of(
        $data->to_array($kv),
        array([1,'Anny'], [2,'Lilly'], [3, 'Zola'])->permute,
        'to_array');
}

# keep_some behaviour testing when Some contains multiple values
{
    is(
        Array::keep_some([Some(1,2,3), Some(4,5,6)]),
        [1,2,3,4,5,6],
        'keep_some multi 1');

    is(
        Array::keep_some([Some([1,2,3]), Some([4,5,6])]),
        [[1,2,3],[4,5,6]],
        'keep_some multi 2');

    is(
        Array::keep_some([Some([1,2,3]), Some([4,5,6])])->merge,
        [1,2,3,4,5,6],
        'keep_some multi 3');
}

# combine
{
    my $data = sq [
        {id => 1, name => "Zelda",       tag => "Action-Adventure"},
        {id => 1, name => "Zelda",       tag => "Link"},
        {id => 1, name => "Zelda",       tag => "Ganon"},
        {id => 2, name => "Mario 64",    tag => "Mario"},
        {id => 2, name => "Mario 64",    tag => "Jump N Run"},
        {id => 3, name => "Doom 64",     tag => "Ego-Shooter"},
        {         name => "Turok",       tag => "Ego-Shooter"},
        {id => 4, name => "Blast Corps", tag => "Rare"},
        {id => 4, name => "Blast Corps", tag => "Destruction"},
    ];

    is(
        $data->combine('id', 'tag'),
        {
            1 => {
                id   => 1,
                name => "Zelda",
                tag  => ["Action-Adventure", "Link", "Ganon"],
            },
            2 => {
                id   => 2,
                name => "Mario 64",
                tag  => ["Mario", "Jump N Run"],
            },
            3 => {
                id   => 3,
                name => "Doom 64",
                tag  => ["Ego-Shooter"],
            },
            4 => {
                id   => 4,
                name => "Blast Corps",
                tag  => ["Rare", "Destruction"],
            },
        },
        'combine 1');
}

{
    my $data = sq [
        {id => 1, name => "Zelda",       tag => "Action-Adventure", comment => "A"},
        {id => 1, name => "Zelda",       tag => "Link",             comment => "B"},
        {id => 1, name => "Zelda",       tag => "Ganon",            comment => "C"},
        {id => 2, name => "Mario 64",    tag => "Mario",            comment => "D"},
        {id => 2, name => "Mario 64",    tag => "Jump N Run",       comment => "E"},
        {id => 3, name => "Doom 64",     tag => "Ego-Shooter",      comment => "F"},
        {         name => "Turok",       tag => "Ego-Shooter",      comment => "G"},
        {id => 4, name => "Blast Corps", tag => "Rare",             comment => "H"},
        {id => 4, name => "Blast Corps", tag => "Destruction",      comment => "I"},
    ];

    is(
        $data->combine(id => qw/tag comment/),
        {
            1 => {
                id      => 1,
                name    => "Zelda",
                tag     => ["Action-Adventure", "Link", "Ganon"],
                comment => [qw/A B C/],
            },
            2 => {
                id      => 2,
                name    => "Mario 64",
                tag     => ["Mario", "Jump N Run"],
                comment => [qw/D E/],
            },
            3 => {
                id      => 3,
                name    => "Doom 64",
                tag     => ["Ego-Shooter"],
                comment => ['F'],
            },
            4 => {
                id      => 4,
                name    => "Blast Corps",
                tag     => ["Rare", "Destruction"],
                comment => [qw/H I/],
            },
        },
        'combine 2');
}

done_testing;