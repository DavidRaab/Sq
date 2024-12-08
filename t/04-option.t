#!perl
use 5.036;
use Sq;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

#----------

# basic loading and initialization
{
    my $x = Some(10);
    my $y = Some(undef);
    my $z = None;

    is($x, check_isa('Option'), '$x is option');
    is($y, check_isa('Option'), '$y is option');
    is($z, check_isa('Option'), '$z is option');

    ok($x->is_some, 'some value');
    ok($y->is_none, 'none value');
    ok($z->is_none, 'none value');
}

# Pattern Matching
{
    my @tests = (
        [None,              0],
        [Some(undef),       0],
        [Some(None),        0],
        [Some(Some(undef)), 0],
        [Some(Some(None)),  0],
        [Some("Hello"),     1],
        [Some(10),          1],
        [Some(0),           1],
        [Some(""),          1],
        [Some("0E0"),       1],
        [Some([]),          1],
        [Some({}),          1],
        [Some(Some(1)),     1],
    );

    my $idx = 0;
    for my $test ( @tests ) {
        my $got      = $test->[0];
        my $expected = $test->[1];

        is(
            $got->match(
               Some => sub($value) { 1 },
               None => sub()       { 0 },
            ),
            $expected,
            (sprintf "match %d", $idx++));
    }
}

# Extracting values
{
    my $a = Some 'Hello';
    my $b = Some 10;
    my $c = None;

    is($a->or('what'), 'Hello', '$a->or');
    is($b->or(0),      10,      '$b->or');
    is($c->or(10),     10,      '$c->or');

    is($a->or_with(sub{ 10 }), 'Hello', '$a->or_with');
    is($c->or_with(sub{ 10 }),      10, '$c->or_with');

    # fold
    {
        my $add = sub($x, $state) { $x + $state };
        is(None       ->fold(100, $add),  100, 'fold 1');
        is(Some(undef)->fold(100, $add),  100, 'fold 2');
        is(Some(0)    ->fold(100, $add),  100, 'fold 3');
        is(Some(10)   ->fold(100, $add),  110, 'fold 4');

        is(
            Option::fold(Some(10), 3, sub($x,$y){ $x - $y }),
            7,
            'functional-style');
    }
}

# or_else
{
    is(Some("Hello")->or_else(Some 10), Some("Hello"), 'or_else 1');
    is(None         ->or_else(Some 10),      Some(10), 'or_else 2');
    is(Some(undef)  ->or_else(Some 10),      Some(10), 'or_else 3');

    my $calls = 0;
    my $next  = sub { Some(++$calls) };

    is(Some("World")->or_else_with($next), Some("World"), 'or_else_with 1');
    is(None         ->or_else_with($next),       Some(1), 'or_else_with 2');
    is(Some(10)     ->or_else_with($next),      Some(10), 'or_else_with 3');
    is(Some(undef)  ->or_else_with($next),       Some(2), 'or_else_with 4');
}

# bind
{
    my $parse_int = sub($str) {
        return $str =~ m/\A \s* (\d+) \s*\z/xms
             ? Some $1
             : None;
    };

    is($parse_int->("  19"), Some(19), 'parse 19');
    is($parse_int->("foo"),  None,     'parse foo');

    is(Option::bind(Some('101110'), $parse_int), Some(101110), 'functional style');
    is(Some("   19")->bind($parse_int),  Some(19), 'parse 19');
    is(Some("0")    ->bind($parse_int),   Some(0), 'parse 0');
    is(Some(" 0 ")  ->bind($parse_int),   Some(0), 'parse 0');
    is(Some("123\n")->bind($parse_int), Some(123), 'parse 123');
    is(Some("10 a") ->bind($parse_int),     None,  'parse 10 a');
    is(Some(undef)  ->bind($parse_int),     None,  'parse undef');
    is(None->bind($parse_int),              None,  'parse None');
    is(
        Some(5)->bind(sub($x) {
            $x > 0 && $x < 10 ? Some('yes') : None;
        }),
        Some('yes'),
        'bind with lambda');
}

