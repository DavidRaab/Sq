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
        t_with_keys(qw/artist title tracks/),
    );

my $is_album2 =
    t_hash(
        t_with_keys('artist', 'title'),
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

is(t_run({},  t_hash), Ok(1),               '{} is hash');
is(t_run([],  t_hash), Err('Not a Hash'),   '[] not a hash');
is(t_run([], t_array), Ok(1),               '[] is array');
is(t_run({}, t_array), Err('Not an Array'), '{} not an array');

is(t_run($album,        $is_album), Ok(1),
    'check if $album is album');
is(t_run($album_wrong1, $is_album), Err("key artist not defined"),
    'check if $album_wrong1 fails');

is(t_run($album_wrong2, $is_album),  Ok(1),
    '$album_wrong2 is a valid $album because tracks only need to be defined');

is(t_run($album, t_key artist => t_str), Ok(1),
    'check if album.artist is_str');
is(t_run($album, t_key foo    => t_str), Err("foo does not exists on hash"),
    'album.foo must fail');

is(t_run($album, t_key artist => t_str_eq('Michael Jackson')), Ok(1),
    'album is from Michael Jackson');
is(t_run($album, $is_album2), Ok(1),
    'full album check');

is(t_run($album_wrong2, $is_album2), Err('Not an Array'),
    'album.tracks not an array');

# t_length
{
    my $ne = Err("Not enough elements");
    my $tm = Err("Too many elements");

    # only min
    is(t_run([],          t_length(1)), $ne,   't_length 1');
    is(t_run([1],         t_length(1)), Ok(1), 't_length 2');
    is(t_run([1,2],       t_length(1)), Ok(1), 't_length 3');

    is(t_run({},          t_length(1)), $ne,   't_length 4');
    is(t_run({f=>1},      t_length(1)), Ok(1), 't_length 5');
    is(t_run({f=>1,g=>1}, t_length(1)), Ok(1), 't_length 6');

    # min and max
    is(t_run([],        t_length(1,3)),   $ne, 't_length 7');
    is(t_run([1],       t_length(1,3)), Ok(1), 't_length 8');
    is(t_run([1,2],     t_length(1,3)), Ok(1), 't_length 9');
    is(t_run([1,2,3],   t_length(1,3)), Ok(1), 't_length 10');
    is(t_run([1,2,3,4], t_length(1,3)),   $tm, 't_length 11');

    is(t_run({},                    t_length(1,3)),   $ne, 't_length 12');
    is(t_run({a=>1},                t_length(1,3)), Ok(1), 't_length 13');
    is(t_run({a=>1,b=>2},           t_length(1,3)), Ok(1), 't_length 14');
    is(t_run({a=>1,b=>2,c=>3},      t_length(1,3)), Ok(1), 't_length 15');
    is(t_run({a=>1,b=>2,c=>3,d=>4}, t_length(1,3)),   $tm, 't_length 16');

    # string
    is(t_run("",   t_length(1)), Err("string to short"), 't_length 17');
    is(t_run("a",  t_length(1)),                  Ok(1), 't_length 18');
    is(t_run("ab", t_length(1)),                  Ok(1), 't_length 19');

    is(t_run("",     t_length(1,3)), Err("string to short"), 't_length 17');
    is(t_run("a",    t_length(1,3)),                  Ok(1), 't_length 18');
    is(t_run("ab",   t_length(1,3)),                  Ok(1), 't_length 19');
    is(t_run("abc",  t_length(1,3)),                  Ok(1), 't_length 20');
    is(t_run("abcd", t_length(1,3)),  Err('string to long'), 't_length 21');
}

# t_all
{
    my $ea = Err("Element of Array does not match predicate");
    my $eh = Err("A value of a Hash does not match predicate");

    is(t_run([],          t_all(t_hash)), Ok(1), 't_all 1');
    is(t_run([{}, {}],    t_all(t_hash)), Ok(1), 't_all 2');
    is(t_run([{}, {}, 1], t_all(t_hash)),   $ea, 't_all 3');

    is(t_run({},                 t_all(t_array)), Ok(1), 't_all 4');
    is(t_run({a=>[]},            t_all(t_array)), Ok(1), 't_all 5');
    is(t_run({a=>[],b=>[]},      t_all(t_array)), Ok(1), 't_all 6');
    is(t_run({a=>[],b=>[],c=>1}, t_all(t_array)),   $eh, 't_all 7');
}

done_testing;
