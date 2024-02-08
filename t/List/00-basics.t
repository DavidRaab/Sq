#!perl
use 5.036;
use List::Util qw(reduce);
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
# use DDP;

# Some values, functions, ... for testing
my $range     = List->range(1, 10);
my $rangeDesc = List->range(10, 1);

my $add     = sub($x, $y) { $x + $y     };
my $add1    = sub($x)     { $x + 1      };
my $double  = sub($x)     { $x * 2      };
my $square  = sub($x)     { $x * $x     };
my $is_even = sub($x)     { $x % 2 == 0 };

# basic List constructor tests
is(List->empty, [],       'List->empty');
ok(List->empty->is_empty, 'List->is_empty');
is($range->is_empty, 0,   '$range not empty');
is(List->cons(1, List->cons(2, List->empty)), [1, [2, []]], 'List->cons');
is(List->range(1,3), [1, [2, [3, []]]], 'List->range(1,3)');
is($range->head, 1, 'head');
is($range->head, List::head($range), 'List::head');
is(List->range(1,3)->tail, [2, [3,[]]], 'tail');
is(List->range(1,3)->tail, List::tail(List->range(1,3)), 'List::tail');

# Basic checks of range and rangeDesc
is($range, D(),                 'range returns something');
is($range, check_isa('List'),   'returns a List');
is($range->to_array, [1 .. 10], 'to_array');
is($range->to_array, [1 .. 10], 'calling to_array twice still returns the same');
is(List->range(1,1)->to_array, [1], 'range is inclusive');
is($rangeDesc->to_array, [reverse 1 .. 10], 'rangeDesc');
is($range->to_array, $rangeDesc->rev->to_array, 'reverse of rangeDesc same as range');

is(
    $range->map($double)->to_array,
    [2,4,6,8,10,12,14,16,18,20],
    'map');
is(
    $range->filter($is_even)->to_array,
    [2,4,6,8,10],
    'filter');

is($range->take(5)->to_array,  [1..5], 'take 1');
is($range->take(0)->to_array,  [],     'take 2');
is($range->take(-1)->to_array, [],     'take 3');

is($range->count, 10, 'count');
is($range->take(5)->count, 5, 'take & count');
is(
    $range->map($square)->filter($is_even)->to_array,
    [4,16,36,64,100],
    'map filter');
is(
    $range->map($square)->filter($is_even)->take(3)->to_array,
    [4,16,36],
    'map filter take');
is(
    $range->fold(0, sub($count, $x) { $count + 1 }),
    $range->count,
    'fold with non-reftype');
is(
    $range->fold([], sub($array, $x) { push @$array, $x; $array }),
    $range->to_array,
    'fold with reftype 1');
is(
    $range->fold([], sub($array, $x) { [@$array, $x ] }),
    $range->to_array,
    'fold with reftype 2');
is(
    $range->fold    ([], sub($array, $x) { push @$array, $x; $array }),
    $range->fold_mut([], sub($array, $x) { push @$array, $x         }),
    'fold_mut');

is($range->rev, check_isa('List'), 'rev return List');
is($range->rev->to_array, [10,9,8,7,6,5,4,3,2,1], 'rev');
is(
    $range->rev->map($add1)->rev->to_array,
    [ $range->map($add1)->expand ],
    'expand');

is($range->sum, 55, 'sum');
is($range->sum, $range->rev->sum, 'sum 2');

# Checking wrap & rangeStep
{
    # Currently on undef it aborts, should it just skip the undef and return
    # the values from 1 to 6?
    is(List->wrap(1,2,3,undef,4,5,6)->to_array, [1..3], 'wrap containing an undef');

    is(List->wrap(5)->to_array, [5], 'wrap');
    is(
        List->wrap(5)->append(List->wrap(10))->to_array,
        [5, 10],
        'wrap and append');
    is(
        List->range(1,5)->append(List->range(6,10))->to_array,
        List->range(1,10)->to_array,
        'append two ranges');
    is(List->range_step(1, 2, 10)->to_array, [ 1,3,5,7,9], '1 .. 10 step 2');
    is(List->range_step(10, 2, 1)->to_array, [10,8,6,4,2], '10 .. 1 step 2');
}

is(
    $range->fold(List->empty, sub($l, $x) { List->cons($x, $l) }),
    $range->rev,
    'fold');

is(
    $range->fold_back(List->empty, sub($l, $x) { List->cons($x*2, $l) }),
    $range->map(sub($x) { $x * 2 }),
    'fold_back');