# map
{
    my $incr = sub($x) { $x + 1 };
    my $dbl  = sub($x) { $x * 2 };

    is(Some(10)   ->map($incr), Some(11), 'map incr');
    is(Some(undef)->map($incr), None,     'map on undef');
    is(None       ->map($dbl),  None,     'map on None');
    is(Some(10)   ->map($dbl),  Some(20), 'map with dbl');

    my $add = sub($x,$y) { $x + $y };

    # map2
    is(Option::map2(Some(10),     Some(3), $add), Some(13), 'map2 - 1');
    is(Option::map2(Some(10),        None, $add),     None, 'map2 - 2');
    is(Option::map2(None,         Some(3), $add),     None, 'map2 - 3');
    is(Option::map2(Some(undef),  Some(3), $add),     None, 'map2 - 4');
    is(Option::map2(Some(10), Some(undef), $add),     None, 'map2 - 5');

    is(Some(10)->map2(Some(3), $add), Some(13), 'map2 - 6');

    # map3 - check None
    my $add3 = sub($a,$b,$c) { $a + $b + $c };
    is(Option::map3(Some(1), Some(2), Some(3), $add3), Some(6), 'map3');
    is(Option::map3(None,    Some(2), Some(3), $add3),    None, 'map3 err 0');
    is(Option::map3(Some(1), None,    Some(3), $add3),    None, 'map3 err 1');
    is(Option::map3(Some(1), Some(2), None,    $add3),    None, 'map3 err 2');

    # map4 - check None
    my $add4 = sub($a,$b,$c,$d) { $a + $b + $c + $d };
    is(Option::map4(Some(1), Some(2), Some(3), Some(4), $add4), Some(10), 'map4');
    is(Option::map4(None,    Some(2), Some(3), Some(4), $add4),     None, 'map4 err 0');
    is(Option::map4(Some(1), None,    Some(3), Some(4), $add4),     None, 'map4 err 1');
    is(Option::map4(Some(1), Some(2), None,    Some(4), $add4),     None, 'map4 err 2');
    is(Option::map4(Some(1), Some(2), Some(3), None,    $add4),     None, 'map4 err 3');

    # map2 without parens
    my $opt_x = Option::map2 Some(10), Some(3), $add;
    is($opt_x, Some(13), 'map2 without parens');
}

# validate
{
    my $between = sub($x,$y) {
        return sub($value) {
            return $value >= $x && $value <= $y ? 1 : 0;
        }
    };

    is(Some(-1)->validate($between->(0,10)),     None, '-1 in 0-10');
    is(Some(0) ->validate($between->(0,10)),  Some(0), '0 in 0-10');
    is(Some(5) ->validate($between->(0,10)),  Some(5), '5 in 0-10');
    is(Some(10)->validate($between->(0,10)), Some(10), '10 in 0-10');
    is(Some(11)->validate($between->(0,10)),     None, '11 in 0-10');

    my @tests = (
        [" foo",    None],
        [" 10 ",    None],
        [" 1",   Some(2)],
        [" 123 ",   None],
        ["0",    Some(0)],
        [" 5",  Some(10)],
    );

    my $idx = 0;
    for my $test ( @tests ) {
        my ($value, $expected) = @$test;

        is(
            Some($value)
            ->bind(sub($str) { $str =~ m/\A \s* (\d+) \s* \z/xms ? Some $1 : None })
            ->map( sub($x)   { $x * 2 })
            ->validate($between->(0,10)),

            $expected,
            "validate $idx");
        $idx++;
    }
}

# check
{
    is(Some(0)      ->check(\&is_num), 1, 'check some(0)');
    is(Some(1)      ->check(\&is_num), 1, 'check some(1)');
    is(Some("0E0")  ->check(\&is_num), 1, 'check 0E0');
    is(Some(" 100") ->check(\&is_num), 1, 'check " 100"');
    is(Some("0.00") ->check(\&is_num), 1, 'check decimal');
    is(Some("+0.00")->check(\&is_num), 1, 'check decimal with +');
    is(Some("f100") ->check(\&is_num), 0, 'check " 100"');
    is(Some(undef)  ->check(\&is_num), 0, 'check some(undef)');
    is(Some("")     ->check(\&is_num), 0, 'check some("")');
    is(None         ->check(\&is_num), 0, 'check None');
}

