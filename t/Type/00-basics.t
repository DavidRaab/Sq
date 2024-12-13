#!perl
use 5.036;
use Sq;
use Sq::Type;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

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
        t_has_keys(qw/artist title tracks/),
    );

my $is_album2 =
    t_hash(
        t_has_keys('artist', 'title'),
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

is(t_run(t_hash,  {}), Ok(1),               '{} is hash');
is(t_run(t_hash,  []), Err('Not a Hash'),   '[] not a hash');
is(t_run(t_array, []), Ok(1),               '[] is array');
is(t_run(t_array, {}), Err('Not an Array'), '{} not an array');

is(t_run(t_hash, {}, {}, {}),             Ok(1), 'multiple hashes');
is(t_run(t_hash, {}, {}, []), Err("Not a Hash"), 'one not hash');

ok( t_valid($is_album, $album),        'check if $album is album');
ok(!t_valid($is_album, $album_wrong1), 'check if $album_wrong1 fails');
ok(
    t_valid($is_album, $album_wrong2),
    '$album_wrong2 is a valid $album because tracks only need to be defined');

ok( t_valid(t_key(artist => t_str), $album), 'check if album.artist is_str');
ok(!t_valid(t_key(foo    => t_str), $album), 'album.foo must fail');
ok(
    t_valid(t_key(artist => t_str_eq('Michael Jackson')), $album),
    'album is from Michael Jackson');
ok( t_valid($is_album2, $album),        'full album check');
ok(!t_valid($is_album2, $album_wrong2), 'album.tracks not an array');

# t_length
{
    # only min
    ok(!t_valid(t_length(1), []         ), 't_length 1');
    ok( t_valid(t_length(1), [1]        ), 't_length 2');
    ok( t_valid(t_length(1), [1,2]      ), 't_length 3');
    ok(!t_valid(t_length(1), {}         ), 't_length 4');
    ok( t_valid(t_length(1), {f=>1}     ), 't_length 5');
    ok( t_valid(t_length(1), {f=>1,g=>1}), 't_length 6');

    # min and max
    ok(!t_valid(t_length(1,3), []       ), 't_length 7');
    ok( t_valid(t_length(1,3), [1,2]    ), 't_length 9');
    ok( t_valid(t_length(1,3), [1]      ), 't_length 8');
    ok( t_valid(t_length(1,3), [1,2,3]  ), 't_length 10');
    ok(!t_valid(t_length(1,3), [1,2,3,4]), 't_length 11');

    ok(!t_valid(t_length(1,3), {}                   ), 't_length 12');
    ok( t_valid(t_length(1,3), {a=>1}               ), 't_length 13');
    ok( t_valid(t_length(1,3), {a=>1,b=>2}          ), 't_length 14');
    ok( t_valid(t_length(1,3), {a=>1,b=>2,c=>3}     ), 't_length 15');
    ok(!t_valid(t_length(1,3), {a=>1,b=>2,c=>3,d=>4}), 't_length 16');

    # string
    ok(!t_valid(t_length(1),  "" ), 't_length 17');
    ok( t_valid(t_length(1),  "a"), 't_length 18');
    ok( t_valid(t_length(1), "ab"), 't_length 19');

    ok(!t_valid(t_length(1,3), ""    ), 't_length 17');
    ok( t_valid(t_length(1,3), "a"   ), 't_length 18');
    ok( t_valid(t_length(1,3), "ab"  ), 't_length 19');
    ok( t_valid(t_length(1,3), "abc" ), 't_length 20');
    ok(!t_valid(t_length(1,3), "abcd"), 't_length 21');
}

# t_all
{
    ok( t_valid(t_all(t_hash), []         ), 't_all 1');
    ok( t_valid(t_all(t_hash), [{}, {}]   ), 't_all 2');
    ok(!t_valid(t_all(t_hash), [{}, {}, 1]), 't_all 3');

    ok( t_valid(t_all(t_array), {}                ), 't_all 4');
    ok( t_valid(t_all(t_array), {a=>[]}           ), 't_all 5');
    ok( t_valid(t_all(t_array), {a=>[],b=>[]}     ), 't_all 6');
    ok(!t_valid(t_all(t_array), {a=>[],b=>[],c=>1}), 't_all 7');
}

# t_valid & t_assert
{
    ok( t_valid(t_hash, {}),     'is hash');
    ok( t_valid(t_hash, {}, {}), 'is hash');
    ok(!t_valid(t_hash, {}, []), 'not all hash');

    like(
        dies { t_assert(t_hash, []) },
        qr/\AType check failed/,
        't_assert throws exception'
    );
}

# t_min / t_max / t_range
{
    ok(!t_valid(t_min(10),  0), 't_min 1');
    ok( t_valid(t_min(10), 10), 't_min 2');
    ok( t_valid(t_min(10), 20), 't_min 3');
    ok( t_valid(t_max(10),  0), 't_max 1');
    ok( t_valid(t_max(10), 10), 't_max 2');
    ok(!t_valid(t_max(10), 20), 't_max 3');

    ok(!t_valid(t_num(t_min(0), t_max(10)), -1), 't_min & t_max 1');
    ok( t_valid(t_num(t_min(0), t_max(10)),  0), 't_min & t_max 2');
    ok( t_valid(t_num(t_min(0), t_max(10)),  5), 't_min & t_max 3');
    ok( t_valid(t_num(t_min(0), t_max(10)), 10), 't_min & t_max 4');
    ok(!t_valid(t_num(t_min(0), t_max(10)), 11), 't_min & t_max 5');

    ok(!t_valid(t_range(0, 10), -1), 't_range 1');
    ok( t_valid(t_range(0, 10),  0), 't_range 2');
    ok( t_valid(t_range(0, 10),  5), 't_range 3');
    ok( t_valid(t_range(0, 10), 10), 't_range 4');
    ok(!t_valid(t_range(0, 10), 11), 't_range 5');
}

# t_or
{
    my $date = t_or(
        t_match(qr{\A \d\d \. \d\d \. \d\d\d\d\z}x),
        t_match(qr{\A \d\d / \d\d  /  \d\d\d\d\z}x),
    );

    ok( t_valid($date, "01.01.1970"), 't_or 1');
    ok( t_valid($date, "12/24/1970"), 't_or 2');
    ok(!t_valid($date, "12-24-1970"), 't_or 3');
}

# t_int
{
    ok(!t_valid(t_int(t_range(0,10)), "-1"), 't_int 1');
    ok( t_valid(t_int(t_range(0,10)),  "0"), 't_int 2');
    ok( t_valid(t_int(t_range(0,10)),  "5"), 't_int 3');
    ok( t_valid(t_int(t_range(0,10)), "+5"), 't_int 4');
    ok(!t_valid(t_int(t_range(0,10)),"5.5"), 't_int 5');
    ok( t_valid(t_num(t_range(0,10)),"5.5"), 't_num vs t_int');
    ok( t_valid(t_int(t_range(0,10)), "10"), 't_int 6');
    ok(!t_valid(t_int(t_range(0,10)), "11"), 't_int 7');
}

done_testing;
