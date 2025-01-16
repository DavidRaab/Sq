#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

# OO and functional interface -- both work

# chained
is(
    Seq
    ->new(1,2,3)
    ->append(seq { 4,5,6 }),
    seq {1 .. 6},
    'append with chaining');

# nested
is(
    Seq::append(
        seq { 1,2,3 },
        seq { 4,5,6 },
    ),
    Seq->range(1,6),
    'append as function');

# chained vs nested
is(
    Seq::append(
        Seq->range(1,5),
        Seq->range(5,1),
    ),
    Seq
    ->range(1,5)
    ->append(Seq->range(5,1)),

    'chaining vs nesting');

# another chained version
is(
    Seq::append(
        Seq->range(1,5),
        Seq->range(5,1),
    ),

    Seq->empty
    ->append(Seq->range(1,5))
    ->append(Seq->range(5,1)),

    'chaining and starting with empty');

done_testing;