# flatten
{
    is(Some(Some(Some(10)))->flatten, Some(10), 'flatten 10');
    is(Some(Some(None))    ->flatten, None,     'flatten None');
    is(Some(None)          ->flatten, None,     'flatten None 2');
    is(Some(Some(undef))   ->flatten, None,     'flatten None 2');
    is(Some(Some(Some([])))->flatten, Some([]), 'Some array');
    is(Some(1)             ->flatten, Some(1),  'Some 1');
    is(None                ->flatten, None,     'None')
}

# flatten is now built-into Some()
{
    is(Some(Some(Some(10))), Some(10), 'flatten 10');
    is(Some(Some(None))    , None,     'flatten None');
    is(Some(None)          , None,     'flatten None 2');
    is(Some(Some(undef))   , None,     'flatten None 2');
    is(Some(Some(Some([]))), Some([]), 'Some array');
    is(Some(1)             , Some(1),  'Some 1');
    is(None                , None,     'None')
}

# iter
{
    my $sum = 0;

    Some(10)->iter(sub($x) { $sum += $x });
    None    ->iter(sub($x) { $sum += $x });
    Some(3) ->iter(sub($x) { $sum += $x });

    is($sum, 13, 'iter');
}

# to_array
{
    my $a = Some(1)->to_array;
    my $b = None->to_array;

    is($a, [1], '$a is [1]');
    is($b, [],  '$a is []');
    is($a, check_isa('Array'), '$a is blessed');
    is($b, check_isa('Array'), '$b is blessed');
}

# get
{
    is(Some(10)->get, 10, 'get');
    like(
        dies { None->get },
        qr/\ACannot extract value of None/,
        'get of None');
}

# all_valid & filter_valid
{
    my $valids = Array->new(
        Some(10),
        Some(3),
        Some(42),
        Some("Hello"),
        Some("World"),
    );

    is(
        Option->all_valid($valids),
        Some([10,3,42,"Hello", "World"]),
        'all_valid all Some');

    is(
        Option->filter_valid($valids),
        [10,3,42,"Hello", "World"],
        'filter_valid all Some');

    is(
        Option->all_valid(
            $valids->map(sub($opt) {
                $opt->map(sub($x) {
                    if ( is_num($x) ) { $x * 2  } # double numbers
                    else              { $x . $x } # double strings
                })
            })
        ),
        Some([20, 6, 84, "HelloHello", "WorldWorld"]),
        'all_valid with map'
    );

    ### tests with invalid

    my $invalid = Array->new(
        Some(10),
        None,
        Some(3),
        None,
        Some(42),
    );

    is(
        Option->all_valid($invalid),
        None,
        'all_valid with None');

    is(
        Option->filter_valid($invalid),
        [10,3,42],
        'filter_valid with None');

    is(
        Option->filter_valid(
            $invalid->map(sub($opt) {
                $opt->map(sub($x) { $x * 2 })
            })
        ),
        [20,6,84],
        'filter_valid containing array::map');
}

# all_valid_by
{
    my $is_num   = sub($x) { is_num($x) ? Some($x) : None };
    my $str_nums = Array->new("23", "100", "16");

    # sometimes we want to map a list with an optional function that turns
    # a value into an optional value. this results into a list of optionals,
    # then with `all_valid` we can check if all transformations returned
    # Some value.
    is(
        Option->all_valid($str_nums->map($is_num)),
        Some([23, 100, 16]),
        'all_valid on array->map');

    # with all_valid_by we can do the same in one operation
    is(
        Option->all_valid_by($str_nums, $is_num),
        Some([23, 100, 16]),
        'all_valid_by');

    is(
        Option->all_valid_by([qw/1 2 3/], $is_num),
        Some([1,2,3]),
        'all_valid_by with array 1');

    is(
        Option->all_valid_by([qw/1 2 3 foo/], $is_num),
        None,
        'all_valid_by with array 2');
}

