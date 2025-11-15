#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Type;
use Sq::Test;

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

# Simple check
my $is_album  =
    t_hash(t_with_keys(qw/artist title tracks/));

# Extended check
my $is_album2 =
    t_hash(
        t_with_keys('artist', 'title'),
        t_keys(
            tracks => t_array(
                t_idx(0,
                    t_hash(t_keys(
                        name     => t_str,
                        duration => t_enum('03:16'),
                    )),
                ),
                t_idx(1,
                    t_hash(t_keys(
                        name     => t_enum('bar'),
                        duration => t_enum('03:45'),
                    )),
                ),
            )
        ),
    );

is(t_run(t_hash,  {}), Ok(1),                      '{} is hash');
is(t_run(t_hash,  []), Err('hash: Not a Hash'),    '[] not a hash');
is(t_run(t_array, []), Ok(1),                      '[] is array');
is(t_run(t_array, {}), Err('array: Not an Array'), '{} not an array');

is(t_run(t_hash, {}, {}, {}),                   Ok(1), 'multiple hashes');
is(t_run(t_hash, {}, {}, []), Err("hash: Not a Hash"), 'one not hash');

ok( t_run($is_album, $album),        'check if $album is album');
nok(t_run($is_album, $album_wrong1), 'check if $album_wrong1 fails');
ok(
    t_run($is_album, $album_wrong2),
    '$album_wrong2 is a valid $album because tracks only need to be defined');

ok( t_run(t_keys(artist => t_str), $album), 'check if album.artist is_str');
nok(t_run(t_keys(foo    => t_str), $album), 'album.foo must fail');
ok(
    t_run(t_keys(artist => t_enum('Michael Jackson')), $album),
    'album is from Michael Jackson');
ok( t_run($is_album2, $album),        'full album check');
nok(t_run($is_album2, $album_wrong2), 'album.tracks not an array');

# t_enum
{
    my $choices = t_enum(qw/yes no maybe/);
    ok( t_run($choices,   'yes'), 't_enum 1');
    ok( t_run($choices,    'no'), 't_enum 2');
    ok( t_run($choices, 'maybe'), 't_enum 3');
    nok(t_run($choices,      ''), 't_enum 4');
    nok(t_run($choices,      []), 't_enum 5');
    nok(t_run($choices,      {}), 't_enum 6');
}

# t_length
{
    nok(t_run(t_length(1,10), []         ), 't_length 1');
    ok( t_run(t_length(1,10), [1]        ), 't_length 2');
    ok( t_run(t_length(1,10), [1,2]      ), 't_length 3');
    nok(t_run(t_length(1,10), {}         ), 't_length 4');
    ok( t_run(t_length(1,10), {f=>1}     ), 't_length 5');
    ok( t_run(t_length(1,10), {f=>1,g=>1}), 't_length 6');

    # min and max
    nok(t_run(t_length(1,3), []       ), 't_length 7');
    ok( t_run(t_length(1,3), [1,2]    ), 't_length 9');
    ok( t_run(t_length(1,3), [1]      ), 't_length 8');
    ok( t_run(t_length(1,3), [1,2,3]  ), 't_length 10');
    nok(t_run(t_length(1,3), [1,2,3,4]), 't_length 11');

    nok(t_run(t_length(1,3), {}                   ), 't_length 12');
    ok( t_run(t_length(1,3), {a=>1}               ), 't_length 13');
    ok( t_run(t_length(1,3), {a=>1,b=>2}          ), 't_length 14');
    ok( t_run(t_length(1,3), {a=>1,b=>2,c=>3}     ), 't_length 15');
    nok(t_run(t_length(1,3), {a=>1,b=>2,c=>3,d=>4}), 't_length 16');

    # string
    nok(t_run(t_length(1,10),  "" ), 't_length 17');
    ok( t_run(t_length(1,10),  "a"), 't_length 18');
    ok( t_run(t_length(1,10), "ab"), 't_length 19');

    nok(t_run(t_length(1,3), ""    ), 't_length 17');
    ok( t_run(t_length(1,3), "a"   ), 't_length 18');
    ok( t_run(t_length(1,3), "ab"  ), 't_length 19');
    ok( t_run(t_length(1,3), "abc" ), 't_length 20');
    nok(t_run(t_length(1,3), "abcd"), 't_length 21');
}

