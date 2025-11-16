#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Type;
use Sq::Signature;
use Sq::Test;

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

dies { add_point($unit, {})           } qr/\Amain::/, 'throws exception 1';
dies { add_point({}, $unit)           } qr/\Amain::/, 'throws exception 2';
dies { add_point({X => 1}, $unit)     } qr/\Amain::/, 'throws exception 3';
dies { add_point($unit, {X => 1})     } qr/\Amain::/, 'throws exception 4';
dies { add_point($unit, $unit, $unit) } qr/\Amain::/, 'too many arguments';

# expect a function that should add numbers but returns hash instead
sub add($x, $y) {
    return {foo => 1};
}
sig('main::add', t_int, t_int, t_int);

dies { add(1,3) }
    qr/\Amain::/,
    'check return value';

# test void
sub whatever() { return 1 }
sig('main::whatever', t_void);

dies { whatever() }
    qr/Not void/,
    'fails because returns something';

# Examples in README
sub what($int, $str, $array_of_nums) {
    return {};
}
sig('main::what', t_int, t_str, t_array(t_of t_num), t_hash);

dies { sig('main::what', t_int, t_void) }
    qr/\Amain::what: Signature already added/,
    'adding signature again fails';

dies { what("foo", "foo", [1,2,3]) } qr/\Amain::what/, 'what fails 1'; # fails
dies { what(  123, "foo", ["foo"]) } qr/\Amain::what/, 'what fails 2'; # fails
dies { what(  123,    [], [1,2,3]) } qr/\Amain::what/, 'what fails 3'; # fails
dies { what(123.3, 123.3,      []) } qr/\Amain::what/, 'what fails 4'; # fails

is( what(123,   123,      []), {}, 'what ok 1');
is( what(123, "foo",      []), {}, 'what ok 2');
is( what(123, "foo", [1,2,3]), {}, 'what ok 3');

# check static implementation
{
    my $is_prime = Sq->math->is_prime;

    dies { $is_prime->("foo") }
    qr/\ASq::Math::is_prime:/,
    'type-check on returning function';
}


# check if sigt() with multiple IN => OUT correctly throws errors when
# the types don't match.
sub mapping1($in) {
    if    ( is_num($in) ) { return [] }
    elsif ( is_str($in) ) { return {} }
}

# first a "correct" version check that should not fail
sigt('main::mapping1',
    t_tuple(t_num), t_array,
    t_tuple(t_str), t_hash,
);

is(mapping1(123),   [], 'mapping1(123) should not fail');
is(mapping1("foo"), {}, 'mapping1("foo") should not fail');


# now a version that should fail
sub mapping2($in) {
    if    ( is_num($in) ) { return [] }
    elsif ( is_str($in) ) { return {} }
}

# first a "correct" version check that should not fail
sigt('main::mapping2',
    t_tuple(t_num), t_hash,
    t_tuple(t_str), t_array,
);

dies { mapping2(123)   } qr/\Amain::mapping2:/, 'mapping2(123) should fail';
dies { mapping2("foo") } qr/\Amain::mapping2:/, 'mapping2("foo") should fail';

done_testing;