# filter_valid_by
{
    my $is_num   = sub($x) { is_num($x) ? Some($x) : None };
    my $str_nums = Array->new("23", "foo", "100g", "16");

    # sometimes we want to map a list with an optional function that turns
    # a value into an optional value. this results into a list of optionals,
    # then with `filter_valid` we can only get the Some values and drop
    # the None.
    is(
        Option->filter_valid($str_nums->map($is_num)),
        [23, 16],
        'filter_valid on array->map');

    # with filter_valid_by we can do the same in one operation
    is(
        Option->filter_valid_by($str_nums, $is_num),
        [23, 16],
        'filter_valid_by');
}

{
    is(Option->filter_valid([Some(1), Some(2), Some(3)]),       [1,2,3], 'filter_valid 1');
    is(Option->filter_valid([Some(1), Some(2),    None]),         [1,2], 'filter_valid 2');
    is(Option->filter_valid([None]),                                 [], 'filter_valid 3');
    is(Option->filter_valid([]),                                     [], 'filter_valid 4');
    is(Option->all_valid   ([Some(1), Some(2), Some(3)]), Some([1,2,3]), 'all_valid 1');
    is(Option->all_valid   ([Some(1), Some(2),    None]),          None, 'all_valid 2');
    is(Option->all_valid   ([None]),                               None, 'all_valid 3');
    is(Option->all_valid   ([]),                               Some([]), 'all_valid 4');
}

{
    # an option generating function
    my $some_num = sub($str) { is_num($str) ? Some($str) : None };

    is(
        Option->filter_valid([map { $some_num->($_) } 1,2,3]),
        [1,2,3],
        'filter_valid_by 1');

    is(
        Option->filter_valid(Array->range(1,3)->map($some_num)),
        [1,2,3],
        'filter_valid_by 2');

    is(
        Option->filter_valid(Array->new(qw/1 foo 2/)->map($some_num)),
        [1,2],
        'filter_valid_by 3');

    is(
        Option->filter_valid_by([qw/1 foo 2/], $some_num),
        [1,2],
        'filter_valid_by 4');
}

# bind 1-4
{
    my $add1 = sub($x)          { Some($x+1)        };
    my $add2 = sub($x,$y)       { Some($x+$y)       };
    my $add3 = sub($x,$y,$z)    { Some($x+$y+$z)    };
    my $add4 = sub($x,$y,$z,$w) { Some($x+$y+$z+$w) };

    is(
        Option::bind(Some(1), $add1),
        Some(2),
        'bind1');

    is(
        Option::bind2(Some(1), Some(2), $add2),
        Some(3),
        'bind2');

    is(
        Option::bind3(Some(1), Some(2), Some(3), $add3),
        Some(6),
        'bind3');

    is(
        Option::bind4(Some(1), Some(2), Some(3), Some(4), $add4),
        Some(10),
        'bind4');
}

# functional-style - bind2
{
    # adds two numbers toegther when they are greater zero, otherwise returns None
    my $add_greater_0 = sub($a,$b) {
        if ( $a > 0 && $b > 0 ) {
            return Some($a + $b);
        }
        return None;
    };

    my @tests = (
        [Some( 1), Some( 2), Some( 3)],
        [Some( 1), Some( 1), Some( 2)],
        [Some(10), Some(10), Some(20)],
        [Some( 1),     None,    None],
        [None,      Some(1),    None],
        [None,         None,    None],
        [Some(0),   Some(1),    None],
        [Some(1),   Some(0),    None],
    );

    my $idx = 0;
    for my $test ( @tests ) {
        my ( $optA, $optB, $expected ) = @$test;
        is(
            Option::bind2($optA, $optB, $add_greater_0),
            $expected,
            "bind2 - functional - $idx");

        is(
            $optA->bind2($optB, $add_greater_0),
            $expected,
            "bind2 - method - $idx");

        $idx++;
    }
}

