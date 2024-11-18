#!perl
use 5.036;
use List::Util qw(reduce);
use Scalar::Util qw(refaddr);
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
# use DDP;

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
    is($a, check_isa('Array'), 'new');
    is($a, [1,2,3],            'new content');

    my $b = Array->bless([1,2,3]);
    is($b, check_isa('Array'), 'bless');
    is($b, [1,2,3],            'bless content');

    like(
        dies { Array->bless(1) },
        qr/\AArray->bless\(\$aref\) must be called with arrayref/,
        'bless without arrayref dies'
    );
}

# Basic checks of range and rangeDesc
is($range, D(),                   'range returns something');
is($range, check_isa('Array'),    'returns an Array');
is($range, [1 .. 10],             'is an array');
is(Array->range(1,1), [1],        'range is inclusive');
is($rangeDesc, [reverse 1 .. 10], 'rangeDesc');
is($range, $rangeDesc->rev,       'reverse of rangeDesc same as range');
is($range->map($double),     [2,4,6,8,10,12,14,16,18,20], 'map');
is($range->filter($is_even), [2,4,6,8,10],                'filter');
is($range->take(5),   [1..5], 'take 1');
is($range->take(0),       [], 'take 2');
is($range->take(-1),      [], 'take 3');
is($range->length,         10, 'length');
is($range->take(5)->length, 5, 'take & length');

is(
    $range->map($square)->filter($is_even),
    [4,16,36,64,100],
    'map filter');
is(
    $range->map($square)->filter($is_even)->take(3),
    [4,16,36],
    'map filter take');

is(
    $range->map($square)->filter_e('$_ % 2 == 0'),
    [4,16,36,64,100],
    'filter_e');

is(
    Array->range(1,3)->map(sub($x) { ($x) x 3 }),
    [1,1,1, 2,2,2, 3,3,3],
    'map can return a list');

is(
    Array->range(1,3)->map_e('($_) x 3'),
    [1,1,1, 2,2,2, 3,3,3],
    'map_e with a list');

is(
    Array->new(qw/Hello World One Two/)->map(sub($str) { $str => length $str }),
    ["Hello", 5, "World", 5, "One", 3, "Two", 3],
    'map with multiple return values');

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

# as_hash
{
    my $h = Array->new(qw/Hello World One Two/)->map(sub($str) { $str => length $str })->as_hash;

    is(
        $h,
        {"Hello" => 5, "World" => 5, "One" => 3, "Two" => 3},
        'map with multiple return values and as_hash');

    is(
        $h,
        check_isa('Hash'),
        'Is a Hash');
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

is($range->rev, check_isa('Array'), 'rev return Array');
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
    is(Array->wrap(1,2,3,undef,4,5,6), [1..3], 'wrap containing an undef');

    is(Array->wrap(5), [5], 'wrap');
    is(
        Array->wrap(5)->append(Array->wrap(10)),
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
        Array->wrap(qw/A B C D E F/),
        Array->range(0, 1_000_000),
    ),
    Array->wrap(qw/A B C D E F/)->indexed,
    'indexed');

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
    (reduce { $a->append($b) } map { Array->wrap($_) } 1 .. 10),
    $range,
    'append a list of wrapped values');
is(
    Array->concat(map { Array->wrap($_) } 1 .. 10),
    $range,
    'concat');

like(
    Array->concat, Array->empty,
    'concat on zero is empty');

is(
    Array->wrap(Array->range(1,10)->expand),
    [1 .. 10],
    'expand');

is(
    Array->wrap(1..5)->append(
        Array->wrap(6..10)
    ),
    Array->concat(
        Array->wrap(1..3),
        Array->wrap(4..6),
        Array->wrap(7..10),
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
        Array->wrap("Hello"),
        Array->empty
    ),
    Array->wrap(1..5, 10..12, "Hello"),
    'concat with empties');