is(
    List::zip(
        List->range(0, 100),
        List->wrap(qw/A B C D E F/),
    )->to_array,
    List->wrap(qw/A B C D E F/)->indexed->to_array,
    'indexed');

is(
    $range->take(3)->indexed->to_array,
    [[0,1], [1,2], [2,3]],
    'take->indexed');
is(
    List->init(10, \&id)->map($add1)->to_array,
    $range->to_array,
    'init->map');
is(
    Seq->range(1,10)->indexed->to_array,
    Seq->init(10, sub($idx) { [$idx, $idx+1] })->to_array,
    'range->indexed vs. init');
is(
    (reduce { $a->append($b) } map { List->wrap($_) } 1 .. 10)->to_array,
    $range->to_array,
    'append a list of wrapped values');

done_testing;
exit;
is(
    Seq->concat(map { Seq->wrap($_) } 1 .. 10)->to_array,
    $range->to_array,
    'concat');
like(
    Seq->concat->to_array,
    Seq->empty->to_array,
    'concat on zero is empty');

is(
    Seq->wrap(Seq->range(1,10)->expand)->to_array,
    [1 .. 10],
    'expand and wrap is isomorph');

is(
    Seq->wrap(1..5)->append(
        Seq->wrap(6..10)
    )->to_array,
    Seq->concat(
        Seq->wrap(1..3),
        Seq->wrap(4..6),
        Seq->wrap(7..10),
    )->to_array,
    'append vs. concat');
is(
    Seq->empty->append(Seq->range(1,5))->append(Seq->range(6,10))->to_array,
    $range->to_array,
    'append on empty');

is(
    Seq->concat(
        Seq->empty,
        Seq->range(1,5),
        Seq->empty,
        Seq->range(10,12),
        Seq->empty,
        Seq->wrap("Hello"),
        Seq->empty
    )->to_array,
    Seq->wrap(1..5, 10..12, "Hello")->to_array,
    'concat with empties');
is(
    Seq->from_array([1..10])->to_array,
    Seq->wrap(1..10)->to_array,
    'from_array and wrap');
is(
    Seq->unfold(10, sub($state) {
        if ( $state > 0 ) {
            return $state, $state-1;
        }
        else {
            return undef;
        }
    })->to_array,
    Seq->range(1,10)->rev->to_array,
    'unfold');
is(
    Seq->wrap->to_array,
    Seq->empty->to_array,
    'wrap without arguments same as empty');

# concat tests
{
    is(Seq->concat->to_array, [], 'Empty concat');
    is(Seq->concat($range)->to_array, $range->to_array, 'concat with 1 element');
    is(
        Seq->concat(
            Seq->range(1,5),
            Seq->range(6,10),
        )->to_array,
        [1..10],
        'concat with 2 elemets');
    is(
        Seq->concat(
            Seq->range(1,5),
            Seq->range(6,10),
            Seq->range(11,15),
        )->to_array,
        [1..15],
        'concat with 3 elements');
}

is($range->skip(3)->take(3)->to_array,  [4,5,6], 'skip->take 1');
is($range->skip(3)->take(10)->to_array, [4..10], 'skip->take 2');
is($range->skip(10)->take(1)->to_array, [],      'skip->take 3');

is($range->take(5)->skip(2)->to_array,  [3,4,5], 'take->skip 1');
is($range->take(5)->skip(4)->to_array,  [5],     'take->skip 2');
is($range->take(5)->skip(6)->to_array,  [],      'take->skip 2');

is(
    Seq->concat(
        Seq->range(1,10),
        Seq->range(10,1),
    )->to_array,
    Seq->concat(
        $range,
        $range->rev
    )->to_array,
    'concat with rev');

is(Seq->wrap([A => 1], [B => 2], [C => 3])->sum_by(\&snd), 6, 'sumBy');
is(
    Seq->wrap(qw/H e l l o W o r l d !/)->str_join('-'),
    "H-e-l-l-o-W-o-r-l-d-!",
    'str_join');

is(
    Seq->wrap(qw/Hello World you are awesome/)->to_hash(sub($x) { length $x => $x }),
    hash {
        field 5 => "World";
        field 3 => "are";
        field 7 => "awesome";
        end;
    },
    'to_hash 1');

is(
    Seq->wrap(qw/Hello World you are awesome/)->to_hash(sub($x) { $x => length $x }),
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
    Seq->wrap(qw/Hello World you are awesome/)->to_hash_of_array(sub($x) { length $x => $x }),
    hash {
        field 5 => array { item "Hello";   item "World" };
        field 3 => array { item "you";     item "are"   };
        field 7 => array { item "awesome";              };
        end;
    },
    'to_hash_of_array');

