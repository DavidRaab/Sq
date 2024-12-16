#!perl
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

my $is_point = t_hash(t_keys(
    X => t_num,
    Y => t_num,
));

sub add_point($p1, $p2) {
    no warnings; # only for testing to surpress warnings
    return {
        X => $p1->{X} + $p2->{X},
        Y => $p1->{Y} + $p2->{Y},
    }
}

my $unit = { X => 1, Y => 1 };
is(
    add_point($unit, $unit),
    {X => 2, Y => 2},
    'add_point');

is(
    add_point($unit, {}),
    {X => 1, Y => 1},
    'executes but would print warnings');

# Add signature to 'add_point'
sig('main::add_point' => $is_point, $is_point, $is_point);

is(add_point($unit, $unit), {X => 2, Y => 2}, 'still works');

like(
    dies { add_point($unit, {}) },
    qr/\AType check failed/,
    'throws exception 1');

like(
    dies { add_point({}, $unit) },
    qr/\AType check failed/,
    'throws exception 2');

like(
    dies { add_point({X => 1}, $unit) },
    qr/\AType check failed/,
    'throws exception 3');

like(
    dies { add_point($unit, {X => 1}) },
    qr/\AType check failed/,
    'throws exception 4');

like(
    dies { add_point($unit, $unit, $unit) },
    qr/Arity mismatch/,
    'too many arguments');

# expect a function that should add numbers but returns hash instead
sub add($x, $y) {
    return {foo => 1};
}
sig('main::add', t_int, t_int, t_int);

like(
    dies { add(1,3) },
    qr/\AType check failed/,
    'check return value');

# test void
sub whatever() { return 1 }
sig('main::whatever', t_void);

like(
    dies { whatever() },
    qr/Not void/,
    'fails because returns something');

done_testing;