is(
    Array->from_array([1..10]),
    Array->wrap(1..10),
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
    Array->wrap, Array->empty,
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

is(Array->wrap([A => 1], [B => 2], [C => 3])->sum_by(\&snd), 6, 'sumBy');
is(
    Array->wrap(qw/H e l l o W o r l d !/)->join('-'),
    "H-e-l-l-o-W-o-r-l-d-!",
    'join');

is(
    Array->wrap(qw/Hello World you are awesome/)->to_hash(sub($x) { length $x => $x }),
    hash {
        field 5 => "World";
        field 3 => "are";
        field 7 => "awesome";
        end;
    },
    'to_hash 1');

is(
    Array->wrap(qw/Hello World you are awesome/)->to_hash(sub($x) { $x => length $x }),
    hash {
        field "Hello"   => 5;
        field "World"   => 5;
        field "you"     => 3;
        field "are"     => 3;
        field "awesome" => 7;
        end;
    },
    'to_hash 2');

is(
    Array->wrap(qw/Hello World you are awesome/)->to_hash_of_array(sub($x) { length $x => $x }),
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

is(Array->wrap(1,1,2,3,1,4,5,4,3,2,6)->distinct, [1..6],              'distinct 1');
is(Array->wrap(1,2,3,2,23,123,4,12,2)->distinct, [1,2,3,23,123,4,12], 'distinct 2');
is(Array::distinct([1,2,3,2,23,123,4,12,2]),     [1,2,3,23,123,4,12], 'distinct 3');

# distinct_by tests
{
    my $data = Array->wrap(
        {id => 1, name => "Foo"},
        {id => 2, name => "Bar"},
        {id => 3, name => "Baz"},
        {id => 1, name => "Foo"},
    );

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
    Array->wrap(qw/A B C D E F/)->mapi(sub($x,$i) { [$x,$i] }),
    [[A => 0], [B => 1], [C => 2], [D => 3], [E => 4], [F => 5]],
    'mapi');

is(
    Array->wrap(qw/A B C D E F/)->mapi(sub($x,$i) {
        $i < 3 ? [$x,$i] : undef
    }),
    [[A => 0], [B => 1], [C => 2]],
    'mapi with filtering');

is(Array->init( 0,  sub($idx) { $idx }), [], 'init with length 0');
is(Array->init(-1,  sub($idx) { $idx }), [], 'init with length -1');
is(Array->init(-10, sub($idx) { $idx }), [], 'init with length -10');
is(Array->range_step(1,1,1), [1], 'range_step with 1,1,1');
is(
    Array->range_step(0,0.1,1),
    array {
        for (my $f=0.0; $f <= 1.0; $f+=0.1) {
            item float $f;
        }
    },
    'range_step with 0,0.1,1');

like(
    dies { Array->range_step(0,0,1) },
    qr/^\$step is 0/,
    'range_step dies with step size of zero');

is(
    $range->map($square)->filter($is_even),
    $range->map(sub($x) {
        my $s = $x * $x;
        $s % 2 == 0 ? $s : undef
    }),
    'map already can filter');

is(
    $range->map(sub($x) {
        my $s = $x * $x;
        $s % 2 == 0 ? $s : undef
    }),
    [grep { $_ % 2 == 0 } map { $_ * $_ } 1 .. 10],
    'Perl implementation of ->map');

is(
    Array
        ->range(1,5)
        ->map(sub($x) {
            my $square = $x * $x;
            return $square % 2 == 0 ? $square : undef
        }),
    Array
        ->range(1,5)
        ->map(   sub($x) { $x * $x     })
        ->filter(sub($x) { $x % 2 == 0 }),
    'square and even');

is($range->find(sub($x) { $x > 5  }),   Some(6), 'find 1');
is($range->find(sub($x) { $x > 10 }),      None, 'find 2');
is($range->find(sub($x) { $x > 10 })->or(0),  0, 'find 3');

is(
    $range->bind(sub($x) { Array->wrap($x) }),
    [1 .. 10],
    'bind - somehow like id');

is(
    Array->wrap(
        Array->wrap(1,1),
        [2,3],
        Array->wrap(5,8,13),
    )->flatten,
    [1,1,2,3,5,8,13],
    'flatten - flattens an array of array');

is(Array->wrap([1,1], [1,2]), [[1,1],[1,2]], 'wrap with arrays');
is(Array->wrap([1,1])       , [[1,1]],       'wrap with array');
is(Array->from_array([1,1]) , [1,1],         'from_array vs. wrap');

is($range->reduce($add),         Some(55), 'reduce');
is(Array->empty->reduce($add),       None, 'reduce on empty 1');
is(Array->empty->reduce($add)->or(0),   0, 'reduce on empty 2');
is(Array->wrap(1)->reduce($add),  Some(1), 'reduce on single element');

is(Array->empty->first,          None, 'first on empty');
is(Array->empty->first->or(0),      0, 'first and optional');
is($range->first,             Some(1), 'first on non empty');
is($range->first->or(0),            1, 'first on non empty and option::or');

is(Array->empty->last,           None, 'last on empty');
is(Array->empty->last->or(0),       0, 'last on empty with or');
is($range->last,             Some(10), 'last on non empty');
is($range->last->or(0),            10, 'last on non empty with option::or');

is(
    Array->wrap(1,5,-3,10,9,-2)->sort(sub($x,$y) { $x <=> $y }),
    [-3,-2,1,5,9,10],
    'sort 1');

is(
    Array->wrap(qw/B b c A a C/)->sort(sub($x,$y) { $x cmp $y }),
    [qw/A B C a b c/],
    'sort 2');

# Schwartzian Transformation
{
    my $data = Array->wrap(
        { id => 1, char => 'W' },
        { id => 4, char => 'L' },
        { id => 5, char => 'D' },
        { id => 2, char => 'O' },
        { id => 3, char => 'R' },
    );

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

my $fs = Array->wrap([1,"Hi"],[2,"Foo"],[3,"Bar"],[4,"Mug"]);
is($fs->fsts, [1,2,3,4],            'fsts');
is($fs->snds, [qw/Hi Foo Bar Mug/], 'snds');

is(
    Array->wrap([1,2,3], [4,5,6], [7,8,9])->flatten,
    [1..9],
    'flatten');

is(
    Array::zip(
        Array->range(1,6),
        Array->wrap(qw(A B C D E F))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/],[qw/5 E/],[qw/6 F/]],
    'zip 1');

is(
    Array::zip(
        Array->range(1,3),
        Array->wrap(qw(A B C D E F))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/]],
    'zip 2');

is(
    Array::zip(
        Array->range(1,6),
        Array->wrap(qw(A B C D))
    ),
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/]],
    'zip 3');

