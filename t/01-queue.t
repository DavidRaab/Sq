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

my $queue = Queue->new;

is($queue->count, 0, 'empty queue');
is($queue->to_array, [], 'empty');

$queue->add(1);
is($queue->to_array, [1], 'add(1)');

$queue->add(2);
is($queue->to_array, [1,2], 'add(2)');

$queue->add(3)->add(4);
is($queue->to_array, [1..4], 'chain');

$queue->add(5,6,7);
is($queue->to_array, [1..7], 'add multiple');
is($queue->count, 7, '7 elements');

is($queue->remove, 1, 'remove 1');
is($queue->remove, 2, 'remove 2');
is($queue->remove, 3, 'remove 3');
is($queue->count, 4, '4 elements');

for ( 1 .. 4 ) { $queue->remove }
is($queue->count, 0, 'empty queue');

$queue->add(10 .. 20);
is($queue->to_array, [10..20], '10 elements added');

$queue->add(21 .. 30);
is($queue->to_array, [10..30], '20 elements');

done_testing;
