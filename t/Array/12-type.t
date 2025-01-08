#!perl
use 5.036;
use Sq;
use Sq::Parser -sig => 1;
use Sq::Test;
use Sq::Sig;

# hex and time parser
my $hex  = p_matchf(qr/0x([0-9a-zA-Z]+)/, sub($hex) { hex $hex });
my $time = p_matchf(qr/(\d\d?):(\d\d?)/,  sub($hour,$min) {
    $hour < 24 && $min < 60 ? ($hour,$min) : ();
});

my $data = sq ["0xff", "00:00", "0x00", "23:40", "0xaf", "12:12", "99:99"];

# But consider that type only checks for success of a parser, it doesn't use
# it results.
is(
    $data->keep_type(type [parser => $hex]),
    ["0xff", "0x00", "0xaf"],
    'keep_type with hex');

is(
    $data->keep_type(type [parser => $time]),
    ["00:00", "23:40", "12:12"],
    'keep_type with time');

# but we can first run the parser against any string.
# TODO: Add a shortcut for this.

is(
    $data->map(sub($str) { p_run $hex, $str })->keep_some->merge,
    [255, 0, 175],
    'parse hex and keep');

is(
    $data->map(sub($str) { p_run $time, $str })->keep_some,
    [ [0,0], [23,40], [12,12] ],
    'parse time and keep');

is(
    $data->map(sub($str) { p_run $time, $str })->keep_some,
    $data->keep_some_by(sub($str) { p_run $time, $str }),
    'keep_some_by same as map->keep_some');

# another array of data
my $data2 = sq [
    { X => 3, Y => 7},
    { id => 1, name => "Anny"  },
    { X => 2, Y => 6},
    { id => 2, name => "Sola"  },
    { id => 3, name => "Lilly", X => 10, Y => 3 },
    { X => 1, Y => 5},
    { id => 4, name => "Candy" },
    { X => 4, Y => 8},
];

is(
    $data2->keep_type(type
        [hash => [keys =>
            id   => ['int'],
            name => ['str'],
        ]]
    ),
    [
        { id => 1, name => "Anny"  },
        { id => 2, name => "Sola"  },
        { id => 3, name => "Lilly", X => 10, Y => 3 },
        { id => 4, name => "Candy" },
    ],
    'only names');

is(
    $data2->keep_type(type
        [hash => [keys =>
            X => ['int'],
            Y => ['str'],
        ]]
    ),
    [
        { X => 3, Y => 7},
        { X => 2, Y => 6},
        { id => 3, name => "Lilly", X => 10, Y => 3 },
        { X => 1, Y => 5},
        { X => 4, Y => 8},
    ],
    'only positions');

done_testing;
