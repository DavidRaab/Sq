#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

# Fibonacci numbers
{
    my $fib =
        Array->concat(
            Array->new(1,1),
            Array->unfold([1,1], sub($state) {
                my $next = fst($state) + snd($state);
                if ( $next < 100_000 ) {
                    return $next, [snd($state),$next];
                }
                return undef;
            })
        );

    is(
        $fib,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946,17711,28657,46368,75025],
        'all fib numbers in $fib');

    is(
        $fib->take(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');

    # when it's important that you get a new array then use ->take(20) instead of
    # ->to_array(). to_array() exists because of API compatibility and can return
    # the same array again in certain cases.
    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

# Same Fibonacci as above but unfold does not create a new arrayref on every
# iteration. It changes the $state instead. This way less garbage is created
# and could be potential a little bit faster. But it envolves writing more code.
{
    my $fib =
        Array->concat(
            Array->new(1,1),
            Array->unfold([1,1], sub($state) {
                # uses $state/Array as a Queue, pushes next value onto the end and
                # removes first entry in array
                push  @$state, Array::sum($state);
                shift @$state;
                return $state->[1], $state if $state->[1] < 10_000;
                return undef;
            })
        );

    is(
        $fib->take(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

# You also can use a hash as a state.
{
    my $fib =
        Array->concat(
            Array->new(1,1),
            Array->unfold({x => 1, y => 1}, sub($state) {
                my $next = $state->{x} + $state->{y};
                $state->{x} = $state->{y};
                $state->{y} = $next;
                return $next, $state if $next < 10_000;
                return undef;
            })
        );

    is(
        $fib->take(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

done_testing;