# t_of
{
     ok(t_run(t_of(t_hash), []         ), 't_of 1');
     ok(t_run(t_of(t_hash), [{}, {}]   ), 't_of 2');
    nok(t_run(t_of(t_hash), [{}, {}, 1]), 't_of 3');

     ok(t_run(t_of(t_array), {}                ), 't_of 4');
     ok(t_run(t_of(t_array), {a=>[]}           ), 't_of 5');
     ok(t_run(t_of(t_array), {a=>[],b=>[]}     ), 't_of 6');
    nok(t_run(t_of(t_array), {a=>[],b=>[],c=>1}), 't_of 7');

    # hash with values of either int or array
    my $hash = t_hash(t_of(t_int, t_array));
     ok(t_run($hash, {foo =>  1}), 't_of 8');
     ok(t_run($hash, {foo => []}), 't_of 9');
     ok(t_run($hash, {foo => [], bar => 1}), 't_of 10');
    nok(t_run($hash, {foo => [], bar => 1, baz => {}}), 't_of 10');
}

# t_valid & t_assert
{
    ok( t_run(t_hash, {}),     'is hash');
    ok( t_run(t_hash, {}, {}), 'is hash');
    nok(t_run(t_hash, {}, []), 'not all hash');

    dies { t_assert(t_hash, []) }
    qr/\AType Error/,
    't_assert throws exception';
}

# t_num
{
    ok( t_run(t_num,   "123"), 't_num 1');
    ok( t_run(t_num,  "12.3"), 't_num 2');
    ok( t_run(t_num, "+12.3"), 't_num 3');
    ok( t_run(t_num, "-12.3"), 't_num 4');
    ok( t_run(t_num,   "0E0"), 't_num 5');
    ok( t_run(t_num,       1), 't_num 6');
    ok( t_run(t_num,     1.2), 't_num 7');

    nok(t_run(t_num,      []), 't_num 8');
    nok(t_run(t_num,      {}), 't_num 9');
    nok(t_run(t_num,   sub{}), 't_num 10');
}

# t_min / t_max / t_range
{
    nok(t_run(t_num(t_min(0), t_max(10)), -1), 't_min & t_max 1');
    ok( t_run(t_num(t_min(0), t_max(10)),  0), 't_min & t_max 2');
    ok( t_run(t_num(t_min(0), t_max(10)),  5), 't_min & t_max 3');
    ok( t_run(t_num(t_min(0), t_max(10)), 10), 't_min & t_max 4');
    nok(t_run(t_num(t_min(0), t_max(10)), 11), 't_min & t_max 5');

    nok(t_run(t_range(0, 10), -1), 't_range 1');
    ok( t_run(t_range(0, 10),  0), 't_range 2');
    ok( t_run(t_range(0, 10),  5), 't_range 3');
    ok( t_run(t_range(0, 10), 10), 't_range 4');
    nok(t_run(t_range(0, 10), 11), 't_range 5');
}

# t_min
{
    nok(t_run(t_min(10),         0), 't_min 1');
    ok( t_run(t_min(10),        10), 't_min 2');
    ok( t_run(t_min(10),        20), 't_min 3');
    nok(t_run(t_min(1),         ""), 't_min 4');
    ok( t_run(t_min(1),        "a"), 't_min 5');
    ok( t_run(t_min(1),       "ab"), 't_min 6');
    nok(t_run(t_min(1),         []), 't_min 7');
    ok( t_run(t_min(1),        [1]), 't_min 8');
    ok( t_run(t_min(1),      [1,2]), 't_min 9');
    nok(t_run(t_min(1),         {}), 't_min 10');
    ok( t_run(t_min(1),     {1=>2}), 't_min 11');
    ok( t_run(t_min(1),     {1..4}), 't_min 12');
    nok(t_run(t_min(1), Seq->empty), 't_min 13');
}

