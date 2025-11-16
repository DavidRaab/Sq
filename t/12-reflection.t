#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Math; # Explicitly load module
use Sq::Fs;
use Sq::Test;

# check lazy loading of Sq::Fmt
{
    # Because Sq::Fmt is not loaded by default anymore. `Sq::Fmt::multiline` should
    # not appear in $statics;
    my $statics    = Sq::Reflection::statics;
    my $signatures = Sq::Reflection::signatures;

    nok($statics   ->contains('Sq::Fmt::multiline'), 'No Sq::Fmt::multiline');
    nok($signatures->contains('Sq::Fmt::multiline'), 'No signature for Sq::Fmt::multiline');

    # This line loads Sq::Fmt
    my $multiline = Sq->fmt->multiline;
    ok(is_sub($multiline), '$multiline is sub-ref');

    # reload statics & signatures
    $statics    = Sq::Reflection::statics;
    $signatures = Sq::Reflection::signatures;

    ok($statics   ->contains('Sq::Fmt::multiline'), 'Sq::Fmt::multiline is now available');
    ok($signatures->contains('Sq::Fmt::multiline'), 'Signature also loaded for Sq::Fmt::multiline');
}


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

# Also check if explicitly loading Sq::Math loads signature
ok(
    Sq::Reflection::signatures->contains('Sq::Math::is_prime'),
    'sig for Sq::Math::is_prime loaded');

done_testing;
