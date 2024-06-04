#!perl
use 5.036;
use Sq;
use Scalar::Util qw(blessed);
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;

# Some values, functions, ... for testing
my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

# Helper functions
my $ishash = check_isa('Hash');
my $by_str = sub($x, $y) { $x cmp $y };
my $by_num = sub($x, $y) { $x <=> $y };

# new & bless
{
    for my $method ( qw/new bless/ ) {
        # passing a hashref
        my $d = Hash->$method({foo => 1, bar => 2});
        is($d, $ishash,              $method . ' $d is Hash');
        is($d, {foo => 1, bar => 2}, $method . ' content of $d');

        # blessing an existing ref
        my $d2 = {foo => 1, bar => 2};
        is(blessed($d2), undef, $method . ' not blessed');
        Hash->$method($d2);
        is($d2, $ishash,              $method . ' $d2 now blessed');
        is($d2, {foo => 1, bar => 2}, $method . ' content of $d2');

        # $method without arguments
        my $d3 = Hash->$method;
        $d3->add(foo => 1);
        is($d3, $ishash,    $method . ' $d3 is Hash');
        is($d3, {foo => 1}, $method . ' content of $d3');

        # $method with many arguments
        my $d4 = Hash->$method(foo => 1, bar => 2);
        is($d4, $ishash,              $method . ' $d4 is Hash');
        is($d4, {foo => 1, bar => 2}, $method . ' content of $d4');

        # one argument - not hashref
        like(
            dies { Hash->$method("foo") },
            qr/\AWhen Hash\-\>new/,
            'one argument not hashref dies'
        );

        # $method with uneven arguments
        like(
            dies { Hash->$method(foo => 1, "bar") },
            qr/\AWhen Hash\-\>new/,
            'uneven arguments dies'
        );
    }
}

# empty
{
    is(Hash->empty,   $ishash, 'empty');
    is(Hash->empty,        {}, 'empty hash');
    is(Hash->new, Hash->empty, 'new() same as empty');
}

# add
{
    my $h = Hash->empty;

    $h->add(foo => 1);
    is($h, {foo => 1}, 'content of $h 1');

    $h->add(bar => 2, baz => 3);
    is($h, {foo => 1, bar => 2, baz => 3}, 'content of $h 2');

    like(
        dies { $h->add(maz => 1, "raz") },
        qr/\AHash\-\>add/,
        'Hash->add with uneven arguments dies.'
    );

}

my $data = Hash->new({
    foo => 1,
    bar => 10,
    baz => 5,
});

# keys & values
is($data->keys->sort($by_str),   [qw/bar baz foo/], 'check keys');
is($data->values->sort($by_num), [1, 5, 10],        'check values');

# map
my $data2 = $data->map(sub($k,$v) {
    return ($k . 's'), $v * 2;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data2, {foos => 2, bars => 20, bazs => 10}, 'map');
is($data2, $ishash,                             '$data2 isa Hash');

# filter
my $data3 = $data->filter(sub($k,$v) {
    $k =~ m/\A b/xms ? 1 : 0;
});

is($data,  {foo  => 1, bar  => 10, baz  =>  5}, '$data stays the same');
is($data3, {bar => 10, baz => 5},               'filter');
is($data3, $ishash,                             '$data3 isa Hash');

# fold
is($data->fold(0, sub($state, $k, $v) { $state + $v }), 16, 'fold 1');
is($data->fold(1, sub($state, $k, $v) { $state + $v }), 17, 'fold 2');

is($data->count, 3, 'count');

done_testing;
