#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use DDP;

# Some values, functions, ... for testing
my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

{
    my $queue = Queue->new;

    is($queue->count,     0, 'empty queue');
    is($queue->capacity, 16, '16 capacity');
    is($queue->to_array, [], 'empty');

    $queue->add(1);
    is($queue->to_array, [1], 'add(1)');

    $queue->add(2);
    is($queue->to_array, [1,2], 'add(2)');

    $queue->add(3)->add(4);
    is($queue->to_array, [1..4], 'chain');

    $queue->add(5,6,7);
    is($queue->to_array, [1..7], 'add multiple');

    is($queue->count,     7, '7 elements');
    is($queue->capacity, 16, 'still 16 capacity');

    is($queue->remove, 1, 'remove 1');
    is($queue->remove, 2, 'remove 2');
    is($queue->remove, 3, 'remove 3');
    is($queue->count, 4, '4 elements');

    for ( 1 .. 4 ) { $queue->remove }
    is($queue->count, 0, 'empty queue');

    $queue->add(10 .. 20);
    is($queue->to_array, [10..20], '10 elements added');

    $queue->add(21 .. 30);

    is($queue->to_array, [10..30], 'is array [10 .. 30]');
    is($queue->count,    21, 'count is 21');
    is($queue->capacity, 32, 'capacity raised to 32');
}

# iter & foreach
{
    my $queue = Queue->new(1..10);
    $queue->remove;
    $queue->remove;

    my @a;
    my @b;

    $queue->iter(   sub($x) { push @a, $x });
    $queue->foreach(sub($x) { push @b, $x });

    is($queue->to_array, [3..10], 'check content');
    is($queue->count,     8,      'count is 8');
    is($queue->capacity, 16,      'capacity is 16');
    is(\@a, \@b, 'iter & foreach');
}

# iteri & foreachi
{
    my $queue = Queue->new(1..10);
    $queue->remove;
    $queue->remove;

    my @a;
    my @b;

    $queue->iteri(   sub($x,$i) { push @a, [$x,$i] });
    $queue->foreachi(sub($x,$i) { push @b, [$x,$i] });

    is($queue->count,     8, 'count is 8');
    is($queue->capacity, 16, 'capacity is 16');
    is(\@a, [[3,0],[4,1],[5,2],[6,3],[7,4],[8,5],[9,6],[10,7]], 'check content');
    is(\@a, \@b, 'iteri & foreachi');
}

{
    my $queue = Queue->new(1..16);

    is($queue->to_array, [1..16], 'new queue');
    $queue->remove for 1 .. 6;

    is($queue->count, 10, 'count must be 10');
    is($queue->capacity, 16, 'capacity 16');

    $queue->add(17 .. 22);
    is($queue->count, 16, 'count must be 16');
    is($queue->capacity, 16, 'capacity stays the same');
}

done_testing;