# t_max
{
    ok( t_run(t_max(10),         0), 't_max 1');
    ok( t_run(t_max(10),        10), 't_max 2');
    nok(t_run(t_max(10),        20), 't_max 3');
    ok( t_run(t_max(1),         ""), 't_max 4');
    ok( t_run(t_max(1),        "a"), 't_max 5');
    nok(t_run(t_max(1),       "ab"), 't_max 6');
    ok( t_run(t_max(1),         []), 't_max 7');
    ok( t_run(t_max(1),        [1]), 't_max 8');
    nok(t_run(t_max(1),      [1,2]), 't_max 9');
    ok( t_run(t_max(1),         {}), 't_max 10');
    ok( t_run(t_max(1),     {1=>2}), 't_max 11');
    nok(t_run(t_max(1),     {1..4}), 't_max 12');
    nok(t_run(t_max(1), Seq->empty), 't_max 13');
}

# t_positive & t_negative
{
    nok(t_run(t_positive, -1), 't_positive 1');
    ok( t_run(t_positive,  0), 't_positive 2');
    ok( t_run(t_positive,  1), 't_positive 3');
    ok( t_run(t_negative, -1), 't_negative 1');
    ok( t_run(t_negative,  0), 't_negative 2');
    nok(t_run(t_negative,  1), 't_negative 3');
}

# t_or
{
    my $date = t_or(
        t_match(qr{\A \d\d \. \d\d \. \d\d\d\d\z}x),
        t_match(qr{\A \d\d / \d\d  /  \d\d\d\d\z}x),
    );

    ok( t_run($date, "01.01.1970"), 't_or 1');
    ok( t_run($date, "12/24/1970"), 't_or 2');
    nok(t_run($date, "12-24-1970"), 't_or 3');
}

# t_int
{
    nok(t_run(t_int(t_range(0,10)), "-1"), 't_int 1');
    ok( t_run(t_int(t_range(0,10)),  "0"), 't_int 2');
    ok( t_run(t_int(t_range(0,10)),  "5"), 't_int 3');
    ok( t_run(t_int(t_range(0,10)), "+5"), 't_int 4');
    nok(t_run(t_int(t_range(0,10)),"5.5"), 't_int 5');
    ok( t_run(t_num(t_range(0,10)),"5.5"), 't_num vs t_int');
    ok( t_run(t_int(t_range(0,10)), "10"), 't_int 6');
    nok(t_run(t_int(t_range(0,10)), "11"), 't_int 7');
}

# t_tuple - size 2
{
    my $kv = t_tuple(t_str, t_int);
    # correct
    ok( t_run($kv, ["foo", 1]),    'tuple 1');

    # not correct size
    nok(t_run($kv, ["foo", 1, 2]), 'tuple 2');
    nok(t_run($kv, ["foo"]),       'tuple 3');
    nok(t_run($kv, []),            'tuple 4');

    # not array
    nok(t_run($kv, {}),            'tuple 5');
    nok(t_run($kv, ""),            'tuple 6');
    nok(t_run($kv, 1),             'tuple 7');

    # correct size, but types don't match
    nok(t_run($kv, [1,"foo"]),     'tuple 8');
}

# t_tuple - size 1
{
    my $str = t_tuple(t_str);
    # correct
    ok( t_run($str, ["foo"]), 'tuple 9');

    # not correct size
    nok(t_run($str,         []), 'tuple 10');
    nok(t_run($str, ["foo", 1]), 'tuple 11');
}

