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

ok( t_valid($is_album, $album),        'check if $album is album');
ok(!t_valid($is_album, $album_wrong1), 'check if $album_wrong1 fails');
ok(
    t_valid($is_album, $album_wrong2),
    '$album_wrong2 is a valid $album because tracks only need to be defined');

ok( t_valid(t_keys(artist => t_str), $album), 'check if album.artist is_str');
ok(!t_valid(t_keys(foo    => t_str), $album), 'album.foo must fail');
ok(
    t_valid(t_keys(artist => t_enum('Michael Jackson')), $album),
    'album is from Michael Jackson');
ok( t_valid($is_album2, $album),        'full album check');
ok(!t_valid($is_album2, $album_wrong2), 'album.tracks not an array');

# t_enum
{
    my $choices = t_enum(qw/yes no maybe/);
    ok( t_valid($choices,   'yes'), 't_enum 1');
    ok( t_valid($choices,    'no'), 't_enum 2');
    ok( t_valid($choices, 'maybe'), 't_enum 3');
    ok(!t_valid($choices,      ''), 't_enum 4');
    ok(!t_valid($choices,      []), 't_enum 5');
    ok(!t_valid($choices,      {}), 't_enum 6');
}

# t_length
{
    ok(!t_valid(t_length(1,10), []         ), 't_length 1');
    ok( t_valid(t_length(1,10), [1]        ), 't_length 2');
    ok( t_valid(t_length(1,10), [1,2]      ), 't_length 3');
    ok(!t_valid(t_length(1,10), {}         ), 't_length 4');
    ok( t_valid(t_length(1,10), {f=>1}     ), 't_length 5');
    ok( t_valid(t_length(1,10), {f=>1,g=>1}), 't_length 6');

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
    ok(!t_valid(t_length(1,10),  "" ), 't_length 17');
    ok( t_valid(t_length(1,10),  "a"), 't_length 18');
    ok( t_valid(t_length(1,10), "ab"), 't_length 19');

    ok(!t_valid(t_length(1,3), ""    ), 't_length 17');
    ok( t_valid(t_length(1,3), "a"   ), 't_length 18');
    ok( t_valid(t_length(1,3), "ab"  ), 't_length 19');
    ok( t_valid(t_length(1,3), "abc" ), 't_length 20');
    ok(!t_valid(t_length(1,3), "abcd"), 't_length 21');
}

# t_of
{
     ok(t_valid(t_of(t_hash), []         ), 't_of 1');
     ok(t_valid(t_of(t_hash), [{}, {}]   ), 't_of 2');
    nok(t_valid(t_of(t_hash), [{}, {}, 1]), 't_of 3');

     ok(t_valid(t_of(t_array), {}                ), 't_of 4');
     ok(t_valid(t_of(t_array), {a=>[]}           ), 't_of 5');
     ok(t_valid(t_of(t_array), {a=>[],b=>[]}     ), 't_of 6');
    nok(t_valid(t_of(t_array), {a=>[],b=>[],c=>1}), 't_of 7');

    # hash with values of either int or array
    my $hash = t_hash(t_of(t_int, t_array));
     ok(t_valid($hash, {foo =>  1}), 't_of 8');
     ok(t_valid($hash, {foo => []}), 't_of 9');
     ok(t_valid($hash, {foo => [], bar => 1}), 't_of 10');
    nok(t_valid($hash, {foo => [], bar => 1, baz => {}}), 't_of 10');
}

# t_valid & t_assert
{
    ok( t_valid(t_hash, {}),     'is hash');
    ok( t_valid(t_hash, {}, {}), 'is hash');
    ok(!t_valid(t_hash, {}, []), 'not all hash');

    like(
        dies { t_assert(t_hash, []) },
        qr/\AType Error/,
        't_assert throws exception'
    );
}

# t_num
{
    ok( t_valid(t_num,   "123"), 't_num 1');
    ok( t_valid(t_num,  "12.3"), 't_num 2');
    ok( t_valid(t_num, "+12.3"), 't_num 3');
    ok( t_valid(t_num, "-12.3"), 't_num 4');
    ok( t_valid(t_num,   "0E0"), 't_num 5');
    ok( t_valid(t_num,       1), 't_num 6');
    ok( t_valid(t_num,     1.2), 't_num 7');

    ok(!t_valid(t_num,      []), 't_num 8');
    ok(!t_valid(t_num,      {}), 't_num 9');
    ok(!t_valid(t_num,   sub{}), 't_num 10');
}

