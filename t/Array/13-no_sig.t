#!perl
use 5.036;
use Sq;
use Sq::Test;

# Those are some tests that only work without signature loaded.
# I could just remove them, but as i anyway have written them
# i also want to test behaviour when no signature is loaded

my $range = Array->range(1,10);

is($range->extract(0,-10), [],           'extract with negative length');
is($range->extract(-3,3),  [8,9,10],     'extract with negative position 1');
is($range->extract(-3,2),  [8,9],        'extract with negative position 2');
is($range->extract(-3,0),  [],           'extract with negative position and 0 length');
is($range->extract(-3,-3), [],           'extract both values negative');
is(Array->new(5)    ->repeat(-1), [],            'repeat 1');
is(Array->new(5)    ->repeat(0) , [],            'repeat 2');
is(Array->new(5)    ->repeat(1) , [5],           'repeat 3');
is(Array->new(5)    ->repeat(5) , [5,5,5,5,5],   'repeat 4');
is(Array->new(1,2,3)->repeat(2) , [1,2,3,1,2,3], 'repeat 5');
is(Array->new(1,2,3)->repeat(3) , [(1,2,3) x 3], 'repeat 6');
is($range->windowed(-1), Array->empty,           'windowed -1');
is(Array->init(-1,  sub($idx) { $idx }), [], 'init with length -1');
is(Array->init(-10, sub($idx) { $idx }), [], 'init with length -10');
is($range->take(-1),  [],      'take(-1)');
is($range->take(-10), [],      'take(-10)');
is($range->skip(-1),  [1..10], 'skip(-1)');
is($range->skip(-10), [1..10], 'skip(-10)');
is($range->take(-1),       [], 'take 3');

done_testing;
