#!perl
use 5.036;
use List::Util qw(reduce);
use Seq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use DDP;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $id      = sub($x) { $x          };
my $add1    = sub($x) { $x + 1      };
my $double  = sub($x) { $x * 2      };
my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

my $fst     = sub($array) { $array->[0] };
my $snd     = sub($array) { $array->[1] };

#----------


# Fibonacci numbers
{
    my $fib =
        Seq->concat(
            Seq->wrap(1,1),
            Seq->unfold([1,1], sub($state) {
                my $next = $state->[0] + $state->[1];
                return $next, [$state->[1],$next];
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

# Same Fibonacci as above but unfold does not create a new arrayref on every
# iteration. It changes the $state instead. This way less garbage is created
# and could be potential a little bit faster. But it envolves writing more code.
{
    my $fib =
        Seq->concat(
            Seq->wrap(1,1),
            Seq->unfold([1,1], sub($state) {
                my $next = $state->[0] + $state->[1];
                $state->[0] = $state->[1];
                $state->[1] = $next;
                return $next, $state;
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

# You also can use a hash as a state.
{
    my $fib =
        Seq->concat(
            Seq->wrap(1,1),
            Seq->unfold({x => 1, y => 1}, sub($state) {
                my $next = $state->{x} + $state->{y};
                $state->{x} = $state->{y};
                $state->{y} = $next;
                return $next, $state;
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers');
}

done_testing;