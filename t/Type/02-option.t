#!perl
use 5.036;
use Sq;
use Sq::Type;
use Test2::V0;

# data used for checking
my $album1 = sq {
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
        t_all(t_hash(t_has_keys(qw/name duration/))),
    )),
    t_key(rating => t_opt(
        t_is(sub($x) { is_num $x }),
    )),
    t_key(tags => t_opt(t_array(t_str))),
    t_key(desc => t_str),
);
is(t_run($is_album1, $album1), Ok 1, '$album1 ok');

# same as $album1 but used t_keys
my $is_album2 = t_hash(
    t_has_keys(qw/artist title tracks rating desc tags/),
    t_keys(
        artist => t_str,
        title  => t_str,
        tracks => t_array(
            t_all(t_hash(t_has_keys(qw/name duration/))),
        ),
        rating => t_opt(
            t_is(sub($x) { is_num $x }),
        ),
        tags => t_opt(t_array(t_str)),
        desc => t_str
    ),
);

ok(t_valid($is_album2, $album1), '$album1 ok');
ok(
    t_valid(t_hash(t_key(rating => t_opt(t_num))), $album1),
    'rating is number');
ok(
    t_valid(
        t_hash(t_key(
            rating => t_opt(t_num(t_is(sub($num){ $num == 10 })))
        )),
        $album1),
    'rating is number and 10');
ok(
    t_valid(
        t_hash(t_key(
            artist => t_str(t_length(3)))),
        $album1),
    'artist at least 3 characters');
ok(
    t_valid(
        t_hash(t_key(
            tracks => t_array(t_all(t_hash(t_keys(
                name     => t_str,
                duration => t_match(qr/\A(\d\d):(\d\d)\z/)
            ))))
        )),
        $album1
    ),
    'tracks duration matches regex');

done_testing;
