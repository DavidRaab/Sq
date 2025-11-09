#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;
use Scalar::Util qw(refaddr);

# test method
ok(equal(sq({}), sq {}), 'hash 1');
ok(equal(sq({}),  hash), 'hash 2');
ok(equal(sq({}),    {}), 'hash 3');
ok(equal(sq([]), sq []), 'array 1');
ok(equal(sq([]), array), 'array 2');
ok(equal(sq([]),    []), 'array 3');

# check equal import
is([],          [], 'array');
is({},          {}, 'hash');
is(sq({}),      {}, 'hash mixed 1');
is({},      sq({}), 'hash mixed 2');
is(sq([]),      [], 'array mixed 1');
is([],      sq([]), 'array mixed 2');

is(
    {foo => 1, bar => 2},
    {foo => 1, bar => 2},
    'struct 1');

is(
    {foo => [], bar => 2},
    {foo => [], bar => 2},
    'struct 2');

is(
    {foo => [1,2,3], bar => 2},
    {foo => [1,2,3], bar => 2},
    'struct 3');

nok(equal(
    {foo => [1,2],   bar => 2},
    {foo => [1,2,3], bar => 2},
), 'struct 4');

nok(equal(
    {foo => [1,2,3], bar => {}},
    {foo => [1,2,3], bar => 2},
), 'struct 5');

is(
    {foo => [1,2,3], bar => {}},
    {foo => [1,2,3], bar => {}},
    'struct 6');

is(
    {foo => [1,2,3], bar => {baz => 1}},
    {foo => [1,2,3], bar => {baz => 1}},
    'struct 7');

is(
    [1,2,3],
    [1,2,3],
    'struct 8');

is(
    [1,[],3],
    [1,[],3],
    'struct 9');

is(
    [1,[6,7],3],
    [1,[6,7],3],
    'struct 10');

nok(equal(
    [1,[6,7,8],3],
    [1,[6,7],3],
), 'struct 11');

is(
    [1,[6,{foo => 1},7],3],
    [1,[6,{foo => 1},7],3],
    'struct 12');

nok(equal(
    [1,[6,{foo => 1},7],3],
    [1,[6,{foo => 2},7],3],
), 'struct 13');

nok(equal(
    [1,[6,{foo => 2},7],3, []],
    [1,[6,{foo => 2},7],3],
), 'struct 14');

is(
    [1,[6,{foo => 2},7],3, []],
    [1,[6,{foo => 2},7],3, []],
    'struct 15');

is(
    [1,[6,{foo => 2},7],3, []],
    [1,[6,{foo => 2},7],3, []],
    'struct 15');

ok(
    equal(
        Array->replicate(3, "foo"),
        ["foo", "foo", "foo"]
    ),
    'struct 16 A');
is(
    Array->replicate(3, "foo"),
    ["foo", "foo", "foo"],
    'struct 16 B');

is(
    [Some(1, Some(2,3), Some(4))],
    [Some(1,2,3,4)],
    'struct 17');

is(
    [Some(1), Some(2), Some(3)],
    [Some(1), Some(2), Some(3)],
    'struct 18');

is(
    [Some(1), Some({foo => 1}), Some(3)],
    [Some(1), Some({foo => 1}), Some(3)],
    'struct 19');

nok(equal(
    [Some(1), Some({foo => 1}), Some(3)],
    [Some(1), Some({foo => 2}), Some(3)],
), 'struct 20');

ok( equal( Ok(1),  Ok(1)), 'struct 21');
nok(equal( Ok(1), Err(1)), 'struct 22');
nok(equal(Err(1),  Ok(1)), 'struct 23');
ok( equal(Err(1), Err(1)), 'struct 24');

is(
    Ok([]),
    Ok([]),
    'struct 25');

is(
    Ok([1,2,3]),
    Ok([1,2,3]),
    'struct 26');

nok(equal(
    Ok([1,2]),
    Ok([1,2,3])),
    'struct 27');

is(
    Ok([1,{foo => "foo"},3]),
    Ok([1,{foo => "foo"},3]),
    'struct 28');

is(
    Ok([1,{foo => "foo", bar => []},3]),
    Ok([1,{foo => "foo", bar => []},3]),
    'struct 29');

is(
    Ok([1,{foo => "foo", bar => [1]},3]),
    Ok([1,{foo => "foo", bar => [1]},3]),
    'struct 30');

is(
    Ok([1,{foo => "foo", bar => [1,{what => 1}]},3]),
    Ok([1,{foo => "foo", bar => [1,{what => 1}]},3]),
    'struct 31');

nok(equal(
    Ok([1,{foo => "foo", bar => [1,{what => 1}]},3]),
    Ok([1,{foo => "foo", bar => [1,{what => 2}]},3])),
    'struct 32');

nok(equal(
     Ok([1,{foo => "foo", bar => [1,{what => 1}]},3]),
    Err([1,{foo => "foo", bar => [1,{what => 1}]},3])),
    'struct 33');

