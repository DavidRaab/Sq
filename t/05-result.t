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
    is(Ok(10) ->map($add1), Ok(11),  'map on Ok');
    is(Err(10)->map($add1), Err(10), 'map on Err');

    is(Ok(10) ->mapErr($add1), Ok(10),  'mapErr on Ok');
        is(Err(10)->mapErr($add1), Err(11), 'mapErr on Err');
}

# is_result / is_ok / is_err
{

    is(Result::is_result(Ok(1)),  1, 'is_result 1');
    is(Result::is_result(Err(1)), 1, 'is_result 2');
    is(Result::is_result(""),     0, 'is_result 3');
    is(Result::is_result([]),     0, 'is_result 4');

    is(Result::is_ok(Ok(10)),   1, 'is_ok 1');
    is(Result::is_ok(Err(10)),  0, 'is_ok 2');
    is(Result::is_ok(""),       0, 'is_ok 3');
    is(Result::is_ok([]),       0, 'is_ok 4');
    is(Ok(10) ->is_ok,          1, 'is_ok 5');
    is(Err(10)->is_ok,          0, 'is_ok 6');

    is(Result::is_err(Ok(10)),  0, 'is_err 1');
    is(Result::is_err(Err(10)), 1, 'is_err 2');
    is(Result::is_err(""),      0, 'is_err 3');
    is(Result::is_err([]),      0, 'is_err 4');
    is(Ok(10) ->is_err,         0, 'is_err 5');
    is(Err(10)->is_err,         1, 'is_err 6');
}

# match
{
    my $fetch = sub($path) {
        state $content = Hash->new(
            '/'             => Ok  'root',
            '/etc/passwd'   => Err 'invalid access',
            '/var/log/text' => Ok  'some text',
        );
        return $content->get($path)->or(Err '404');
    };

    is($fetch->('/'),              Ok('root'),            'fetching /');
    is($fetch->('/etc/passwd'),    Err('invalid access'), 'fetching /etc/passwd');
    is($fetch->('/var/log/text'),  Ok('some text'),       'fetching /var/log/text');
    is($fetch->('/home/Foo/text'), Err('404'),            'fetching /home/Foo/text');

    my @fetches = (
        $fetch->('/'),             $fetch->('/etc/passwd'),
        $fetch->('/var/log/text'), $fetch->('/home/Foo/text'),
    );

    my $oks  = 0;
    my $errs = 0;
    for my $fetch ( @fetches ) {
        $fetch->match(
            Ok  => sub($str) { $oks++ },
            Err => sub($str) { $errs++ },
        );
    }

    is($oks,  2, '2 oks');
    is($errs, 2, '2 errs');
}

done_testing;
