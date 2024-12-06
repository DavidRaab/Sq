#!perl
use 5.036;
use Sq;
use Sq::Type;
use Test2::V0;

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

is(t_run($is_album1, $album1), Ok 1, '$album1 ok');

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

done_testing;