is(Seq->wrap(1,1,2,3,1,4,5,4,3,2,6)->distinct->to_array, [1..6],              'distinct 1');
is(Seq->wrap(1,2,3,2,23,123,4,12,2)->distinct->to_array, [1,2,3,23,123,4,12], 'distinct 2');

# distinct_by tests
{
    my $data = Seq->wrap(
        {id => 1, name => "Foo"},
        {id => 2, name => "Bar"},
        {id => 3, name => "Baz"},
        {id => 1, name => "Foo"},
    );

    is($data->count, 4, 'distinct_by starts with 4');
    is($data->distinct->count, 4, 'still 4 as HashRefs are always unequal');
    is($data->distinct_by(sub($x) { $x->{id} })->count, 3, 'one element less');
    is(
        $data->distinct_by(sub($x) { $x->{id} })->to_array,
        [
            {id => 1, name => "Foo"},
            {id => 2, name => "Bar"},
            {id => 3, name => "Baz"},
        ],
        'check elements and order');
}

is(
    Seq->wrap(qw/A B C D E F/)->mapi(sub($x,$i) { [$x,$i] })->to_array,
    [[A => 0], [B => 1], [C => 2], [D => 3], [E => 4], [F => 5]],
    'mapi');

is(Seq->init( 0,  sub($idx) { $idx })->to_array, [], 'init with count 0');
is(Seq->init(-1,  sub($idx) { $idx })->to_array, [], 'init with count -1');
is(Seq->init(-10, sub($idx) { $idx })->to_array, [], 'init with count -10');
is(Seq->range_step(1,1,1)->to_array, [1], 'range_step with 1,1,1');
is(
    Seq->range_step(0,0.1,1)->to_array,
    array {
        for (my $f=0.0; $f <= 1.0; $f+=0.1) {
            item float $f;
        }
    },
    'range_step with 0,0.1,1');
like(
    dies { Seq->range_step(0,0,1)->to_array },
    qr/^\$step is 0/,
    'range_step dies with step size of zero');

is(
    $range->map($square)->filter($is_even)->to_array,
    $range->choose(sub($x) {
        my $s = $x * $x;
        $s % 2 == 0 ? $s : undef
    })->to_array,
    'choose same as map->filter');

is(
    $range->choose(sub($x) {
        my $s = $x * $x;
        $s % 2 == 0 ? $s : undef
    })->to_array,
    [grep { $_ % 2 == 0 } map { $_ * $_ } 1 .. 10],
    'Non Lazy Perl implementation of choose');


is($range->find(undef, sub($x) { $x > 5  }),     6, 'find 1');
is($range->find(undef, sub($x) { $x > 10 }), undef, 'find 2');
is($range->find(0,     sub($x) { $x > 10 }),     0, 'find 3');

is(
    $range->bind(sub($x) { Seq->wrap($x) })->to_array,
    [1 .. 10],
    'bind - somehow like id');

is(
    Seq->wrap(
        Seq->wrap(1,1),
        Seq->wrap(2,3,5,8,13),
    )->flatten->to_array,
    [1,1,2,3,5,8,13],
    'flatten - flattens a seq of seq');

is(Seq->wrap([1,1], [1,2])->to_array, [[1,1],[1,2]], 'wrap with arrays');
is(Seq->wrap([1,1])       ->to_array, [[1,1]],       'wrap with array');
is(Seq->from_array([1,1]) ->to_array, [1,1],         'from_array vs. wrap');

is($range->reduce(undef, $add),      55, 'reduce');
is(Seq->empty->reduce(undef, $add), U(), 'reduce on empty 1');
is(Seq->empty->reduce(0, $add),       0, 'reduce on empty 2');
is(Seq->wrap(1)->reduce(0, $add),     1, 'reduce on single element');

is(Seq->empty->first(undef), U(), 'first on empty is undef');
is(Seq->empty->first(0),       0, 'first with default value');
is($range->first(-1),          1, 'first on non empty without default');
is($range->first(0),           1, 'first on non empty with default');

is(Seq->empty->last(undef),   U(), 'last on empty is undef');
is(Seq->empty->last(0),         0, 'last with default value');
is($range->last(undef),        10, 'last on non empty without default');
is($range->last(0),            10, 'last on non empty with default');

is(
    Seq->wrap(1,5,-3,10,9,-2)->sort(sub($x,$y) { $x <=> $y })->to_array,
    [-3,-2,1,5,9,10],
    'sort 1');

is(
    Seq->wrap(qw/B b c A a C/)->sort(sub($x,$y) { $x cmp $y })->to_array,
    [qw/A B C a b c/],
    'sort 2');

