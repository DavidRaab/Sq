#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

# Fibonacci numbers
{
    my $fib =
        Seq->concat(
            Seq->new(1,1),
            Seq->unfold([1,1], sub($state) {
                my $next = fst($state) + snd $state;
                return $next, [snd($state),$next];
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

# Another way of calculating fib
{
    my $fib =
        Seq->concat(
            seq { 1,1 },
            Seq->unfold([1,1], sub($state) {
                my $next = Array::sum($state);
                return $next, [$state->[1], $next];
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

# You also can use a hash as a state.
{
    my $fib =
        Seq->concat(
            seq { 1,1 },
            Seq->unfold({x => 1, y => 1}, sub($state) {
                my $next = $state->{x} + $state->{y};
                return $next, {x => $state->{y}, y => $next };
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

# Or probably most efficent is to use Seq->from_sub as this way we don't
# need to create a lot of arrays, we can use a queue instead.
{
    my $fib =
        Seq->concat(
            seq { 1,1 },
            Seq->from_sub(sub{
                # State of the sequence comes here
                my @queue = (1,1);

                # this function is executed every time you request a new value
                # from the sequence.
                return sub {
                    push @queue, ($queue[0] + $queue[1]);
                    shift @queue;
                    return $queue[1];
                }
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

done_testing;