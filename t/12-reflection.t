#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Sq::Sig;

my $statics = Sq::Reflection::statics;
check_isa($statics, 'Array', 'statics is Array');

my @statics = (
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
);

# by checking every element with `contains` the test doesn't fail when i add
# new statics. Consider that building a hash is usually A LOT better than
# using ->contains(). Use for example ->count() instead.
#
# Here i use ->contains() to also test that function.
my $idx = 0;
for my $static ( @statics ) {
    ok($statics->contains($static), "statics $idx");
    $idx++;
}

done_testing;
