#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;

#----------

# basic loading and initialization
{
    my $x = Some(10);
    my $y = Some(undef);
    my $z = None;

    is($x, check_isa('Option'), '$x is option');
    is($y, check_isa('Option'), '$x is option');
    is($z, check_isa('Option'), '$x is option');

    ok($x->is_some, 'some value');
    ok($y->is_none, 'none value');
    ok($z->is_none, 'none value');
}

# Pattern Matching
{
    my @tests = (
        [None,              0],
        [Some(undef),       0],
        [Some("Hello"),     1],
        [Some(10),          1],
        [Some(0),           1],
        [Some(""),          1],
        [Some("0E0"),       1],
        [Some([]),          1],
        [Some({}),          1],
        [Some(None),        1],
        [Some(Some(1)),     1],
        [Some(Some(undef)), 1],
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
        my $add = sub($state, $x) { $state + $x };
        is(None       ->fold(100, $add),  100, 'fold 1');
        is(Some(undef)->fold(100, $add),  100, 'fold 2');
        is(Some(0)    ->fold(100, $add),  100, 'fold 3');
        is(Some(10)   ->fold(100, $add),  110, 'fold 4');

        is(
            Option::fold(Some(10), 3, sub($x,$y){ $x - $y }),
            -7,
            'functional-style');
    }
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

    # map3
    is(
        Option::map3(Some(1), Some(2), Some(3), sub($a,$b,$c) { $a + $b + $c }),
        Some(6),
        'map3');

    # map4
    is(
        Option::map4(Some(1), Some(2), Some(3), Some(4), sub($a,$b,$c,$d) { $a + $b + $c + $d }),
        Some(10),
        'map4');
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

done_testing;
