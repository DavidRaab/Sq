#!perl
use 5.036;
use Sq;
use Sq::Test;
use Sq::Sig;

#---------- Check if cache really caches the iterator

# Test cache by making a side-effect and increase $calls. iterating from
# $fromto now must increase $calls. But iterating from $cache must not.
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

is($calls,  0, '$calls at 0 because cache only init sequence');
is($cache, $r, 'populate cache');
is($calls, 11, '$calls now 11');

is($cache, $r, 'run $cache again');
is($calls, 11, '$calls should still be 11');

is($range, $r, 'calling $range increases $calls');
is($calls, 22, '$calls now 22');

is($cache, $r, 'comparing $cache again');
is($calls, 22, 'but $calls did not increase');

is($range, $r, 'But $range increases again');
is($calls, 33, '$calls now 33');

is($cache, $r, 'check cache once again');
is($calls, 33, '$calls stay at 33');


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


# Another cache test
{
    # I create one cache, and then take the first (x) element from it. I store
    # again how often the internal iterator was called and it should only increase
    # when the cached version needs to read from its iterator

    my $calls = 0;
    my $incr  = Seq->from_sub(sub {
        my $current = 0;
        return sub {
            if ( $current < 10 ) {
                $calls++;
                return $current++;
            }
            return undef;
        }
    });
    my $cache = $incr->cache;

    is($calls,  0, 'not yet run');

    is($cache->take(1), seq { 0 }, 'take 1');
    is($calls,  1, '$calls at one');

    is($cache->take(1), seq { 0 }, 'take 1');
    is($calls,  1, 'still at one');

    is($cache->take(2), seq { 0,1 }, 'take 2');
    is($calls,  2, '$calls at 2');

    is($cache->take(2), seq { 0,1 }, 'take 2');
    is($calls,  2, '$calls at 2');

    is($cache->take(5), seq { 0,1,2,3,4 }, 'take 5');
    is($calls,  5, '$calls at 5');

    is($cache->take(3), seq { 0,1,2 }, 'take 3');
    is($calls,  5, '$calls at 5');

    is($cache->take(8), seq { 0..7 }, 'take 8');
    is($calls,  8, '$calls at 8');

    is($cache->take(2), seq { 0,1 }, 'take 2');
    is($calls,  8, '$calls at 8');

    is($cache, seq { 0..9 }, 'full compare');
    is($calls,  10, '$calls at 10');

    is($cache, seq { 0..9 }, 'full compare again');
    is($calls,  10, '$calls at 10');
}

# fibonacci test
{
    my $calls = 0;
    # a possible infinite sequence
    my $fib = Seq->concat(
        seq { 1,1 },
        Seq->unfold([1,1], sub($state) {
            $calls++;
            my $next = $state->[0] + $state->[1];
            shift @$state;
            push  @$state, $next;
            return $next, $state;
        }),
    );

    # cache it
    my $cache = $fib->cache;

    is($calls, 0, 'not yet runned');
    is(
        $cache->take(10),
        seq { 1, 1, 2, 3, 5, 8, 13, 21, 34, 55 },
        'first 10 fibs');
    is($calls, (10-2), '8 calls');
    is(
        $cache->take(80),
        seq {
            1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987,
            1597, 2584, 4181, 6765, 10946, 17711, 28657, 46368, 75025,
            121393, 196418, 317811, 514229, 832040, 1346269, 2178309, 3524578,
            5702887, 9227465, 14930352, 24157817, 39088169, 63245986, 102334155,
            165580141, 267914296, 433494437, 701408733, 1134903170, 1836311903,
            2971215073, 4807526976, 7778742049, 12586269025, 20365011074,
            32951280099, 53316291173, 86267571272, 139583862445, 225851433717,
            365435296162, 591286729879, 956722026041, 1548008755920, 2504730781961,
            4052739537881, 6557470319842, 10610209857723, 17167680177565, 27777890035288,
            44945570212853, 72723460248141, 117669030460994, 190392490709135,
            308061521170129, 498454011879264, 806515533049393, 1304969544928657,
            2111485077978050, 3416454622906707, 5527939700884757, 8944394323791464,
            14472334024676221, 23416728348467685,
        },
        'first 80 fibs');
    is($calls, (80-2), '78 calls');

    is(
        $cache->take(80),
        seq {
            1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987,
            1597, 2584, 4181, 6765, 10946, 17711, 28657, 46368, 75025,
            121393, 196418, 317811, 514229, 832040, 1346269, 2178309, 3524578,
            5702887, 9227465, 14930352, 24157817, 39088169, 63245986, 102334155,
            165580141, 267914296, 433494437, 701408733, 1134903170, 1836311903,
            2971215073, 4807526976, 7778742049, 12586269025, 20365011074,
            32951280099, 53316291173, 86267571272, 139583862445, 225851433717,
            365435296162, 591286729879, 956722026041, 1548008755920, 2504730781961,
            4052739537881, 6557470319842, 10610209857723, 17167680177565, 27777890035288,
            44945570212853, 72723460248141, 117669030460994, 190392490709135,
            308061521170129, 498454011879264, 806515533049393, 1304969544928657,
            2111485077978050, 3416454622906707, 5527939700884757, 8944394323791464,
            14472334024676221, 23416728348467685,
        },
        'first 80 fibs');
    is($calls, (80-2), '78 calls');
}

done_testing;