# t_tuple - other sizes
{
    ok( t_run(t_tuple(t_int, t_str, t_array), [12, "foo", []]), 'tuple 12');
    nok(t_run(t_tuple(t_int, t_str, t_array), [12, "foo"]    ), 'tuple 13');
    nok(t_run(t_tuple(t_int, t_str, t_array), []             ), 'tuple 14');
    ok( t_run(
            t_tuple(t_int, t_str, t_array(t_of t_int)),
            [12, "foo", [1,2,3]]
        ),
        'tuple 15'
    );
    nok(t_run(
            t_tuple(t_int, t_str, t_array(t_of t_int)),
            [12, "foo", [1,"foo",3]]
        ),
        'tuple 16'
    );

    # tuple of tuple
    my $tot =
        t_tuple(
            t_tuple(t_int, t_str),
            t_tuple(t_int, t_str),
        );
    ok( t_run($tot, [[1, "foo"], [2, "bar"]]), 'tuple 17');
    nok(t_run($tot, [["foo", 1], [2, "bar"]]), 'tuple 18');
    nok(t_run($tot, [[1, "foo"], [2, "bar"], [3, "baz"]]), 'tuple 19');
}

# t_any
{
    # How can i test if t_any really checks against any value? Don't know
    # but i just check some common things.
    ok(t_run(t_any,             1), 't_any  1');
    ok(t_run(t_any,         "foo"), 't_any  2');
    ok(t_run(t_any,            []), 't_any  3');
    ok(t_run(t_any,            {}), 't_any  4');
    ok(t_run(t_any,         undef), 't_any  5');
    ok(t_run(t_any,         sub{}), 't_any  6');
    ok(t_run(t_any,         sq []), 't_any  7');
    ok(t_run(t_any,         sq {}), 't_any  8');
    ok(t_run(t_any,       Some(1)), 't_any  9');
    ok(t_run(t_any,          None), 't_any 10');
    ok(t_run(t_any,         Ok(1)), 't_any 11');
    ok(t_run(t_any,        Err(1)), 't_any 12');
    ok(t_run(t_any, Seq->new(1,2)), 't_any 13');
    ok(t_run(t_any,         t_any), 't_any 14');
}