is(
    Array::zip(
        Array->empty,
        Array->wrap(qw(A B C D E F))
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
    Array->wrap(
        Array->wrap(1,2,3),
        Array->wrap(4,5,6),
        Array->wrap(7,8,9),
    ),
    [
        [1,2,3],
        [4,5,6],
        [7,8,9],
    ],
    'Is array of array');

is(
    Array->wrap(
        Array->wrap(1,2,3),
        Array->wrap(4,5,6),
        Array->wrap(7,8,9),
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

# regex_match
{
    my $lines = Array->wrap(
        '2023-11-25T15:10:00',
        '2023-11-20T10:05:29',
        'xxxx-xx-xxT00:00:00',
        '1900-01-01T00:00:01',
        '12345678901234567890',
    );

    my $matches = $lines->regex_match(qr/
        \A
            (\d\d\d\d) - (\d\d) - (\d\d)  # Date
        T                                 # T
            (\d\d) : (\d\d) : (\d\d)      # Time
        \z/xms, [3,2,1,4,5,6]);

    is(
        $matches,
        [
            [qw/25 11 2023 15 10 00/],
            [qw/20 11 2023 10 05 29/],
            [qw/01 01 1900 00 00 01/],
        ],
        'regex_match');

    is(
        $lines->regex_match(qr/\A
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
        \z/xms, [1..20]),
        [
            [1 .. 9, 0, 1 .. 9, 0],
        ],
        'check 20 matches');
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

is(Array->wrap()     ->intersperse(0), [],              'intersperse 1');
is(Array->wrap(1)    ->intersperse(0), [1],             'intersperse 2');
is(Array->wrap(1,2)  ->intersperse(0), [1,0,2],         'intersperse 3');
is(Array->wrap(1,2,3)->intersperse(0), [1,0,2,0,3],     'intersperse 4');
is(Array->wrap(1..4) ->intersperse(0), [1,0,2,0,3,0,4], 'intersperse 5');
is(
    Array->range(1,10)->intersperse(0),
    [1,0,2,0,3,0,4,0,5,0,6,0,7,0,8,0,9,0,10],
    'intersperse 6');

is(Array->wrap(5)    ->repeat(-1), [],            'repeat 1');
is(Array->wrap(5)    ->repeat(0) , [],            'repeat 2');
is(Array->wrap(5)    ->repeat(1) , [5],           'repeat 3');
is(Array->wrap(5)    ->repeat(5) , [5,5,5,5,5],   'repeat 4');
is(Array->wrap(1,2,3)->repeat(2) , [1,2,3,1,2,3], 'repeat 5');
is(Array->wrap(1,2,3)->repeat(3) , [(1,2,3) x 3], 'repeat 6');

is(Array->replicate(10, 'A'), [('A') x 10], 'replicate');

is(
    Array::zip(
        Array->replicate(10, 1),
        Array->wrap(qw/A B C D E F/),
    ),
    [ [1,'A'],[1,'B'],[1,'C'],[1,'D'],[1,'E'],[1,'F'] ],
    'replicate with zip');

is(
    Array::zip(
        Array->wrap(1,2)->repeat(9),
        Array->wrap(qw/A B C D E F/),
    ),
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],[2,'F'] ],
    'repeat with zip 1');

is(
    Array::zip(
        Array->wrap(1,2)->repeat(2),
        Array->wrap(qw/A B C D E F/),
    ),
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'] ],
    'repeat with zip 2');

is(
    Array::zip(
        Array->wrap(1,2)->repeat(20),
        Array->wrap(qw/A B C D E/)->repeat(20),
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
    Array
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->take_while(sub($x) { $x < 100 }),
    [1,3,20,-40,20,12],
    'take_while 1'
);

is(
    Array
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->take_while(sub($x) { $x > 100 }),
    [],
    'take_while 2'
);

is(
    Array
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x < 100 }),
    [100, 5, 20],
    'skip_while 1'
);

is(
    Array
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x > 100 }),
    [1,3,20,-40,20,12,100,5,20],
    'skip_while 2'
);

