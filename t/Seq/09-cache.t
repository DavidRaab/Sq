#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

#---------- Check if cache really caches the iterator

my $calls  = 0;
my $fromto = sub($start, $stop) {
    return Seq->from_sub(sub {
        my $current = $start;
        return sub {
            $calls++;
            return $current++ if $current <= $stop;
            return undef;
        }
    });
};
my $range = $fromto->(1,10);
my $cache = $range->cache;

# there are 11 calls to the iterator. 10 calls to get 10 values.
# And the 11 call returns undef
my $r = Seq->range(1,10);

is($calls, 11, '$calls at 11 because cache executed $range once');
is($range, $r, 'generate range');
is($calls, 22, '$calls now 22');
is($range, $r, 'generate range again');
is($calls, 33, '$calls now 33');

is($cache, $r, 'cache same result');
is($calls, 33, 'but calls did not get called anymore');

is($range, $r, 'But $range increases again');
is($calls, 44, '$calls now 44');

is($cache, $r, 'check cache once again');
is($calls, 44, '$calls stay at 44');


#--- Test cache with sort

# sort is an expensive call. But still, in normal operation on a sequence
# you expect that it always sorts again. Especially when it operates on
# mutable state. You want the latest updated data. But when this is not
# needed, you cache the result after a sort().

my @data = (3,10,67,123,21,2,6,8578,34);

# genereates a sequence from mutable data storage. when @data changes
# $sorted will see latest values, while the cached variant dont update anymore
my $sorted       = Seq->from_array(\@data)->sort(sub($x,$y) { $x <=> $y });
my $sorted_cache = $sorted->cache;

is($sorted,                 $sorted_cache,                'must be the same');
is($sorted->to_array,       [2,3,6,10,21,34,67,123,8578], 'check sorted');
is($sorted_cache->to_array, [2,3,6,10,21,34,67,123,8578], 'check sorted cache');

# add value to mutable array
push @data, 42;

is($sorted->to_array,       [2,3,6,10,21,34,42,67,123,8578], 'sorted sees updated value');
is($sorted_cache->to_array, [2,3,6,10,21,34,67,123,8578],    'but sorted_cache stays the same');

done_testing;