# t_min / t_max / t_range
{
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

# t_min
{
    ok(!t_valid(t_min(10),         0), 't_min 1');
    ok( t_valid(t_min(10),        10), 't_min 2');
    ok( t_valid(t_min(10),        20), 't_min 3');
    ok(!t_valid(t_min(1),         ""), 't_min 4');
    ok( t_valid(t_min(1),        "a"), 't_min 5');
    ok( t_valid(t_min(1),       "ab"), 't_min 6');
    ok(!t_valid(t_min(1),         []), 't_min 7');
    ok( t_valid(t_min(1),        [1]), 't_min 8');
    ok( t_valid(t_min(1),      [1,2]), 't_min 9');
    ok(!t_valid(t_min(1),         {}), 't_min 10');
    ok( t_valid(t_min(1),     {1=>2}), 't_min 11');
    ok( t_valid(t_min(1),     {1..4}), 't_min 12');
    ok(!t_valid(t_min(1), Seq->empty), 't_min 13');
}

# t_max
{
    ok( t_valid(t_max(10),         0), 't_max 1');
    ok( t_valid(t_max(10),        10), 't_max 2');
    ok(!t_valid(t_max(10),        20), 't_max 3');
    ok( t_valid(t_max(1),         ""), 't_max 4');
    ok( t_valid(t_max(1),        "a"), 't_max 5');
    ok(!t_valid(t_max(1),       "ab"), 't_max 6');
    ok( t_valid(t_max(1),         []), 't_max 7');
    ok( t_valid(t_max(1),        [1]), 't_max 8');
    ok(!t_valid(t_max(1),      [1,2]), 't_max 9');
    ok( t_valid(t_max(1),         {}), 't_max 10');
    ok( t_valid(t_max(1),     {1=>2}), 't_max 11');
    ok(!t_valid(t_max(1),     {1..4}), 't_max 12');
    ok(!t_valid(t_max(1), Seq->empty), 't_max 13');
}

# t_positive & t_negative
{
    ok(!t_valid(t_positive, -1), 't_positive 1');
    ok( t_valid(t_positive,  0), 't_positive 2');
    ok( t_valid(t_positive,  1), 't_positive 3');
    ok( t_valid(t_negative, -1), 't_negative 1');
    ok( t_valid(t_negative,  0), 't_negative 2');
    ok(!t_valid(t_negative,  1), 't_negative 3');
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

# t_tuple - size 2
{
    my $kv = t_tuple(t_str, t_int);
    # correct
    ok( t_valid($kv, ["foo", 1]),    'tuple 1');

    # not correct size
    ok(!t_valid($kv, ["foo", 1, 2]), 'tuple 2');
    ok(!t_valid($kv, ["foo"]),       'tuple 3');
    ok(!t_valid($kv, []),            'tuple 4');

    # not array
    ok(!t_valid($kv, {}),            'tuple 5');
    ok(!t_valid($kv, ""),            'tuple 6');
    ok(!t_valid($kv, 1),             'tuple 7');

    # correct size, but types don't match
    ok(!t_valid($kv, [1,"foo"]),     'tuple 8');
}

# t_tuple - size 1
{
    my $str = t_tuple(t_str);
    # correct
    ok( t_valid($str, ["foo"]), 'tuple 9');

    # not correct size
    ok(!t_valid($str,         []), 'tuple 10');
    ok(!t_valid($str, ["foo", 1]), 'tuple 11');
}

# t_tuple - other sizes
{
    ok( t_valid(t_tuple(t_int, t_str, t_array), [12, "foo", []]), 'tuple 12');
    ok(!t_valid(t_tuple(t_int, t_str, t_array), [12, "foo"]    ), 'tuple 13');
    ok(!t_valid(t_tuple(t_int, t_str, t_array), []             ), 'tuple 14');
    ok( t_valid(
            t_tuple(t_int, t_str, t_array(t_of t_int)),
            [12, "foo", [1,2,3]]
        ),
        'tuple 15'
    );
    ok(!t_valid(
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
    ok( t_valid($tot, [[1, "foo"], [2, "bar"]]), 'tuple 17');
    ok(!t_valid($tot, [["foo", 1], [2, "bar"]]), 'tuple 18');
    ok(!t_valid($tot, [[1, "foo"], [2, "bar"], [3, "baz"]]), 'tuple 19');
}

# t_any
{
    # How can i test if t_any really checks against any value? Don't know
    # but i just check some common things.
    ok(t_valid(t_any,             1), 't_any  1');
    ok(t_valid(t_any,         "foo"), 't_any  2');
    ok(t_valid(t_any,            []), 't_any  3');
    ok(t_valid(t_any,            {}), 't_any  4');
    ok(t_valid(t_any,         undef), 't_any  5');
    ok(t_valid(t_any,         sub{}), 't_any  6');
    ok(t_valid(t_any,         sq []), 't_any  7');
    ok(t_valid(t_any,         sq {}), 't_any  8');
    ok(t_valid(t_any,       Some(1)), 't_any  9');
    ok(t_valid(t_any,          None), 't_any 10');
    ok(t_valid(t_any,         Ok(1)), 't_any 11');
    ok(t_valid(t_any,        Err(1)), 't_any 12');
    ok(t_valid(t_any, Seq->new(1,2)), 't_any 13');
    ok(t_valid(t_any,         t_any), 't_any 14');
}

# other simple checks
{
    ok( t_valid(t_sub,       sub{}), 't_sub 1');
    ok(!t_valid(t_sub,          {}), 't_sub 2');
    ok(!t_valid(t_sub,          []), 't_sub 3');
    ok(!t_valid(t_sub,           1), 't_sub 4');
    ok(!t_valid(t_sub,       "foo"), 't_sub 5');

    ok( t_valid(t_regex,      qr//), 't_regex 1');
    ok(!t_valid(t_regex,        ""), 't_regex 2');

    ok( t_valid(t_bool,          0), 't_bool 1');
    ok( t_valid(t_bool,          1), 't_bool 2');
    ok(!t_valid(t_bool,         -1), 't_bool 3');
    ok(!t_valid(t_bool,          2), 't_bool 4');

    ok( t_valid(t_seq, Seq->new(1)), 't_seq 1');
    ok( t_valid(t_seq,  Seq->empty), 't_seq 2');
    ok(!t_valid(t_seq,          {}), 't_seq 3');
    ok(!t_valid(t_seq,       sub{}), 't_seq 4');
    ok(!t_valid(t_seq,          []), 't_seq 5');
}

# t_even_sized
{
    my $es1 = t_even_sized;
    my $es2 = t_array(t_even_sized);

    my $idx = 0;
    for my $es ( $es1, $es2 ) {
        ok( t_valid($es,        []), "$idx: t_even_sized 1");
        ok(!t_valid($es,       [1]), "$idx: t_even_sized 2");
        ok( t_valid($es,     [1,2]), "$idx: t_even_sized 3");
        ok(!t_valid($es,   [1,2,3]), "$idx: t_even_sized 4");
        ok( t_valid($es, [1,2,3,4]), "$idx: t_even_sized 5");
        ok(!t_valid($es,        {}), "$idx: t_even_sized 6");
        ok(!t_valid($es,     "foo"), "$idx: t_even_sized 7");
        ok(!t_valid($es,         1), "$idx: t_even_sized 8");
        $idx++;
    }
}

# t_void
{
    ok( t_valid(t_void, undef), 't_void 1');

    ok(!t_valid(t_void,     1), 't_void 3');
    ok(!t_valid(t_void, "foo"), 't_void 4');
    ok(!t_valid(t_void,    {}), 't_void 6');
}

# t_ref
{
    my $point    = bless({X=>1, Y=>1}, 'Point');
    my $is_point = t_ref('Point');

    ok( t_valid($is_point, $point), 't_ref 1');
    ok(!t_valid($is_point,     {}), 't_ref 2');
    ok(!t_valid($is_point,     []), 't_ref 3');
}

# t_can
{
    my $opt = None;
    ok( t_valid(t_can('map', 'iter'), $opt), 't_methods 1');
    ok(!t_valid(t_can('dope'),        $opt), 't_methods 2');
    ok(!t_valid(t_can('dope'),          []), 't_methods 3');
    ok(!t_valid(t_can('dope'),          {}), 't_methods 4');

    my $is_seq = t_ref('Seq', t_can('map', 'keep'));
    ok( t_valid($is_seq, Seq->empty), 't_ref & t_methods');
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

    ok( t_valid(t_isa('Stupid'),     $s),  't_isa 1');
    ok(!t_valid(t_isa('MoreStupid'), $s),  't_isa 2');
    ok( t_valid(t_isa('Stupid'),     $ms), 't_isa 3');
    ok( t_valid(t_isa('MoreStupid'), $ms), 't_isa 4');

    ok( t_valid(t_isa('Stupid', t_can('foo')),  $s), 't_isa 5');
    ok(!t_valid(t_isa('Stupid', t_can('bar')),  $s), 't_isa 6');
    ok( t_valid(t_isa('Stupid', t_can('foo')), $ms), 't_isa 7');
    ok( t_valid(t_isa('Stupid', t_can('bar')), $ms), 't_isa 8');

    ok(!t_valid(t_isa('MoreStupid', t_can('foo')),  $s), 't_isa 9');
    ok(!t_valid(t_isa('MoreStupid', t_can('bar')),  $s), 't_isa 10');
    ok( t_valid(t_isa('MoreStupid', t_can('foo')), $ms), 't_isa 11');
    ok( t_valid(t_isa('MoreStupid', t_can('bar')), $ms), 't_isa 12');
}

# t_tuplev
{
    my $t1 = t_tuplev(t_str, t_int, t_array(t_even_sized));
    ok(!t_valid($t1, []),                    't_tuplev 1');
    ok(!t_valid($t1, ["foo"]),               't_tuplev 2');
    ok( t_valid($t1, ["foo" => 1]),          't_tuplev 3');
    ok(!t_valid($t1, ["foo" => 1, 1]),       't_tuplev 4');
    ok( t_valid($t1, ["foo" => 1, 1, 2]),    't_tuplev 5');
    ok(!t_valid($t1, ["foo" => 1, 1, 2, 3]), 't_tuplev 6');

    my $t2 = t_tuplev(t_int, t_array(t_of t_num));
    ok(!t_valid($t2, []),         't_tuplev 7');
    ok( t_valid($t2, [1]),        't_tuplev 8');
    ok(!t_valid($t2, [1, "foo"]), 't_tuplev 9');
    ok( t_valid($t2, [1, 2]),     't_tuplev 10');

    my $t3 = t_tuplev(t_int, t_array, t_array(t_of t_int));
    ok( t_valid($t3, [3,    [], 1,2,3]),     't_tuplev 11');
    ok( t_valid($t3, [3, [1,2], 1,2,3]),     't_tuplev 12');
    ok(!t_valid($t3, [3,    {}, 1,2,3]),     't_tuplev 13');
    ok(!t_valid($t3, [3,    [], 1,"foo",3]), 't_tuplev 14');

    my $t4 = t_tuplev(t_str, t_int, t_array(t_of(t_str, t_int)));
    ok( t_valid($t4, ["foo", 1]),              't_tuplev 15');
    ok( t_valid($t4, ["foo", 1, "bar", 2]),    't_tuplev 16');
    ok(!t_valid($t4, ["foo", 1, "bar"]),       't_tuplev 17');
    ok(!t_valid($t4, ["foo", "t", "bar", 2]),  't_tuplev 18');
    ok(!t_valid($t4, ["foo", 1, "bar", 2, 3]), 't_tuplev 19');

    my $t5 = t_tuplev(t_str, t_array(t_of(t_str, t_int)));
    ok( t_valid($t5, ["foo"]),                     't_tuplev 15');
    ok( t_valid($t5, ["foo", "bar", 2]),           't_tuplev 16');
    ok( t_valid($t5, ["foo", "bar", 2, "maz", 3]), 't_tuplev 17');
    ok(!t_valid($t5, ["foo", "bar", 2, "maz"]),    't_tuplev 18');
    ok(!t_valid($t5, ["foo", "bar"]),              't_tuplev 19');
}

# t_result
{
    my $res = t_result(t_hash, t_array(t_of t_int));
    ok( t_valid($res,   Ok({foo => 1})), 't_result 1');
    ok( t_valid($res,       Err([1,2])), 't_result 2');
    nok(t_valid($res,        Ok("foo")), 't_result 3');
    nok(t_valid($res,       Err("foo")), 't_result 4');
    nok(t_valid($res, Err([1,"foo",2])), 't_result 5');
}

done_testing;
