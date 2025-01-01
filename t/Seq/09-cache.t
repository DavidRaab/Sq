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

# Previously calling sort(), it returned a Sequence again. I tested
# that when calling multiple times sort() you always get the updated
# version. This was a test if sort itself keeps the current state of
# when sort() was called. Now it returns an Array and this becomes obvious.
# Don't really need to test that. Now it becomes obvious that calling sort()
# must fetch all elements from a sequence to work. Also calling
# "->cache" on the result of sort didn't really made a sense. Now this fails
# because an Array is already a "cache" and this method doesn't make sense to
# call there.
# TODO: But i could add it to Array as a noop?

my @data = (3,10,67,123,21,2,6,8578,34);
# this generates a sequence over mutable state. Because we still can acces
# @data and change it. And Seq->from_array just keeps a reference, it allows
# changing @data and a sequence will always get updated values.
# This is officially supported as an "advanced" feature.
my $data = Seq->from_array(\@data);

# genereates a sequence from mutable data storage. when @data changes
# $sorted will see latest values, while the cached variant dont update anymore
my $sorted = $data->sort(by_num);

is($sorted, [2,3,6,10,21,34,67,123,8578], 'check sorted');

# add value to mutable array
push @data, 42;

is(
    $sorted,
    [2,3,6,10,21,34,67,123,8578],
    'sorted stays the same');
is(
    $data->sort(by_num),
    [2,3,6,10,21,34,42,67,123,8578],
    'but calling sort again sees new value');

done_testing;
