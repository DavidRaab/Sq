#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

my $time = qr/
\A
    (\d\d\d\d) - (\d\d) - (\d\d)  # Date
T                                 # T
    (\d\d) : (\d\d) : (\d\d)      # Time
\z/xms;

# rx
{
    my $lines = sq [
        '2023-11-25T15:10:00',
        '2023-11-20T10:05:29',
        'xxxx-xx-xxT00:00:00',
        '1900-01-01T00:00:01',
        '12345678901234567890',
    ];

    is(
        $lines->rx($time),
        [
            '2023-11-25T15:10:00',
            '2023-11-20T10:05:29',
            '1900-01-01T00:00:01',
        ],
        'rx');
}

# rxm
{
    my $lines = sq [
        '2023-11-25T15:10:00',
        '2023-11-20T10:05:29',
        'xxxx-xx-xxT00:00:00',
        '1900-01-01T00:00:01',
        '12345678901234567890',
    ];

    my $matches = $lines->rxm($time)->map(call 'slice', 2,1,0,3,4,5);

    is(
        $matches,
        [
            [qw/25 11 2023 15 10 00/],
            [qw/20 11 2023 10 05 29/],
            [qw/01 01 1900 00 00 01/],
        ],
        'rxm');

    is(
        $lines->rxm(qr/\A
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
            (.)(.)(.)(.)
        \z/xms),
        [
            [1 .. 9, 0, 1 .. 9, 0],
        ],
        'check 20 matches');
}

# rxs
{
    my $stuff = sq [
        "  one   two    three",
        " with     whitespace    ",
        "test",
    ];

    is(
        $stuff
        ->rxs(qr/\A\s+/, sub { ''  }) # remove leading ws
        ->rxs(qr/\s+\z/, sub { ''  }) # remove trailing ws
        ->rxs(qr/\s+/,   sub { ' ' }), # replace multiple ws with single one
        [
            "one two    three",
            "with whitespace",
            "test",
        ],
        'rxs');

    is(
        $stuff
        ->rxs (qr/\A\s+/, sub { ''  })  # remove leading ws
        ->rxs (qr/\s+\z/, sub { ''  })  # remove trailing ws
        ->rxsg(qr/\s+/,   sub { ' ' }), # replace multiple ws with single one
        [
            "one two three",
            "with whitespace",
            "test",
        ],
        'rxs');
}

done_testing;
