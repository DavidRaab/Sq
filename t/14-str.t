#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

is(Str->length("foo"), 3, 'length 1');
is(array(qw/foo bar baz/)->map(Str->length), [3,3,3], 'length 2');

is(Str->trim("  foo  "), "foo", 'trim 1');
is(
    array("  foo", "  bat ", "\nasd\n")->map(Str->trim),
    ["foo","bat","asd"],
    'trim 2');

is(Str->collapse(" foo   bar "), "foo bar", 'collapse 1');
is(
    array("  foo", "  bat   what ", "\nasd\n")->map(Str->collapse),
    ["foo","bat what","asd"],
    'trim 2');
is(Str->nospace("  foo  space  "), "foospace", 'nospace 1');
is(
    array("  foo  space", "foo what   ")->map(Str->nospace),
    ["foospace", "foowhat"],
    'nospace 2');

fn repeat => Str->repeat;
is(repeat("doo", 3), "doodoodoo", "repeat");

fn starts_with => Str->starts_with;
 ok(starts_with("Hello World!", "Hello"), 'starts_with');
nok(starts_with("Hello World!", "World"), 'starts_with');

fn ends_with => Str->ends_with;
 ok(ends_with("Hello World", "World"),  'ends_with 1');
nok(ends_with("Hello World", "World!"), 'ends_with 2');

fn contains => Str->contains;
my $fox = "The fox jumps over the lazy dog.";
 ok(contains($fox, "fox"),   "contains 1");
nok(contains($fox, "Hello"), "contains 2");

is(array("Foo","Bar")     ->map(Str->lc),      ["foo","bar"],   "lc");
is(array("Foo","Bar")     ->map(Str->uc),      ["FOO","BAR"],   "uc");
is(array("foo\n","bar")   ->map(Str->chomp),   ["foo","bar"],   "chomp");
is(array("foo\n","bar")   ->map(Str->chop),    ["foo","ba"],    "chop");
is(array("foo\n","bar")   ->map(Str->reverse), ["\noof","rab"], "reverse");
is(array("foo","bar")     ->map(Str->ord),     [102,98],        'ord');
is(array("0xff","ff","10")->map(Str->hex),     [255,255,16],    'hex');
is(array(32, 97, 100)     ->map(Str->chr),     [" ", "a","d"],  'chr');

done_testing;
