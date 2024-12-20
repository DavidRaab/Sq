#!perl
use 5.036;
use Sq;
use Sq::Type;
use Sq::Parser;
use Sq::Sig;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

# data used for checking
my $album = sq {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        { name => 'foo', duration => '03:16' },
        { name => 'bar', duration => '03:45' },
    ],
    rating => Some(10),
    tags   => None,
    desc   => "Good Album",
};

# checks for an album
my $is_album1 = t_hash(
    t_has_keys(qw/artist title tracks rating desc tags/),
    t_key(artist => t_str),
    t_key(title  => t_str),
    t_key(tracks => t_array(
        t_of(t_hash(t_has_keys(qw/name duration/))),
    )),
    t_key(rating => t_opt(
        t_is(sub($x) { is_num $x }),
    )),
    t_key(tags => t_opt(t_array(t_str))),
    t_key(desc => t_str),
);
is(t_run($is_album1, $album), Ok 1, '$album1 ok');

# same as $album but uses t_keys
my $is_album2 = t_hash(
    t_has_keys(qw/artist title tracks rating desc tags/),
    t_keys(
        artist => t_str,
        title  => t_str,
        tracks => t_array(
            t_of(t_hash(t_has_keys(qw/name duration/))),
        ),
        rating => t_opt(
            t_is(sub($x) { is_num $x }),
        ),
        tags => t_opt(t_array(t_str)),
        desc => t_str
    ),
);

ok(t_valid($is_album2, $album), '$album1 ok');
ok(
    t_valid(t_hash(t_key(rating => t_opt(t_num))), $album),
    'rating is number');
ok(
    t_valid(
        t_hash(t_key(
            rating => t_opt(t_num(t_is(sub($num){ $num == 10 })))
        )),
        $album),
    'rating is number and 10');
ok(
    t_valid(
        t_hash(t_key(
            artist => t_str(t_length(3)))),
        $album),
    'artist at least 3 characters');
ok(
    t_valid(
        t_hash(t_key(
            tracks => t_array(t_of(t_hash(t_keys(
                name     => t_str,
                duration => t_match(qr/\A(\d\d):(\d\d)\z/)
            ))))
        )),
        $album
    ),
    'tracks duration matches regex');

# Example for using the Parser, but its usually better to use
# t_match ot t_matchf instead.
my $is_album_parser = assign {
    my $duration = p_matchf(qr/(\d\d):(\d\d)\z/, sub($min,$sec) {
        return if $min >= 60;
        return if $sec >= 60;
        return $min,$sec;
    });

    return
        t_hash(
            t_has_keys(qw/artist title tracks/),
            t_keys(
                artist => t_str(t_length 1),
                title  => t_str(t_length 1),
                tracks => t_array(
                    t_length(1),               # Array must have at least 1 entry
                    t_of(t_hash(              # All entries must be hashes
                        t_has_keys(qw/name duration/),
                        t_keys(
                            name     => t_str,
                            duration => t_parser($duration)))))));
};

my $is_album_matchf = assign {
    my $duration = t_matchf(qr/\A(\d\d):(\d\d)\z/, sub($min,$sec) {
        return if $min >= 60;
        return if $sec >= 60;
        return 1;
    });

    return
        t_hash(
            t_has_keys(qw/artist title tracks/),
            t_keys(
                artist => t_str(t_length 1),
                title  => t_str(t_length 1),
                tracks => t_array(
                    t_length(1),               # Array must have at least 1 entry
                    t_of(t_hash(              # All entries must be hashes
                        t_has_keys(qw/name duration/),
                        t_keys(
                            name     => t_str,
                            duration => $duration))))));
};

my $idx = 0;
for my $is_album ( $is_album_parser, $is_album_matchf ) {
    ok(t_valid($is_album, $album), "$idx: \$album is an album");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [],
    }), "$idx: no track");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [{
            name => "first",
            dur  => 200,
        }],
    }), "$idx: dur instead of duration in track");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [{
            name     => "first",
            duration => 200,
        }],
    }), "$idx: duration not correct format 1");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [{
            name     => "first",
            duration => "000:00",
        }],
    }), "$idx: duration not correct format 2");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [{
            Name     => "first",
            duration => "00:00",
        }],
    }), "$idx: Name in tracks wrong");

    ok(t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [{
            name     => "first",
            duration => "00:00",
        }],
    }), "$idx: Everything ok");

    ok(!t_valid($is_album, {
        artist => "",
        title  => "Whatever",
        tracks => [{
            name     => "first",
            duration => "00:00",
        }],
    }), "$idx: artist empty");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "",
        tracks => [{
            name     => "first",
            duration => "00:00",
        }],
    }), "$idx: title empty");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [
            {
                name     => "first",
                duration => "00:00",
            },
            {}
        ],
    }), "$idx: second track missing everything");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [
            {
                name     => "first",
                duration => "00:00",
            },
            {
                name     => "second",
                duration => "60:44",
            }
        ],
    }), "$idx: duration not correct");

    ok(t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [
            {
                name     => "first",
                duration => "00:00",
            },
            {
                name     => "second",
                duration => "59:59",
            }
        ],
    }), "$idx: everything ok 2");

    ok(!t_valid($is_album, {
        artist => "Yes",
        title  => "Whatever",
        tracks => [
            {
                name     => "first",
                duration => "00:00",
            },
            {
                name     => "second",
                duration => "59:60",
            }
        ],
    }), "$idx: duration not correct");

    $idx++;
}

done_testing;