# other simple checks
{
    ok( t_run(t_sub,       sub{}), 't_sub 1');
    nok(t_run(t_sub,          {}), 't_sub 2');
    nok(t_run(t_sub,          []), 't_sub 3');
    nok(t_run(t_sub,           1), 't_sub 4');
    nok(t_run(t_sub,       "foo"), 't_sub 5');

    ok( t_run(t_regex,      qr//), 't_regex 1');
    nok(t_run(t_regex,        ""), 't_regex 2');

    ok( t_run(t_bool,          0), 't_bool 1');
    ok( t_run(t_bool,          1), 't_bool 2');
    nok(t_run(t_bool,         -1), 't_bool 3');
    nok(t_run(t_bool,          2), 't_bool 4');

    ok( t_run(t_seq, Seq->new(1)), 't_seq 1');
    ok( t_run(t_seq,  Seq->empty), 't_seq 2');
    nok(t_run(t_seq,          {}), 't_seq 3');
    nok(t_run(t_seq,       sub{}), 't_seq 4');
    nok(t_run(t_seq,          []), 't_seq 5');
}

# t_even_sized
{
    my $es1 = t_even_sized;
    my $es2 = t_array(t_even_sized);

    my $idx = 0;
    for my $es ( $es1, $es2 ) {
        ok( t_run($es,        []), "$idx: t_even_sized 1");
        nok(t_run($es,       [1]), "$idx: t_even_sized 2");
        ok( t_run($es,     [1,2]), "$idx: t_even_sized 3");
        nok(t_run($es,   [1,2,3]), "$idx: t_even_sized 4");
        ok( t_run($es, [1,2,3,4]), "$idx: t_even_sized 5");
        nok(t_run($es,        {}), "$idx: t_even_sized 6");
        nok(t_run($es,     "foo"), "$idx: t_even_sized 7");
        nok(t_run($es,         1), "$idx: t_even_sized 8");
        $idx++;
    }
}

# t_void
{
    ok( t_run(t_void, undef), 't_void 1');

    nok(t_run(t_void,     1), 't_void 3');
    nok(t_run(t_void, "foo"), 't_void 4');
    nok(t_run(t_void,    {}), 't_void 6');
}

# t_ref
{
    my $point    = bless({X=>1, Y=>1}, 'Point');
    my $is_point = t_ref('Point');

    ok( t_run($is_point, $point), 't_ref 1');
    nok(t_run($is_point,     {}), 't_ref 2');
    nok(t_run($is_point,     []), 't_ref 3');
}

# t_can
{
    my $opt = None;
    ok( t_run(t_can('map', 'iter'), $opt), 't_methods 1');
    nok(t_run(t_can('dope'),        $opt), 't_methods 2');
    nok(t_run(t_can('dope'),          []), 't_methods 3');
    nok(t_run(t_can('dope'),          {}), 't_methods 4');

    my $is_seq = t_ref('Seq', t_can('map', 'keep'));
    ok( t_run($is_seq, Seq->empty), 't_ref & t_methods');
}

# t_and
{
    my $has_position = t_hash(t_keys(
        x => t_num,
        y => t_num,
    ));
    my $has_health = t_hash(t_keys(
        health_max     => t_positive,
        health_current => t_positive,
    ));
    my $combined = t_and($has_position, $has_health);

    ok(t_run($combined, {
        title => "Entity",
        x => 10, y => 20,
        health_max => 100, health_current => 20
    }), 't_and 1');

    nok(t_run($combined, {
        title => "Entity",
        x => 10, z => 20,
        health_max => 100, health_current => 20
    }), 't_and 2');

    nok(t_run($combined, {
        title => "Entity",
        x => 10, y => 20,
        health_max => 100
    }), 't_and 3');

    nok(t_run($combined, {
        title => "Entity",
        x => 10, y => 20,
        health_max => 100, health_current => -100
    }), 't_and 4');
}

# t_maybe
{
    my $aoh = type [hash => [keys =>
        header => [array => [of => ['str']]],
        data   => [array => [of => ['hash']]],
        border => [maybe => ['bool']],
    ]];

    ok(t_run($aoh, {
        header => [qw/a b c/],
        data   => [{foo=>1}],
        border => 1,
    }), 't_maybe 1 - border defined and bool 1');

    ok(t_run($aoh, {
        header => [qw/a b c/],
        data   => [{foo=>1}],
        border => 0,
    }), 't_maybe 2 - border defined and bool 0');

    ok(t_run($aoh, {
        header => [qw/a b c/],
        data   => [{foo=>1}],
    }), 't_maybe 3 - border not defined - still valid');

    nok(t_run($aoh, {
        header => [qw/a b c/],
        data   => [{foo=>1}],
        border => 3,
    }), 't_maybe 4 - border defined but not bool');

    # check maybe number
    my $mnum = t_maybe(t_num);
     ok(t_run($mnum, undef), 'maybe num - undef turns into no check and valid');
     ok(t_run($mnum,    10), 'maybe num - is number');
    nok(t_run($mnum, "abc"), 'maybe num - string not number');
    nok(t_run($mnum,    []), 'maybe num - array-ref not number');

    # t_maybe(t_str) vs t_str
    nok(t_run(t_str,          undef), 'undef not allowed');
     ok(t_run(t_str,             ""), 'empty string is fine');
     ok(t_run(t_maybe(t_str), undef), 'undef now allowed');
     ok(t_run(t_maybe(t_str),    ""), 'empty string is fine');
}

# t_sub
{
    ok(t_run(t_sub,   sub{}), 'sub  {} is t_sub');
    ok(t_run(t_sub, lazy {}), 'lazy {} is t_sub');
}


# Build a stupid class with inheritance. Throughout Sq i don't have that
package Stupid;
use 5.036;
sub new($class) { bless({}, $class) }
sub foo() { ... }

package MoreStupid;
use 5.036;
our @ISA = 'Stupid';
sub new($class) { bless({}, $class) }
sub bar() { ... }

package main;

# t_isa
{
    my $s  = Stupid->new;
    my $ms = MoreStupid->new;

    ok( t_run(t_isa('Stupid'),     $s),  't_isa 1');
    nok(t_run(t_isa('MoreStupid'), $s),  't_isa 2');
    ok( t_run(t_isa('Stupid'),     $ms), 't_isa 3');
    ok( t_run(t_isa('MoreStupid'), $ms), 't_isa 4');

    ok( t_run(t_isa('Stupid', t_can('foo')),  $s), 't_isa 5');
    nok(t_run(t_isa('Stupid', t_can('bar')),  $s), 't_isa 6');
    ok( t_run(t_isa('Stupid', t_can('foo')), $ms), 't_isa 7');
    ok( t_run(t_isa('Stupid', t_can('bar')), $ms), 't_isa 8');

    nok(t_run(t_isa('MoreStupid', t_can('foo')),  $s), 't_isa 9');
    nok(t_run(t_isa('MoreStupid', t_can('bar')),  $s), 't_isa 10');
    ok( t_run(t_isa('MoreStupid', t_can('foo')), $ms), 't_isa 11');
    ok( t_run(t_isa('MoreStupid', t_can('bar')), $ms), 't_isa 12');
}

# t_tuplev
{
    my $t1 = t_tuplev(t_str, t_int, t_array(t_even_sized));
    nok(t_run($t1, []),                    't_tuplev 1');
    nok(t_run($t1, ["foo"]),               't_tuplev 2');
    ok( t_run($t1, ["foo" => 1]),          't_tuplev 3');
    nok(t_run($t1, ["foo" => 1, 1]),       't_tuplev 4');
    ok( t_run($t1, ["foo" => 1, 1, 2]),    't_tuplev 5');
    nok(t_run($t1, ["foo" => 1, 1, 2, 3]), 't_tuplev 6');

    my $t2 = t_tuplev(t_int, t_array(t_of t_num));
    nok(t_run($t2, []),         't_tuplev 7');
    ok( t_run($t2, [1]),        't_tuplev 8');
    nok(t_run($t2, [1, "foo"]), 't_tuplev 9');
    ok( t_run($t2, [1, 2]),     't_tuplev 10');

    my $t3 = t_tuplev(t_int, t_array, t_array(t_of t_int));
    ok( t_run($t3, [3,    [], 1,2,3]),     't_tuplev 11');
    ok( t_run($t3, [3, [1,2], 1,2,3]),     't_tuplev 12');
    nok(t_run($t3, [3,    {}, 1,2,3]),     't_tuplev 13');
    nok(t_run($t3, [3,    [], 1,"foo",3]), 't_tuplev 14');

    my $t4 = t_tuplev(t_str, t_int, t_array(t_of(t_str, t_int)));
    ok( t_run($t4, ["foo", 1]),              't_tuplev 15');
    ok( t_run($t4, ["foo", 1, "bar", 2]),    't_tuplev 16');
    nok(t_run($t4, ["foo", 1, "bar"]),       't_tuplev 17');
    nok(t_run($t4, ["foo", "t", "bar", 2]),  't_tuplev 18');
    nok(t_run($t4, ["foo", 1, "bar", 2, 3]), 't_tuplev 19');

    my $t5 = t_tuplev(t_str, t_array(t_of(t_str, t_int)));
    ok( t_run($t5, ["foo"]),                     't_tuplev 15');
    ok( t_run($t5, ["foo", "bar", 2]),           't_tuplev 16');
    ok( t_run($t5, ["foo", "bar", 2, "maz", 3]), 't_tuplev 17');
    nok(t_run($t5, ["foo", "bar", 2, "maz"]),    't_tuplev 18');
    nok(t_run($t5, ["foo", "bar"]),              't_tuplev 19');
}

# t_result
{
    my $res = t_result(t_hash, t_array(t_of t_int));
    ok( t_run($res,   Ok({foo => 1})), 't_result 1');
    ok( t_run($res,       Err([1,2])), 't_result 2');
    nok(t_run($res,        Ok("foo")), 't_result 3');
    nok(t_run($res,       Err("foo")), 't_result 4');
    nok(t_run($res, Err([1,"foo",2])), 't_result 5');
}

done_testing;
