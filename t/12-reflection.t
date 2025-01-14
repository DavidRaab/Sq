#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Sq::Sig;

my $statics = Sq::Reflection::statics;
check_isa($statics, 'Array', 'statics is Array');
is(
    $statics->sort(by_str),
    [
        "Sq::Fmt::table",
        "Sq::Fs::children",
        "Sq::Fs::compare_text",
        "Sq::Fs::make_link",
        "Sq::Fs::read_bytes",
        "Sq::Fs::read_raw",
        "Sq::Fs::read_text",
        "Sq::Fs::read_text_gz",
        "Sq::Fs::recurse",
        "Sq::Fs::sha512",
        "Sq::Math::is_prime",
    ],
    'statics');

done_testing;
