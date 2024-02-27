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

# checks count & capacity
sub check_cc($queue, $count, $capacity, $msg) {
    is($queue->count,    $count,    sprintf('%s: count must be %d', $msg, $count));
    is($queue->capacity, $capacity, sprintf('%s: capacity must be %d', $msg, $capacity));
}

{
    my $queue = Queue->new(1..16);

    is($queue->to_array, [1..16], 'new queue');
    $queue->remove for 1 .. 6;
    check_cc($queue, 10, 16, 'AAA');

    $queue->add(17 .. 22);
    check_cc($queue, 16, 16, 'AAB');

    $queue->add(23);
    check_cc($queue, 17, 32, 'AAC');

    $queue->add(24 .. 32);
    check_cc($queue, 26, 32, 'AAD');

    my @three = $queue->remove(3);
    is(\@three, [7,8,9], 'first three elements');
    check_cc($queue, 23, 32, 'AAE');

    my @two = $queue->remove(2);
    $queue->add(33 .. 36);
    is(\@two, [10,11], 'first two');
    check_cc($queue, 25, 32, 'ABA');

    @two = $queue->remove(2);
    $queue->add(37 .. 40);
    is(\@two, [12,13], 'first two');
    check_cc($queue, 27, 32, 'ABB');

    @two = $queue->remove(2);
    $queue->add(41 .. 44);
    is(\@two, [14,15], 'first two');
    check_cc($queue, 29, 32, 'ABC');

    @two = $queue->remove(2);
    $queue->add(45 .. 48);
    is(\@two, [16,17], 'first two');
    check_cc($queue, 31, 32, 'ABD');

    @two = $queue->remove(2);
    $queue->add(49 .. 52);
    is(\@two, [18,19], 'first two');
    check_cc($queue, 33, 64, 'ABE');
}

done_testing;
