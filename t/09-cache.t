#!perl
use 5.036;
use Seq qw(id fst snd key assign);
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use DDP;

# Some values, functions, ... for testing
# my $range     = Seq->range(1, 10);
# my $rangeDesc = Seq->range(10, 1);

my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

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

is($calls,                11, '$calls at 11 because cache executed $range once');
is($range->to_array, [1..10], 'generate range');
is($calls,                22, '$calls now 22');
is($range->to_array, [1..10], 'generate range again');
is($calls,                33, '$calls now 33');

is($cache->to_array, [1..10], 'cache same result');
is($calls,                33, 'but calls did not get called anymore');

is($range->to_array, [1..10], 'But $range increases again');
is($calls,                44, '$calls now 44');

is($cache->to_array, [1..10], 'call cached range again');
is($calls,                44, '$calls stay at 44');

done_testing;
