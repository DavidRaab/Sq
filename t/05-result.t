#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

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

    check_isa($x, 'Result', '$x is result');
    check_isa($y, 'Result', '$y is result');
    check_isa($z, 'Result', '$z is result');

     ok($x->is_ok,  'ok value 1');
     ok($x,         'ok value 2');  # ok understands Ok()
     ok($y->is_ok,  'err value 1'); # in a result `undef` can be part of Ok()
     ok($z->is_err, 'err value 2');
    nok($z,         'err value 3'); # nok understand result

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

        is(is_result($value),      $is_result, "$idx functional-style is_result ");
        is(Result::is_ok($value),      $is_ok, "$idx functional-style is_ok");
        is(Result::is_err($value),    $is_err, "$idx functional-style is_err");

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

    is(is_result(Ok(1)),  1, 'is_result 1');
    is(is_result(Err(1)), 1, 'is_result 2');
    is(is_result(""),     0, 'is_result 3');
    is(is_result([]),     0, 'is_result 4');

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
        state $content = sq {
            '/'             => Ok  'root',
            '/etc/passwd'   => Err 'invalid access',
            '/var/log/text' => Ok  'some text',
        };
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


# Extracting values
{
    my $a = Ok  'Hello';
    my $b = Ok  10;
    my $c = Err -1;

    is($a->or('what'), 'Hello', '$a->or');
    is($b->or(0),      10,      '$b->or');
    is($c->or(10),     10,      '$c->or');

    is($a->or_with(sub{ 10 }), 'Hello', '$a->or_with');
    is($c->or_with(sub{ 10 }),      10, '$c->or_with');

    # fold
    {
        my $add = sub($x, $state) { $x + $state };
        is(Err(0)->fold(100, $add),  100, 'fold 1');
        is(Ok(0) ->fold(100, $add),  100, 'fold 2');
        is(Ok(10)->fold(100, $add),  110, 'fold 3');

        is(
            Result::fold(Ok(10), 3, sub($x,$y){ $x - $y }),
            7,
            'functional-style');
    }
}

# or_else
{
    is(Ok("Hello")->or_else(Ok 10), Ok("Hello"), 'or_else 1');
    is(Err(0)     ->or_else(Ok 10),      Ok(10), 'or_else 2');

    my $calls = 0;
    my $next  = sub { Ok(++$calls) };

    is(Ok("World")->or_else_with($next), Ok("World"), 'or_else_with 1');
    is(Err(0)     ->or_else_with($next),       Ok(1), 'or_else_with 2');
    is(Ok(10)     ->or_else_with($next),      Ok(10), 'or_else_with 3');
    is(Err(0)     ->or_else_with($next),       Ok(2), 'or_else_with 4');
}

# map
{
    my $incr = sub($x) { $x + 1 };
    my $dbl  = sub($x) { $x * 2 };

    is(Ok(10)->map($incr), Ok(11), 'map incr');
    is(Err(0)->map($dbl),  Err(0), 'map on None');
    is(Ok(10)->map($dbl),  Ok(20), 'map with dbl');

    my $add = sub($x,$y) { $x + $y };

    # map2
    is(Result::map2(Ok(10),     Ok(3), $add), Ok(13), 'map2 - 1');
    is(Result::map2(Ok(10),    Err(0), $add), Err(0), 'map2 - 2');
    is(Result::map2(Err(0),     Ok(3), $add), Err(0), 'map2 - 3');

    is(Ok(10)->map2(Ok(3), $add), Ok(13), 'map2 - 6');

    # map3
    my $add3 = sub($a,$b,$c) { $a + $b + $c };
    is(Result::map3( Ok(1),  Ok(2),  Ok(3), $add3),  Ok(6), 'map3');
    is(Result::map3(Err(0),  Ok(2),  Ok(3), $add3), Err(0), 'map3 err 1');
    is(Result::map3( Ok(1), Err(0),  Ok(3), $add3), Err(0), 'map3 err 2');
    is(Result::map3( Ok(1),  Ok(2), Err(0), $add3), Err(0), 'map3 err 3');

    # map4
    my $add4 = sub($a,$b,$c,$d) { $a + $b + $c + $d };
    is(Result::map4(Ok(1),   Ok(2),  Ok(3),  Ok(4), $add4), Ok(10), 'map4');
    is(Result::map4(Err(0),  Ok(2),  Ok(3),  Ok(4), $add4), Err(0), 'map4 err 0');
    is(Result::map4( Ok(1), Err(0),  Ok(3),  Ok(4), $add4), Err(0), 'map4 err 1');
    is(Result::map4( Ok(1),  Ok(2), Err(0),  Ok(4), $add4), Err(0), 'map4 err 2');
    is(Result::map4( Ok(1),  Ok(2),  Ok(3), Err(0), $add4), Err(0), 'map4 err 3');

    # map2 without parens
    my $opt_x = Result::map2 Ok(10), Ok(3), $add;
    is($opt_x, Ok(13), 'map2 without parens');
}


