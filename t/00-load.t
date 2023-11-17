#!perl
use 5.036;
use List::Util qw(reduce);
use Seq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float/;
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

# Stuff that is possible because arrayref are mutable
{
    my @data = (1,2,3,4,5);
    my $data = Seq->from_array(\@data);

    is($data->count, 5, 'count is 5');
    is($data->to_array, [1..5], '$data as array');

    # change @data
    push @data, 6;
    is($data->count, 6, 'count is 6');
    is($data->to_array, [1..6], '$data is now 6');
}

# Same mutable tests with a hashref
{
    my %data = (
        1 => "Foo",
        2 => "Bar",
        3 => "Baz",
    );

    my $data = Seq->from_hash(\%data, sub($key, $value) {
        return $key . $value;
    });

    is($data->count, 3, 'count from hashref is 3');
    is(
        $data->to_array,
        bag {
            item "1Foo";
            item "2Bar";
            item "3Baz";
            end;
        },
        'hash to sequence');

    # add entry to data
    $data{4} = 'Maz';

    is($data->count, 4, 'count from hashref is 4');
    is(
        $data->to_array,
        bag {
            item "1Foo";
            item "2Bar";
            item "3Baz";
            item "4Maz";
            end;
        },
        'hash to sequence after added key');
}

# difference of wrap and from_array
{
    my @data = (1..10);

    # makes a copy at that time
    my $data1 = Seq->wrap(@data);
    # just refers to the array
    my $data2 = Seq->from_array(\@data);

    is($data1->count, 10, '$data1 has 10 items');
    is($data2->count, 10, '$data2 has 10 items');

    # we now add an element to the array
    push @data, 11;

    is($data1->count, 10, '$data1 still has 10 items');
    is($data2->count, 11, '$data2 now has 11 items');
}

# Fibonacci numbers
{
    my $fib =
        Seq->concat(
            Seq->wrap(1,1),
            Seq->unfold([1,1], sub($state) {
                my $next = $state->[0] + $state->[1];
                return $next, [$state->[1],$next];
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

# Same Fibonacci as above but unfold does not create a new arrayref on every
# iteration. It changes the $state instead. This way less garbage is created
# and could be potential a little bit faster. But it envolves writing more code.
{
    my $fib =
        Seq->concat(
            Seq->wrap(1,1),
            Seq->unfold([1,1], sub($state) {
                my $next = $state->[0] + $state->[1];
                $state->[0] = $state->[1];
                $state->[1] = $next;
                return $next, $state;
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

# You also can use a hash as a state.
{
    my $fib =
        Seq->concat(
            Seq->wrap(1,1),
            Seq->unfold({x => 1, y => 1}, sub($state) {
                my $next = $state->{x} + $state->{y};
                $state->{x} = $state->{y};
                $state->{y} = $next;
                return $next, $state;
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

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

done_testing;