# Schwartzian Transformation
{
    my $data = Seq->wrap(
        { id => 1, char => 'W' },
        { id => 4, char => 'L' },
        { id => 5, char => 'D' },
        { id => 2, char => 'O' },
        { id => 3, char => 'R' },
    );

    is(
        $data->sort_by(sub($x,$y) { $x <=> $y }, sub($x) { $x->{id} })->to_array,
        [
            { id => 1, char => 'W' },
            { id => 2, char => 'O' },
            { id => 3, char => 'R' },
            { id => 4, char => 'L' },
            { id => 5, char => 'D' },
        ],
        'sort_by 1');

    is(
        $data->sort_by(sub($x,$y) { $x cmp $y }, sub($x) { $x->{char} })->to_array,
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
        ->map (sub($x)    {  $x->[1]              })
        ->to_array,

        $data->sort_by(sub($x,$y) { $x <=> $y }, sub($x) { $x->{id} })->to_array,
        'sort_by 3');
}


my $fs = Seq->wrap([1,"Hi"],[2,"Foo"],[3,"Bar"],[4,"Mug"]);
is($fs->fsts->to_array, [1,2,3,4],            'fsts');
is($fs->snds->to_array, [qw/Hi Foo Bar Mug/], 'snds');

is(
    Seq->wrap([1,2,3], [4,5,6], [7,8,9])->flatten_array->to_array,
    [1..9],
    'flatten_array');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->wrap(qw(A B C D E F))
    )->to_array,
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/],[qw/5 E/],[qw/6 F/]],
    'zip 1');

is(
    Seq::zip(
        Seq->range(1,3),
        Seq->wrap(qw(A B C D E F))
    )->to_array,
    [[qw/1 A/],[qw/2 B/],[qw/3 C/]],
    'zip 2');

is(
    Seq::zip(
        Seq->range(1,6),
        Seq->wrap(qw(A B C D))
    )->to_array,
    [[qw/1 A/],[qw/2 B/],[qw/3 C/],[qw/4 D/]],
    'zip 3');

