#!perl
use 5.036;
use Sq;
use Sq::Type;
use Test2::V0;

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

is(t_run($is_album, $album), Ok(1),
    'check if $album is album');
is(t_run($is_album, $album_wrong1), Err("key artist not defined"),
    'check if $album_wrong1 fails');

is(t_run($is_album, $album_wrong2), Ok(1),
    '$album_wrong2 is a valid $album because tracks only need to be defined');

is(t_run(t_key(artist => t_str), $album), Ok(1),
    'check if album.artist is_str');
is(t_run(t_key(foo    => t_str), $album), Err("foo does not exists on hash"),
    'album.foo must fail');

is(t_run(t_key(artist => t_str_eq('Michael Jackson')), $album, ), Ok(1),
    'album is from Michael Jackson');
is(t_run($is_album2, $album), Ok(1),
    'full album check');

is(t_run($is_album2, $album_wrong2), Err('Not an Array'),
    'album.tracks not an array');

# t_length
{
    my $ne = Err("Not enough elements");
    my $tm = Err("Too many elements");

    # only min
    is(t_run(t_length(1), []   ), $ne,   't_length 1');
    is(t_run(t_length(1), [1]  ), Ok(1), 't_length 2');
    is(t_run(t_length(1), [1,2]), Ok(1), 't_length 3');

    is(t_run(t_length(1), {}         ), $ne,   't_length 4');
    is(t_run(t_length(1), {f=>1}     ), Ok(1), 't_length 5');
    is(t_run(t_length(1), {f=>1,g=>1}), Ok(1), 't_length 6');

    # min and max
    is(t_run(t_length(1,3), []       ),   $ne, 't_length 7');
    is(t_run(t_length(1,3), [1]      ), Ok(1), 't_length 8');
    is(t_run(t_length(1,3), [1,2]    ), Ok(1), 't_length 9');
    is(t_run(t_length(1,3), [1,2,3]  ), Ok(1), 't_length 10');
    is(t_run(t_length(1,3), [1,2,3,4]),   $tm, 't_length 11');

    is(t_run(t_length(1,3), {}                   ),   $ne, 't_length 12');
    is(t_run(t_length(1,3), {a=>1}               ), Ok(1), 't_length 13');
    is(t_run(t_length(1,3), {a=>1,b=>2}          ), Ok(1), 't_length 14');
    is(t_run(t_length(1,3), {a=>1,b=>2,c=>3}     ), Ok(1), 't_length 15');
    is(t_run(t_length(1,3), {a=>1,b=>2,c=>3,d=>4}),   $tm, 't_length 16');

    # string
    is(t_run(t_length(1),  "" ), Err("string to short"), 't_length 17');
    is(t_run(t_length(1),  "a"),                  Ok(1), 't_length 18');
    is(t_run(t_length(1), "ab"),                  Ok(1), 't_length 19');

    is(t_run(t_length(1,3), ""    ), Err("string to short"), 't_length 17');
    is(t_run(t_length(1,3), "a"   ),                  Ok(1), 't_length 18');
    is(t_run(t_length(1,3), "ab"  ),                  Ok(1), 't_length 19');
    is(t_run(t_length(1,3), "abc" ),                  Ok(1), 't_length 20');
    is(t_run(t_length(1,3), "abcd"),  Err('string to long'), 't_length 21');
}

# t_all
{
    my $ea = Err("Element of Array does not match predicate");
    my $eh = Err("A value of a Hash does not match predicate");

    is(t_run(t_all(t_hash), []         ), Ok(1), 't_all 1');
    is(t_run(t_all(t_hash), [{}, {}]   ), Ok(1), 't_all 2');
    is(t_run(t_all(t_hash), [{}, {}, 1]),   $ea, 't_all 3');

    is(t_run(t_all(t_array), {}                ), Ok(1), 't_all 4');
    is(t_run(t_all(t_array), {a=>[]}           ), Ok(1), 't_all 5');
    is(t_run(t_all(t_array), {a=>[],b=>[]}     ), Ok(1), 't_all 6');
    is(t_run(t_all(t_array), {a=>[],b=>[],c=>1}),   $eh, 't_all 7');
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

done_testing;
