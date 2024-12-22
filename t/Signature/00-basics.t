#!perl
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;
use Sq::Sig;
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
    qr/\AType Error/,
    'throws exception 1');

like(
    dies { add_point({}, $unit) },
    qr/\AType Error/,
    'throws exception 2');

like(
    dies { add_point({X => 1}, $unit) },
    qr/\AType Error/,
    'throws exception 3');

like(
    dies { add_point($unit, {X => 1}) },
    qr/\AType Error/,
    'throws exception 4');

like(
    dies { add_point($unit, $unit, $unit) },
    qr/Not correct size/,
    'too many arguments');

# expect a function that should add numbers but returns hash instead
sub add($x, $y) {
    return {foo => 1};
}
sig('main::add', t_int, t_int, t_int);

like(
    dies { add(1,3) },
    qr/\AType Error/,
    'check return value');

# test void
sub whatever() { return 1 }
sig('main::whatever', t_void);

like(
    dies { whatever() },
    qr/Not void/,
    'fails because returns something');


# Examples in README
sub what($int, $str, $array_of_nums) {
    return {};
}
sig('main::what', t_int, t_str, t_array(t_of t_num), t_hash);

like( dies { what("foo", "foo", [1,2,3]) }, qr/\AType Error:/, 'what fails 1'); # fails
like( dies { what(  123, "foo", ["foo"]) }, qr/\AType Error:/, 'what fails 2'); # fails
like( dies { what(  123,    [], [1,2,3]) }, qr/\AType Error:/, 'what fails 3'); # fails
like( dies { what(123.3, 123.3,      []) }, qr/\AType Error:/, 'what fails 4'); # fails

is( what(123,   123,      []), {}, 'what ok 1');
is( what(123, "foo",      []), {}, 'what ok 2');
is( what(123, "foo", [1,2,3]), {}, 'what ok 3');

done_testing;
