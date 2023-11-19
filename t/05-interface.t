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

# OO and functional interface -- both work

# chained
is(
    Seq
    ->wrap(1,2,3)
    ->append(Seq->wrap(4,5,6))
    ->to_array,

    [1..6],
    'append with chaining');

# nested
is(
    Seq::to_array(
        Seq::append(
            Seq->wrap(1,2,3),
            Seq->wrap(4,5,6),
        )
    ),

    [1..6],
    'append as function');

# chained vs nested
is(
    Seq::to_array(
        Seq::append(
            Seq->range(1,5),
            Seq->range(5,1),
        )
    ),

    Seq
    ->range(1,5)
    ->append(Seq->range(5,1))
    ->to_array,

    'chaining vs nesting');

# another chained version
is(
    Seq::to_array(
        Seq::append(
            Seq->range(1,5),
            Seq->range(5,1),
        )
    ),

    Seq->empty
    ->append(Seq->range(1,5))
    ->append(Seq->range(5,1))
    ->to_array,

    'chaining and starting with empty');

done_testing;
