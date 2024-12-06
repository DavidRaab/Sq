#!perl
use 5.036;
use Test2::V0 qw(diag is done_testing);
use Data::Language qw/:default :error/;

diag( "Testing Data::Language $Data::Language::VERSION, Perl $], $^X" );

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
    a_hash(
        with_key('artist'),
        with_key('title'),
        with_key('tracks'),
    );

my $is_album2 =
    a_hash(
        with_key('artist'),
        with_key('title'),
        key('tracks', a_array(
            idx(0,
                a_hash(
                    key(name     => is_str),
                    key(duration => str('03:16')),
                ),
            ),
            idx(1,
                a_hash(
                    key(name     => str('bar')),
                    key(duration => str('03:45')),
                ),
            ),
        )),
    );

is(check({}, a_hash),  ok(1),              '{} is hash');
is(check([], a_hash),  err('Not a HASH'),  '[] not a hash');
is(check([], a_array), ok(1),              '[] is array');
is(check({}, a_array), err('Not a ARRAY'), '{} not an array');

is(check($album,        $is_album), ok(1),
    'check if $album is album');
is(check($album_wrong1, $is_album), err("key artist not defined"),
    'check if $album_wrong1 fails');

is(check($album_wrong2, $is_album),  ok(1),
    '$album_wrong2 is a valid $album because tracks only need to be defined');

is(check($album, key artist => is_str), ok(1),
    'check if album.artist is_str');
is(check($album, key foo    => is_str), err("foo does not exists on hash"),
    'album.foo must fail');

is(check($album, key artist => str('Michael Jackson')), ok(1),
    'album is from Michael Jackson');
is(check($album, $is_album2), ok(1),
    'full album check');

is(check($album_wrong2, $is_album2), err('Not a ARRAY'),
    'album.tracks not an array');

done_testing;

