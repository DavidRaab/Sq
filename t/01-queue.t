#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

{
    my $queue = Queue->new;

    is($queue->length,    0, 'empty queue');
    is($queue->to_array, [], 'empty');

    $queue->add(1);
    is($queue->to_array, [1], 'add(1)');

    $queue->add(2);
    is($queue->to_array, [1,2], 'add(2)');

    $queue->add(3);
    $queue->add(4);
    is($queue->to_array, [1..4], 'chain');

    $queue->add(5,6,7);
    is($queue->to_array, [1..7], 'add multiple');

    is($queue->length, 7, '7 elements');

    is($queue->remove, 1, 'remove 1');
    is($queue->remove, 2, 'remove 2');
    is($queue->remove, 3, 'remove 3');
    is($queue->length, 4, '4 elements');

    for ( 1 .. 4 ) { $queue->remove }
    is($queue->length, 0, 'empty queue');

    $queue->add(10 .. 20);
    is($queue->to_array, [10..20], '10 elements added');

    $queue->add(21 .. 30);

    is($queue->to_array, [10..30], 'is array [10 .. 30]');
    is($queue->length,   21,       'length is 21');
}

{
    my $queue = Queue->new(1..16);

    is($queue->to_array, [1..16], 'new queue');
    $queue->remove for 1 .. 6;
    is($queue->length, 10, 'length 1');

    $queue->add(17 .. 22);
    is($queue->length, 16, 'length 2');

    $queue->add(23);
    is($queue->length, 17, 'length 3');

    $queue->add(24 .. 32);
    is($queue->length, 26, 'length 4');

    my @three = $queue->remove(3);
    is(\@three, [7,8,9], 'first three elements');
    is($queue->length, 23, 'length 5');

    my @two = $queue->remove(2);
    $queue->add(33 .. 36);
    is(\@two, [10,11], 'first two');
    is($queue->length, 25, 'length 6');

    @two = $queue->remove(2);
    $queue->add(37 .. 40);
    is(\@two, [12,13], 'first two');
    is($queue->length, 27, 'length 7');

    @two = $queue->remove(2);
    $queue->add(41 .. 44);
    is(\@two, [14,15], 'first two');
    is($queue->length, 29, 'length 8');

    @two = $queue->remove(2);
    $queue->add(45 .. 48);
    is(\@two, [16,17], 'first two');
    is($queue->length, 31, 'length 9');

    @two = $queue->remove(2);
    $queue->add(49 .. 52);
    is(\@two, [18,19], 'first two');
    is($queue->length, 33, 'length 10');
}

done_testing;