# all_ok & keep_pl
{
    my $oks = sq [
        Ok(10),
        Ok( 3),
        Ok(42),
        Ok("Hello"),
        Ok("World"),
    ];

    is(Array::all_ok($oks), Some([10,3,42,"Hello", "World"]), 'all_ok');
    is(Array::keep_ok($oks),      [10,3,42,"Hello", "World"], 'keep_ok');
    is(
        Array::all_ok(
            $oks->map(sub($result) {
                $result->map(sub($x) {
                    if ( is_num($x) ) { $x * 2  } # double numbers
                    else              { $x . $x } # double strings
                })
            })
        ),
        Some([20, 6, 84, "HelloHello", "WorldWorld"]),
        'all_ok with map'
    );

    ### tests with invalid

    my $mixed = sq [
        Ok (10),
        Err(10),
        Ok ( 3),
        Err(10),
        Ok (42),
    ];

    is($mixed->all_ok,        None, 'all_ok with Err 1');
    is(Array::all_ok($mixed), None, 'all_ok with Err 2');
    is($mixed->keep_ok,  [10,3,42], 'keep_ok with None');

    is(
        Array::keep_ok(
            $mixed->map(sub($result) {
                $result->map(sub($x) { $x * 2 })
            })
        ),
        [20,6,84],
        'keep_ok containing array::map');
}

# all_ok_by
{
    my $is_num   = sub($x) { is_num($x) ? Ok($x) : Err("Not Number") };
    my $str_nums = sq ["23", "100", "16"];

    is(
        $str_nums->map($is_num)->all_ok,
        Some([23, 100, 16]),
        'all_ok on array->map');

    # with all_valid_by we can do the same in one operation
    is(
        $str_nums->all_ok_by($is_num),
        Some([23, 100, 16]),
        'all_ok_by');

    is(
        Array::all_ok_by([qw/1 2 3/], $is_num),
        Some([1,2,3]),
        'all_ok_by with array 1');

    is(
        Array::all_ok_by([qw/1 2 3 foo/], $is_num),
        None,
        'all_ok_by with array 2');
}

# keep_some_by
{
    my $is_num   = sub($x) { is_num($x) ? Ok($x) : Err("Not a number") };
    my $str_nums = sq [ "23", "foo", "100g", "16"];

    # sometimes we want to map a list with an optional function that turns
    # a value into an optional value. this results into a list of optionals,
    # then with `keep_some` we can only get the Some values and drop
    # the None.
    is($str_nums->map($is_num)->keep_ok, [23, 16], 'keep_ok on array->map');

    # with keep_some_by we can do the same in one operation
    is($str_nums->keep_ok_by($is_num), [23, 16], 'keep_ok_by');
}

{
    is(Array::keep_ok([Ok(1), Ok(2),   Ok(3)]),      [1,2,3], 'keep_ok 1');
    is(Array::keep_ok([Ok(1), Ok(2), Err("")]),        [1,2], 'keep_ok 2');
    is(Array::keep_ok([Err("")]),                         [], 'keep_ok 3');
    is(Array::keep_ok([]),                                [], 'keep_ok 4');
    is(Array::all_ok ([Ok(1), Ok(2), Ok(3)]),  Some([1,2,3]), 'all_ok 1');
    is(Array::all_ok ([Ok(1), Ok(2), Err("")]),         None, 'all_ok 2');
    is(Array::all_ok ([Err("")]),                       None, 'all_ok 3');
    is(Array::all_ok ([]),                          Some([]), 'all_ok 4');
}

done_testing;
