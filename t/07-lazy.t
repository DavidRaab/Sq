#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

my $counter = 0;
my $time = lazy {
    $counter++;
    return localtime();
};

is($counter, 0, 'lazy not yet executed');

my $dt1 = $time->force;
is($counter, 1, 'lazy executed once');

# sleep 1
#
# this would be needed otherwise chances are high that when lazy is not
# correctly implemented and does not cache it's result. The same result
# is still returned as not enough time is passed for loacltime() to return
# something different.
#
# But i check through $counter if the function only executes once. Also
# the implementaion of lazy is so brainless that it's hard todo it wrong.

my $dt2 = $time->force;

is($counter, 1, '$counter stays at 1');
is($dt1, $dt2, '$dt1 same as $dt2');

done_testing;
