#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;

# Some values, functions, ... for testing
my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

# basic loading and initialization
{
    my $x = Ok(10);
    my $y = Ok(undef);
    my $z = Err(10);

    is($x, check_isa('Result'), '$x is result');
    is($y, check_isa('Result'), '$y is result');
    is($z, check_isa('Result'), '$z is result');

    ok($x->is_ok,  'ok value');
    ok($y->is_ok,  'err value');
    ok($z->is_err, 'err value');

    is($x, [1,10],    'internal structure check 1');
    is($y, [1,undef], 'internal structure check 2');
    is($z, [0,10],    'internal structure check 3');

    # check functional-style
    my @tests = (
        # $value,      $is_result, $is_ok, $is_err
        [Ok(10),          1, 1, 0],
        [[],              0, 0, 0],
        ["",              0, 0, 0],
        [Ok(Some(10)),    1, 1, 0],
        [Err("test"),     1, 0, 1],
        [Err(Ok("what")), 1, 0, 1],
    );

    my $idx = 0;
    for my $test ( @tests ) {
        my ($value, $is_result, $is_ok, $is_err) = @$test;

        is(Result::is_result($value), $is_result, "$idx functional-style is_result ");
        is(Result::is_ok($value),     $is_ok,     "$idx functional-style is_ok");
        is(Result::is_err($value),    $is_err,    "$idx functional-style is_err");

        $idx++;
    }
}

# Pattern Matching
{
    my @tests = (
        [Ok(undef),        1],
        [Ok("found"),      1],
        [Ok(Ok("hello")),  1],
        [Ok(Err("hello")), 1],
        [Ok([]),           1],
        [Err(undef),       0],
        [Err("not found"), 0],
        [Err(Ok("what")),  0],
        [Err(Err("test")), 0],
        [Err([]),          0],
    );

    my $idx = 0;
    for my $test ( @tests ) {
        my $got      = $test->[0];
        my $expected = $test->[1];

        is(
            $got->match(
               Ok  => sub($value) { 1 },
               Err => sub($value) { 0 },
            ),
            $expected,
            (sprintf "match check Ok/Err %d", $idx));

        is(
            $got->match(
                Ok  => sub($x) { $x },
                Err => sub($x) { $x },
            ),
            $got->[1],
            (sprintf "match check internal %d", $idx));

        $idx++;
    }
}

# map, mapErr
{
    is(Ok(10) ->map($add1), Ok(11),  'map');
    is(Err(10)->map($add1), Err(10), 'map on Err');
}

done_testing;