is(Ok("foo"), Ok("foo"),             'struct 34');
is(Ok(Some("foo")), Ok(Some("foo")), 'struct 35');

nok(equal(
    Ok(Some("foo")), Ok(Some("bar"))
), 'struct 36');

nok(equal(
    Ok(Some(["foo"])), Ok(Some(["bar"]))
), 'struct 37');

is(Ok(Some(["foo"])), Ok(Some(["foo"])), 'struct 38');

nok(equal(Some(1),       None), 'struct 39');
ok( equal(Some(1,undef), None), 'struct 40');
ok( equal(Some(1, None), None), 'struct 41');
ok( equal(Some(),        None), 'struct 42');
nok(equal(Some(1),      Ok(1)), 'struct 43');
nok(equal({}, [1,2,3]),         'struct 44');

is(
    Seq->init(3, sub($idx) { $idx }),
    Seq->new(0,1,2),
    'struct 45');

is(
    Seq
    ->range(0,99)
    ->keep(sub($num) { $num % 2 == 0 })
    ->take(10),
    seq { 0,2,4,6,8,10,12,14,16,18 },
    'struct 46');

nok(equal(
    seq { 1,2,3 },
    seq { 4,5,6 },
), 'struct 48');

nok(equal(
    Seq->init(1_000_000_000, sub($idx) { $idx }),
    seq { 3 },
), 'struct 49');

is(
    sq({
        Artist => 'Queen',
        Title  => 'Greatest Hits',
        Tracks => seq {
            { Title => 'We will Rock You'          },
            { Title => 'Radio Gaga'                },
            { Title => 'Who Wants To Life Forever' },
            { Title => "You Don't Fool Me"         },
        },
        Tags => Some(qw/80/),
    }),
    {
        Artist => 'Queen',
        Title  => 'Greatest Hits',
        Tracks => seq {
            { Title => 'We will Rock You'          },
            { Title => 'Radio Gaga'                },
            { Title => 'Who Wants To Life Forever' },
            { Title => "You Don't Fool Me"         },
        },
        Tags => Some(qw/80/),
    },
    'struct 50');

nok(equal(
    sq({
        Artist => 'Queen',
        Title  => 'Greatest Hits',
        Tracks => seq {
            { Title => 'We will Rock You'          },
            { Title => 'Radio Gaga'                },
            { Title => 'Who Wants To Life Forever' },
            { Title => "You Don't Fool Me"         },
        },
        Tags => Some(qw/80/),
    }),
    {
        Artist => 'Queen',
        Title  => 'Greatest Hits',
        Tracks => seq {
            { Title => 'We will Rock You'          },
            { Title => 'Radio Gaga!'               },
            { Title => 'Who Wants To Life Forever' },
            { Title => "You Don't Fool Me"         },
        },
        Tags => Some(qw/80/),
    }),
    'struct 51');

ok(
    equal(
        sq({
            Artist => 'Queen',
            Title  => 'Greatest Hits',
            Tracks => seq {
                { Title => 'We will Rock You'          },
                { Title => 'Radio Gaga'                },
                { Title => 'Who Wants To Life Forever' },
                { Title => "You Don't Fool Me"         },
            },
            Tags => Some(qw/80/),
        }),
        {
            Artist => 'Queen',
            Title  => 'Greatest Hits',
            Tracks => seq {
                { Title => 'We will Rock You'          },
                { Title => 'Radio Gaga'                },
                { Title => 'Who Wants To Life Forever' },
                { Title => "You Don't Fool Me"         },
            },
            Tags => Some(qw/80/),
        }),
        'struct 52');

{
    my $character = sq {
        Name   => 'Me',
        X      => 100,
        Y      => 100,
        Health => 100,
    };

    my $circle = sq {
        X      => 100,
        Y      => 100,
        Radius => 50,
    };

    # equal on portion of two hashes
    is(
        $character->slice(qw/X Y/),
        $circle->slice(qw/X Y/),
        'struct 53');
}

 ok(equal(undef, undef), 'undef is equal');
nok(equal(undef, 1),     'one value is undef 1');
nok(equal(1, undef),     'one value is undef 2');
nok(equal("foo", 1),     'string and num');
nok(equal(1, "foo"),     'num and string');
 ok(equal("123", 123),   'nums one as a sring');

### Check adding another class to Equality
package Stupid;
sub new($class) { bless({}, $class) }

package main;

my $o1 = Stupid->new;
my $o2 = Stupid->new;
nok(equal($o1, $o2), 'objects not equal');

# Add Equality for Stupid
Sq::Equality::add_equality(Stupid => sub($o1, $o2) {
    return 1 if refaddr($o1) == refaddr($o2);
    return Sq::Equality::hash($o1, $o2);
});

# now check must pass
is($o1, $o2, 'objects now equal');

done_testing;
