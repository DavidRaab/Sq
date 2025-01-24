#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Type qw(t_run t_valid type);
use Sq::Test;
use Sq::Gen;
use Path::Tiny qw(path);

# check if inner hash with min => 1 works
my $hash1 = type [hash => [min => 1]];
nok(t_valid($hash1, {}), 'hash must have one key');

my $hoh1 = type [hash => [of => $hash1]];
ok(t_run($hoh1, {}), 'empty hash ok');
nok(t_valid($hoh1, {
    what => {}
}), 'inner hash fails');
ok(t_run($hoh1, {
    what => {
        foo => 1
    },
}), 'at least one');

# this is a test for t_key_is. I uses the structure in my find_duplicates
# example. So just copied the type here.
# This checks for the following structure.
# { FILESIZE => { SHA512 => [FILES] } }
my $is_dup = type
    [hash =>
        [key_is => ['int']], # File-Size
        [of     => [hash =>
            [min    => 1],
            [key_is => [match => qr/\A[0-9a-f]{128}\z/i]], # SHA512
            [of     => [array =>
                [of => [ref => 'Path::Tiny']]]]]]];

ok(t_run($is_dup, {}), 'is_dup 1');

nok(t_valid($is_dup, {
    123 => {},
}), 'is_dup 2');

nok(t_valid($is_dup, {
    123 => { foo => 1 },
}), 'is_dup 3');

ok(t_run($is_dup, {
    "123" => {
        gen_sha512->(), [
            path "/",
            path "/whatever",
        ],
    }
}), 'is_dup 4');

ok(t_run($is_dup, {
    "123" => {
        gen_sha512->(), [
            path "/",
            path "/whatever",
        ],
        gen_sha512->(), [
            path '/foo/bar',
            path '/etc',
        ],
    }
}), 'is_dup 5');

nok(t_valid($is_dup, {
    "123" => {
        "0", [
            path "/",
            path "/whatever",
        ],
        gen_sha512->(), [
            path '/foo/bar',
            path '/etc',
        ],
    }
}), 'is_dup 6');

ok(t_run($is_dup, {
    "123" => {
        gen_sha512->(), [
            path '/',
        ],
        gen_sha512->(), [
            path '/foo/bar',
            path '/etc',
        ],
    }
}), 'is_dup 7');

### Another structure i use in my find_duplicates example
my $num_or_str = type
    [or =>
        [int => [range => 1, 100]],
        [str => [not => ['int']]]];

ok (t_run($num_or_str,          1), 'ns 1');
ok (t_run($num_or_str,        100), 'ns 2');
nok(t_valid($num_or_str,      101), 'ns 3');
nok(t_valid($num_or_str,        0), 'ns 4');
ok (t_run($num_or_str,   "foo123"), 'ns 5');
ok (t_run($num_or_str,     "123f"), 'ns 6');
ok (t_run($num_or_str,     "/asd"), 'ns 7');

done_testing;
