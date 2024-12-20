#!perl
use 5.036;
use Sq;
use Sq::Type;
use Sq::Sig;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

my $album = sq {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
};

my $is_album_manual = sub ($album) {
    if ( ref $album eq 'Hash' ) {
        return 0 if !defined $album->{artist};
        return 0 if !defined $album->{title};
        if ( ref $album->{tracks} eq 'Array' ) {
            for my $track ( @{$album->{tracks}} ) {
                return 0 if !defined $track->{title};
                return 0 if !defined $track->{duration};
            }
            return 1;
        }
        return 0;
    }
    return 0;
};

my $is_album_type =
    t_hash(
        t_with_keys(qw/artist title tracks/),
        t_keys(
            artist => t_str,
            title  => t_str,
            tracks => t_array(t_of(t_hash(
                t_keys(
                    title    => t_str,
                    duration => t_int,
                )
            ))),
        )
    );

sub test($idx, $is_album) {
    is($is_album->($album), 1, "$idx: is an album");
    is($is_album->(sq {}),  0, "$idx: not an album");
    is($is_album->(sq{
        artist => 'yes',
        title  => 'no',
    }), 0, "$idx: missing tracks");
    is($is_album->(sq{
        artist => 'yes',
        title  => 'no',
        tracks => undef
    }), 0, "$idx: tracks undefined");
    is($is_album->(sq{
        artist => 'yes',
        title  => 'no',
        tracks => [],
    }), 1, "$idx: fine");
    is($is_album->(sq{
        artist => 'yes',
        title  => 'no',
        tracks => [
            {},
        ],
    }), 0, "$idx: empty track");
    is($is_album->(sq{
        artist => 'yes',
        title  => 'no',
        tracks => [
            {title => "yep"},
        ],
    }), 0, "$idx: missing duration");
    is($is_album->(sq{
        artist => 'yes',
        title  => 'no',
        tracks => [
            {title => "yep", duration => 10},
        ],
    }), 1, "$idx: fine 2");

    $idx++;
}

test(0, sub($data) { $is_album_manual->($data)      });
test(1, sub($data) { t_valid($is_album_type, $data) });

sub add_points($p1, $p2) {
    state $is_point = t_hash(t_keys(
        X => t_num,
        Y => t_num,
    ));
    t_assert($is_point, $p1, $p2);

    return {
        X => $p1->{X} + $p2->{X},
        Y => $p1->{Y} + $p2->{Y},
    };
}

is(
    add_points({X=>1,Y=>1}, {X=>1,Y=>1}),
    {X => 2, Y => 2},
    'adding points');

like(
    dies { add_points({X=>1}, {X=>1,Y=>1}) },
    qr/\AType Error/,
    'throws error 1');

like(
    dies { add_points({X=>1,Y=>1}, {X=>1}) },
    qr/\AType Error/,
    'throws error 2');

like(
    dies { add_points({}, {}) },
    qr/\AType Error/,
    'throws error 3');

like(
    dies { add_points([], []) },
    qr/\AType Error/,
    'throws error 4');

like(
    dies { add_points("", "") },
    qr/\AType Error/,
    'throws error 5');

done_testing;