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


done_testing;
