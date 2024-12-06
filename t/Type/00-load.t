#!perl
use 5.036;
use Sq;
use Sq::Type;
use Test2::V0 qw(diag is done_testing);

my $album = {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        { name => 'foo', duration => '03:16' },
        { name => 'bar', duration => '03:45' },
    ],
};

my $album_wrong1 = {
    artsst => 'Michael Jackson',  # TYPO
    title  => 'Thriller',
    tracks => [
        { name => 'foo', duration => '03:16' },
        { name => 'bar', duration => '03:45' },
    ],
};

my $album_wrong2 = {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => { # HASH instead of ARRAY
        { name => 'foo', duration => '03:16' },
        { name => 'bar', duration => '03:45' },
    },
};

# my $is_album =
my $is_album =
    t_hash(
        t_with_key('artist'),
        t_with_key('title'),
        t_with_key('tracks'),
    );

my $is_album2 =
    t_hash(
        t_with_key('artist'),
        t_with_key('title'),
        t_key('tracks', t_array(
            t_idx(0,
                t_hash(
                    t_key(name     => t_str),
                    t_key(duration => t_str_eq('03:16')),
                ),
            ),
            t_idx(1,
                t_hash(
                    t_key(name     => t_str_eq('bar')),
                    t_key(duration => t_str_eq('03:45')),
                ),
            ),
        )),
    );

is(t_check({}, t_hash),  Ok(1),               '{} is hash');
is(t_check([], t_hash),  Err('Not a Hash'),   '[] not a hash');
is(t_check([], t_array), Ok(1),               '[] is array');
is(t_check({}, t_array), Err('Not an Array'), '{} not an array');

is(t_check($album,        $is_album), Ok(1),
    'check if $album is album');
is(t_check($album_wrong1, $is_album), Err("key artist not defined"),
    'check if $album_wrong1 fails');

is(t_check($album_wrong2, $is_album),  Ok(1),
    '$album_wrong2 is a valid $album because tracks only need to be defined');

is(t_check($album, t_key artist => t_str), Ok(1),
    'check if album.artist is_str');
is(t_check($album, t_key foo    => t_str), Err("foo does not exists on hash"),
    'album.foo must fail');

is(t_check($album, t_key artist => t_str_eq('Michael Jackson')), Ok(1),
    'album is from Michael Jackson');
is(t_check($album, $is_album2), Ok(1),
    'full album check');

is(t_check($album_wrong2, $is_album2), Err('Not an Array'),
    'album.tracks not an array');

done_testing;