{ # iter & foreach
    my @iter;    $range->iter(   sub($x) { push @iter,    $x });
    my @foreach; $range->foreach(sub($x) { push @foreach, $x });

    is(\@iter, [1..10],   'iter');
    is(\@iter, \@foreach, 'iter same as foreach');
}

{ # iteri & foreachi
    my @iteri;    $range->iteri(   sub($x,$i) { push @iteri,    [$i,$x] });
    my @foreachi; $range->foreachi(sub($x,$i) { push @foreachi, [$i,$x] });

    is(\@iteri, [[0,1], [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10]], 'iteri');
    is(\@iteri, \@foreachi, 'iteri same as foreachi');
}

# sort
is(Array->new(qw/1 9 10 5/)->sort_str, [qw/1 10 5 9/], 'sort_str');
is(Array->new(qw/1 9 10 5/)->sort_num, [1, 5, 9, 10],  'sort_num');

# keyed_by
{
    my $data = Array->new(
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
        $data->keyed_by(key 'name')->values->map(key 'name')->sort_str,
        $data->distinct_by(key 'name')->map(key 'name')->sort_str,
        'keyed_by->values is like distinct_by');
}

# sort_hash_*
{
    my $data = Array->new(
        Hash->new(id => 2,  name => 'B'),
        Hash->new(id => 3,  name => 'A'),
        Hash->new(id => 1,  name => 'C'),
        Hash->new(id => 10, name => 'J'),
    );

    is(
        $data->sort_hash_str('name'),
        [
            {id =>  3, name => 'A'},
            {id =>  2, name => 'B'},
            {id =>  1, name => 'C'},
            {id => 10, name => 'J'}
        ],
        'sort_hash_str name');

    is(
        $data->sort_hash_str('id'),
        [
            {id =>  1, name => 'C'},
            {id => 10, name => 'J'},
            {id =>  2, name => 'B'},
            {id =>  3, name => 'A'},
        ],
        'sort_hash_str id');

    is(
        $data->sort_hash_num('id'),
        [
            {id =>  1, name => 'C'},
            {id =>  2, name => 'B'},
            {id =>  3, name => 'A'},
            {id => 10, name => 'J'},
        ],
        'sort_hash_num id');
}

is(
    Array->new(qw/foo bar baz foo bar foo 1 2/)->count,
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

# slice
{
    # index: 0 1 2 3 4 5 6 7 8 9
    # data:   1 2 3 4 5 6 7 8 9 10
    my $data = Array->range(1,10);
    is($data->slice(0,3),   [1,2,3],      'slice at beginning');
    is($data->slice(1,3),   [2,3,4],      'slice skipping first');
    is($data->slice(20,10), [],           'slice empty');
    is($data->slice(5,100), [6,7,8,9,10], 'slice to the end');
    is($data->slice(3,3),   [4,5,6],      'slice of 3');
    is($data->slice(9,1),   [10],         'slice at end');
    is($data->slice(9,10),  [10],         'slice at end');
    is($data->slice(10,1),  [],           'slice out of bound');
    is($data->slice(0,0),   [],           'slice with zero length');
    is($data->slice(0,-10), [],           'slice with negative length');
    is($data->slice(-3,3),  [8,9,10],     'slice with negative position 1');
    is($data->slice(-3,2),  [8,9],        'slice with negative position 2');
    is($data->slice(-3,0),  [],           'slice with negative position and 0 length');
    is($data->slice(-3,-3), [],           'slice both values negative');
    is($data->slice(1,3), $data->skip(1)->take(3), 'slice is like skip->take');
}

# copy of array-ref
{
    my $data = Array->new(1,2,3,4,5);
    my $new  = $data->copy;

    is($data, $new,         'contains same data');
    ok(not ($data eq $new), 'not same array references');

    my $new2  = Array::copy([1,2,3,undef,4,5,6]);
    is($new2, [1,2,3], 'copy only copies up to first undef');
}

# filter_e
{
    is(
        $range->filter(sub($x) { $x % 2 == 0 }),
        $range->filter_e('$_ % 2 == 0'),
        'filter_e');
}

# cartesian
{
    my $nums   = Array->new(7,8,9,10);
    my $symbol = Array->new("Hearth", "Spades");

    is(
        $nums->cartesian($symbol),
        [
            [7,"Hearth"], [7,"Spades"],  [8,"Hearth"],  [8,"Spades"],
            [9,"Hearth"], [9,"Spades"], [10,"Hearth"], [10,"Spades"],
        ],
        'cartesian');
}

# split and join
{
    my $words =
        Array
        ->new("Foo+Bar+Baz", "maz+faz")
        ->split(qr/\+/);

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

done_testing;