is(
    Seq::zip(
        Seq->empty,
        Seq->wrap(qw(A B C D E F))
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
    Seq->wrap(
        Seq->wrap(1,2,3),
        Seq->wrap(4,5,6),
        Seq->wrap(7,8,9),
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
    $range->pick(undef, sub($x) { $x*$x > 1000 ? $x*$x : undef }),
    undef,
    'pick squared element that is greater 1000');
is(
    $range->pick("NO", sub($x) { $x*$x > 1000 ? $x*$x : undef }),
    "NO",
    'pick squared element that is greater 1000');
is(
    $range->pick(undef, sub($x) { $x*$x > 50 ? $x*$x : undef }),
    64,
    'pick squared element that is greater 50');
is(
    $range->pick("NO", sub($x) { $x*$x > 50 ? $x*$x : undef }),
    64,
    'pick squared element that is greater 50');

# regex_match
{
    my $lines = Seq->wrap(
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
        $matches->to_array,
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
        \z/xms, [1..20])->to_array,
        [
            [1 .. 9, 0, 1 .. 9, 0],
        ],
        'check 20 matches');
}

is( $range->windowed(-1)->to_array, Seq->empty->to_array,   'windowed -1');
is( $range->windowed(0) ->to_array, Seq->empty->to_array,   'windowed 0');
is( $range->windowed(1) ->to_array, [map { [$_] } 1 .. 10], 'windowed 1');
is(
    $range->windowed(2)->to_array,
    [ [1,2], [2,3], [3,4], [4,5], [5,6], [6,7], [7,8], [8,9], [9,10] ],
    'windowed 2');
is(
    $range->windowed(5)->to_array,
    [
        [1,2,3,4,5], [2,3,4,5,6], [3,4,5,6,7], [4,5,6,7,8], [5,6,7,8,9], [6,7,8,9,10]
    ],
    'windowed 5');

is($range->windowed(10)->to_array, [ [1,2,3,4,5,6,7,8,9,10] ], 'windowed 10');
is($range->windowed(11)->to_array, Seq->empty->to_array,       'windowed 11');

is(Seq->wrap()     ->intersperse(0)->to_array, [],          'intersperse 1');
is(Seq->wrap(1)    ->intersperse(0)->to_array, [1],         'intersperse 2');
is(Seq->wrap(1,2)  ->intersperse(0)->to_array, [1,0,2],     'intersperse 3');
is(Seq->wrap(1,2,3)->intersperse(0)->to_array, [1,0,2,0,3], 'intersperse 4');
is(
    Seq->range(1,10)->intersperse(0)->to_array,
    [1,0,2,0,3,0,4,0,5,0,6,0,7,0,8,0,9,0,10],
    'intersperse 5');

is(Seq->always(5)->take(-1)->to_array, [],         'always 1');
is(Seq->always(5)->take(0) ->to_array, [],         'always 2');
is(Seq->always(5)->take(1) ->to_array, [5],        'always 3');
is(Seq->always(5)->take(10)->to_array, [(5) x 10], 'always 4');

is(Seq->wrap(5)    ->infinity->take(0) ->to_array, [],                    'infinity 1');
is(Seq->wrap(5)    ->infinity->take(1) ->to_array, [5],                   'infinity 2');
is(Seq->wrap(5)    ->infinity->take(5) ->to_array, [5,5,5,5,5],           'infinity 3');
is(Seq->wrap(1,2,3)->infinity->take(3) ->to_array, [1,2,3],               'infinity 4');
is(Seq->wrap(1,2,3)->infinity->take(6) ->to_array, [1,2,3,1,2,3],         'infinity 5');
is(Seq->wrap(1,2,3)->infinity->take(9) ->to_array, [1,2,3,1,2,3,1,2,3],   'infinity 6');
is(Seq->wrap(1,2,3)->infinity->take(10)->to_array, [1,2,3,1,2,3,1,2,3,1], 'infinity 7');

is(Seq->wrap(5)    ->repeat(-1)->to_array, [],            'repeat 1');
is(Seq->wrap(5)    ->repeat(0) ->to_array, [],            'repeat 2');
is(Seq->wrap(5)    ->repeat(1) ->to_array, [5],           'repeat 3');
is(Seq->wrap(5)    ->repeat(5) ->to_array, [5,5,5,5,5],   'repeat 4');
is(Seq->wrap(1,2,3)->repeat(2) ->to_array, [1,2,3,1,2,3], 'repeat 5');
is(Seq->wrap(1,2,3)->repeat(3) ->to_array, [(1,2,3) x 3], 'repeat 6');

is(Seq->replicate(10, 'A')->to_array, [('A') x 10], 'replicate');

is(
    Seq::zip(
        Seq->always(1),
        Seq->wrap(qw/A B C D E F/),
    )->to_array,
    [ [1,'A'],[1,'B'],[1,'C'],[1,'D'],[1,'E'],[1,'F'] ],
    'always with zip');

is(
    Seq::zip(
        Seq->wrap(1,2)->repeat(9),
        Seq->wrap(qw/A B C D E F/),
    )->to_array,
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],[2,'F'] ],
    'repeat with zip 1');

is(
    Seq::zip(
        Seq->wrap(1,2)->repeat(2),
        Seq->wrap(qw/A B C D E F/),
    )->to_array,
    [ [1,'A'],[2,'B'],[1,'C'],[2,'D'] ],
    'repeat with zip 2');

is(
    Seq::zip(
        Seq->wrap(1,2)->infinity,
        Seq->wrap(qw/A B C D E/)->infinity,
    )->take(12)->to_array,
    [
        [1,'A'],[2,'B'],[1,'C'],[2,'D'],[1,'E'],
        [2,'A'],[1,'B'],[2,'C'],[1,'D'],[2,'E'],
        [1,'A'],[2,'B'],
    ],
    'zip on infinities');

is(
    Seq::zip(
        $range->infinity,
        $range->rev->infinity,
    )->take(15)->to_array,
    [
        [1,10],[2,9],[3,8],[4,7],[5,6],[6,5],[7,4],[8,3],[9,2],[10,1],
        [1,10],[2,9],[3,8],[4,7],[5,6],
    ],
    'zip on ifinity with reverse');

is(
    Seq::zip(
        $range->infinity,
        $range->rev->infinity,
    )->take(15)->map(sub($tuple) { fst($tuple) + snd($tuple) })->to_array,

    Seq->always(11)->take(15)->to_array,
    'zip,infinity,rev,take,map,always');

is(
    Seq
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->take_while(sub($x) { $x < 100 })
    ->to_array,
    [1,3,20,-40,20,12],
    'take_while 1'
);

is(
    Seq
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->take_while(sub($x) { $x > 100 })
    ->to_array,
    [],
    'take_while 2'
);

is(
    Seq
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x < 100 })
    ->to_array,
    [100, 5, 20],
    'skip_while 1'
);

is(
    Seq
    ->wrap(1, 3, 20, -40, 20, 12, 100, 5, 20)
    ->skip_while(sub($x) { $x > 100 })
    ->to_array,
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

done_testing;
