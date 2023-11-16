#!perl
use 5.036;
use List::Util qw(reduce);
use Seq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end/;
# use DDP;

diag( "Testing Seq $Seq::VERSION, Perl $], $^X" );
is($Seq::VERSION, number_ge("0.001"), 'Check minimum version number');

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $id      = sub($x) { $x          };
my $add1    = sub($x) { $x + 1      };
my $double  = sub($x) { $x * 2      };
my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

my $fst     = sub($array) { $array->[0] };
my $snd     = sub($array) { $array->[1] };

# Basic checks of range and rangeDesc
is($range, D(),                 'range returns something');
is($range, check_isa('Seq'),    'returns a Seq');
is($range->to_array, [1 .. 10], 'to_array');
is($range->to_array, [1 .. 10], 'calling to_array twice still returns the same');
is(Seq->range(1,1)->to_array, [1], 'range is inclusive');
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
is(
    $range->take(5)->to_array,
    [1..5],
    'take');
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
    $range->fold([], sub($array, $x) { push @$array, $x }),
    $range->to_array,
    'fold with reftype');

is($range->rev, check_isa('Seq'), 'rev return Seq');
is($range->rev->to_array, [10,9,8,7,6,5,4,3,2,1], 'rev');
is(
    $range->rev->map($add1)->rev->to_array,
    [ $range->map($add1)->to_list ],
    'to_list');
is($range->sum, 55, 'sum');
is($range->sum, $range->rev->sum, 'sum 2');

# Checking wrap & rangeStep
{
    is(Seq->wrap(5)->to_array, [5], 'wrap');
    is(
        Seq->wrap(5)->append(Seq->wrap(10))->to_array,
        [5, 10],
        'wrap and append');
    is(
        Seq->range(1,5)->append(Seq->range(6,10))->to_array,
        Seq->range(1,10)->to_array,
        'append two ranges');
    is(Seq->range_step(1, 2, 10)->to_array, [ 1,3,5,7,9], '1 .. 10 step 2');
    is(Seq->range_step(10, 2, 1)->to_array, [10,8,6,4,2], '10 .. 1 step 2');
}

is(
    $range->take(3)->indexed->to_array,
    [[0,1], [1,2], [2,3]],
    'take->indexed');
is(
    Seq->init(10, $id)->map($add1)->to_array,
    $range->to_array,
    'init->map');
is(
    Seq->range(1,10)->indexed->to_array,
    Seq->init(10, sub($idx) { [$idx, $idx+1] })->to_array,
    'range->indexed vs. init');
is(
    (reduce { $a->append($b) } map { Seq->wrap($_) } 1 .. 10)->to_array,
    $range->to_array,
    'append a list of wrapped values');
is(
    Seq->concat(map { Seq->wrap($_) } 1 .. 10)->to_array,
    $range->to_array,
    'concat');
like(
    Seq->concat()->to_array,
    Seq->empty->to_array,
    'concat on zero is empty');
is(
    Seq->from_list(1 .. 10)->to_array,
    $range->to_array,
    'from_list');
is(
    Seq->from_list(Seq->range(1,10)->to_list)->to_array,
    [1 .. 10],
    'from_list and to_list is isomorph');
is(
    Seq->from_list(1..5)->append(
        Seq->from_list(6..10)
    )->to_array,
    Seq->concat(
        Seq->from_list(1..3),
        Seq->from_list(4..6),
        Seq->from_list(7..10),
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
    Seq->from_list(1..5, 10..12, "Hello")->to_array,
    'concat with empties');
is(
    Seq->from_array([1..10])->to_array,
    Seq->from_list(1..10)->to_array,
    'from_array and from_list');
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
    Seq->wrap(1,2,3)->to_array,
    Seq->from_list(1,2,3)->to_array,
    'from_list is an alias to wrap');
is(
    Seq->wrap->to_array,
    Seq->from_list->to_array,
    'wrap and from_list without arguments is the same');
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

is(Seq->wrap([A => 1], [B => 2], [C => 3])->sum_by($snd), 6, 'sumBy');
is(
    Seq->wrap(qw/H e l l o W o r l d !/)->join('-'),
    "H-e-l-l-o-W-o-r-l-d-!",
    'join');

is(
    Seq->wrap(qw/Hello World you are awesome/)->to_hash(sub($value) { length($value) }),
    hash {
        field 5 => "World";
        field 3 => "are";
        field 7 => "awesome";
        end;
    },
    'group_by');

is(
    Seq->wrap(qw/Hello World you are awesome/)->group_by(sub($value) { length($value) }),
    hash {
        field 5 => array { item "Hello";   item "World" };
        field 3 => array { item "you";     item "are"   };
        field 7 => array { item "awesome";              };
        end;
    },
    'group_by_duplicates');

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
    Seq->wrap(qw/A B C D E F/)->mapi($id)->to_array,
    [[0,'A'], [1,'B'], [2,'C'], [3,'D'], [4, 'E'], [5, 'F']],
    'mapi');

done_testing;