# bind3, bind4
{
    is(
        Option::bind3(Some(1), Some(2), Some(3), sub($x,$y,$z) { Some $x+$y+$z }),
        Some(6),
        'bind3');

    is(
        Option::bind4(Some(1), Some(2), Some(3), Some(4), sub($x,$y,$z,$w) { Some $x+$y+$z+$w }),
        Some(10),
        'bind4');
}

# map_v
{
    is(
        Option::map_v(Some(1), Some(2), Some(3), Some(4), Some(5), Some(6), Some(7), sub {
            my $sum = 0;
            for my $x ( @_ ) {
                $sum += $x;
            }
            return $sum;
        }),
        Some(28),
        'map_v');

    is(
        Some(1)->map_v(Some(2), Some(3), Some(4), Some(5), Some(6), Some(7), sub {
            my $sum = 0;
            for my $x ( @_ ) {
                $sum += $x;
            }
            return $sum;
        }),
        Some(28),
        'map_v as method');

    is(
        Option::map_v(Some(1), Some(2), sub($x,$y) { $x + $y }),
        Some(3),
        'map_v with two arguments');
}

# bind_v
{
    my $sum_under_100 = sub {
        my $sum = 0;
        for my $x ( @_ ) {
            $sum += $x;
        }
        return $sum <= 100
             ? Some($sum)
             : None;
    };

    is(
        Option::bind_v(Some(1), Some(2), Some(3), Some(4), Some(5), Some(6), Some(7), $sum_under_100),
        Some(28),
        'bind_v 1');

    is(
        Option::map_v(Some(1), Some(2), Some(3), Some(4), Some(5), Some(6), Some(7), $sum_under_100),
        Some(Some(28)),
        'map_v compared to bind_v');

    is(
        Option::bind_v(Some(10), Some(50), Some(50), $sum_under_100),
        None,
        'bind_v 2');
}

is(Option->is_opt(Some({})),    1, 'is_opt 1');
is(Option->is_opt(Some(1)),     1, 'is_opt 2');
is(Option->is_opt(None),        1, 'is_opt 3');
is(Option->is_opt(Some(undef)), 1, 'is_opt 4');
is(Option->is_opt(""),          0, 'is_opt 5');
is(Option->is_opt(0),           0, 'is_opt 6');
is(Option->is_opt([]),          0, 'is_opt 7');
is(Option->is_opt({}),          0, 'is_opt 8');

is(Option::is_some(Some({})),    1, 'is_some 1');
is(Option::is_some(Some(1)),     1, 'is_some 2');
is(Option::is_some(None),        0, 'is_some 3');
is(Option::is_some(Some(undef)), 0, 'is_some 4');
is(Option::is_some(""),          0, 'is_some 5');
is(Option::is_some(0),           0, 'is_some 6');
is(Option::is_some([]),          0, 'is_some 7');
is(Option::is_some({}),          0, 'is_some 8');

is(Option::is_none(Some({})),    0, 'is_none 1');
is(Option::is_none(Some(1)),     0, 'is_none 2');
is(Option::is_none(None),        1, 'is_none 3');
is(Option::is_none(Some(undef)), 1, 'is_none 4');

is(Option::is_none(""),          0, 'is_none 5');
is(Option::is_none(0),           0, 'is_none 6');
is(Option::is_none([]),          0, 'is_none 7');
is(Option::is_none({}),          0, 'is_none 8');

# Extract max of Array of Array
{
    my $data = Array->new(
        Array->range(10,100),
        Array->new(50, 10, 16),
        Array->new(100,1000),
        Array->empty,
        Array->new(1,2,3),
        Array->new(3,2,1),
    );

    my $maxs = $data->choose(sub($array) { $array->max });

    is(
        $maxs,
        [100, 50, 1000, 3, 3],
        'Option with Array::choose');
}

# returning option in Option::map
{
    my $x = Some(10)->map(sub($x) { Some($x+1) });
    is($x, Some(11) , 'Returning option in Option::map');
}

is(Some(1,2,3)->to_seq->sum, 6, 'to_seq');

done_testing;
