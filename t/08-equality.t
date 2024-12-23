#!perl
use 5.036;
use Sq;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

# basic tests
ok(sq({})->equal(sq {}), 'hash');
ok(sq([])->equal(sq []), 'array');

# check equal import
ok(equal([], []),     'array');
ok(equal({}, {}),     'hash');
ok(equal(sq({}), {}), 'hash mixed 1');
ok(equal({}, sq({})), 'hash mixed 2');
ok(equal(sq([]), []), 'array mixed 1');
ok(equal([], sq([])), 'array mixed 2');

ok(equal(
    {foo => 1, bar => 2},
    {foo => 1, bar => 2},
), 'struct 1');

ok(equal(
    {foo => [], bar => 2},
    {foo => [], bar => 2},
), 'struct 2');

ok(equal(
    {foo => [1,2,3], bar => 2},
    {foo => [1,2,3], bar => 2},
), 'struct 3');

ok(!equal(
    {foo => [1,2],   bar => 2},
    {foo => [1,2,3], bar => 2},
), 'struct 4');

ok(!equal(
    {foo => [1,2,3], bar => {}},
    {foo => [1,2,3], bar => 2},
), 'struct 5');

ok(equal(
    {foo => [1,2,3], bar => {}},
    {foo => [1,2,3], bar => {}},
), 'struct 6');

ok(equal(
    {foo => [1,2,3], bar => {baz => 1}},
    {foo => [1,2,3], bar => {baz => 1}},
), 'struct 7');

ok(equal(
    [1,2,3],
    [1,2,3],
), 'struct 8');

ok(equal(
    [1,[],3],
    [1,[],3],
), 'struct 9');

ok(equal(
    [1,[6,7],3],
    [1,[6,7],3],
), 'struct 10');

ok(!equal(
    [1,[6,7,8],3],
    [1,[6,7],3],
), 'struct 11');

ok(equal(
    [1,[6,{foo => 1},7],3],
    [1,[6,{foo => 1},7],3],
), 'struct 12');

ok(!equal(
    [1,[6,{foo => 1},7],3],
    [1,[6,{foo => 2},7],3],
), 'struct 13');

ok(!equal(
    [1,[6,{foo => 2},7],3, []],
    [1,[6,{foo => 2},7],3],
), 'struct 14');

ok(equal(
    [1,[6,{foo => 2},7],3, []],
    [1,[6,{foo => 2},7],3, []],
), 'struct 15');

ok(equal(
    [1,[6,{foo => 2},7],3, []],
    [1,[6,{foo => 2},7],3, []],
), 'struct 15');

ok(Array->replicate(3, "foo")->equal(["foo", "foo", "foo"]), 'struct 16');

ok(equal(
    [Some(1, Some(2,3), Some(4))],
    [Some(1,2,3,4)]
), 'struct 17');

ok(equal(
    [Some(1), Some(2), Some(3)],
    [Some(1), Some(2), Some(3)],
), 'struct 18');

ok(equal(
    [Some(1), Some({foo => 1}), Some(3)],
    [Some(1), Some({foo => 1}), Some(3)],
), 'struct 19');

ok(!equal(
    [Some(1), Some({foo => 1}), Some(3)],
    [Some(1), Some({foo => 2}), Some(3)],
), 'struct 20');

ok( equal( Ok(1),  Ok(1)), 'struct 21');
ok(!equal( Ok(1), Err(1)), 'struct 22');
ok(!equal(Err(1),  Ok(1)), 'struct 23');
ok( equal(Err(1), Err(1)), 'struct 24');

ok(equal(
    Ok([]),
    Ok([])),
    'struct 25');

ok(equal(
    Ok([1,2,3]),
    Ok([1,2,3])),
    'struct 26');

ok(!equal(
    Ok([1,2]),
    Ok([1,2,3])),
    'struct 27');

ok(equal(
    Ok([1,{foo => "foo"},3]),
    Ok([1,{foo => "foo"},3])),
    'struct 28');

ok(equal(
    Ok([1,{foo => "foo", bar => []},3]),
    Ok([1,{foo => "foo", bar => []},3])),
    'struct 29');

ok(equal(
    Ok([1,{foo => "foo", bar => [1]},3]),
    Ok([1,{foo => "foo", bar => [1]},3])),
    'struct 30');

ok(equal(
    Ok([1,{foo => "foo", bar => [1,{what => 1}]},3]),
    Ok([1,{foo => "foo", bar => [1,{what => 1}]},3])),
    'struct 31');

ok(!equal(
    Ok([1,{foo => "foo", bar => [1,{what => 1}]},3]),
    Ok([1,{foo => "foo", bar => [1,{what => 2}]},3])),
    'struct 32');

ok(!equal(
     Ok([1,{foo => "foo", bar => [1,{what => 1}]},3]),
    Err([1,{foo => "foo", bar => [1,{what => 1}]},3])),
    'struct 33');

ok(equal(
    Ok("foo"), Ok("foo")
), 'struct 34');

ok(equal(
    Ok(Some("foo")), Ok(Some("foo"))
), 'struct 35');

ok(!equal(
    Ok(Some("foo")), Ok(Some("bar"))
), 'struct 36');

ok(!equal(
    Ok(Some(["foo"])), Ok(Some(["bar"]))
), 'struct 37');

ok(equal(
    Ok(Some(["foo"])), Ok(Some(["foo"]))
), 'struct 38');

ok(!equal(Some(1),       None), 'struct 39');
ok( equal(Some(1,undef), None), 'struct 40');
ok( equal(Some(1, None), None), 'struct 41');
ok( equal(Some(),        None), 'struct 42');
ok(!equal(Some(1),      Ok(1)), 'struct 43');
ok(!equal({}, [1,2,3]),         'struct 44');

ok(equal(
    Seq->init(3, sub($idx) { $idx }),
    Seq->new(0,1,2)
), 'struct 45');

ok(equal(
    Seq
    ->init(100, sub($idx) { $idx })
    ->filter(sub($num) { $num % 2 == 0 })
    ->take(10),
    Seq->new(0,2,4,6,8,10,12,14,16,18)
), 'struct 46');


### Check adding another class to Equality
package Stupid;
sub new($class) { bless({}, $class) }

package main;

my $o1 = Stupid->new;
my $o2 = Stupid->new;
ok(!equal($o1, $o2), 'objects not equal');

# Add Equality for Stupid
Sq::Equality::add_equality(Stupid => sub($o1, $o2) {
    return 1 if builtin::refaddr($o1) == builtin::refaddr($o2);
    return Sq::Equality::hash($o1, $o2);
});

# now check must pass
ok(equal($o1, $o2), 'objects now equal');

done_testing;
