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

# chunk of 0 dies
like(
    dies { Str->chunk("0123456789", 0), ["012", "345", "678", "9"] },
    qw/\ASq::Core::Str::chunk/,
    'chunk 0');

is(Str->chunk("0123456789", 1),  [qw/0 1 2 3 4 5 6 7 8 9/],  'chunk 1');
is(Str->chunk("0123456789", 3),  ["012", "345", "678", "9"], 'chunk 3');
is(Str->chunk("0123456789", 20), ["0123456789"],             'chunk 20');
is(
    Str->chunk("0123456789", 3)->join(","),
    "012,345,678,9",
    "chunk->join");

is(Str->map("abc", sub($char) { ord $char }), "979899", 'map 1');
is(Str->map("abc", Str->ord),                 "979899", 'map 2');

is(Str->keep  ("0123456789", sub($char) { $char % 2 == 0 }), "02468", 'keep');
is(Str->remove("0123456789", sub($char) { $char % 2 == 0 }), "13579", 'remove');

is(
    Str->keep("foo 1&23-asd", sub($char) { $char =~ m/(?: [a-zA-Z0-9] | \s | - ) /x }),
    Str->keep("foo 1&23-asd", qr/(?: [a-zA-Z0-9] | \s | - ) /x),
    'keep with a regex');

# split
{
    my $str    = "abc def ghi jkl mno p";
    my $threes = Str->split(qr/\s+/, $str);
    check_isa($threes, 'Array', 'split returns Sq Array');
    is($threes, [qw/abc def ghi jkl mno p/], 'content from split');
}

# is_empty
ok(Str->is_empty(undef), 'is_empty 0');
ok(Str->is_empty(""),    'is_empty 1');
ok(Str->is_empty(" "),   'is_empty 2');
ok(Str->is_empty("  "),  'is_empty 3');
nok(Str->is_empty(" a"), 'is_empty 4');

done_testing;
