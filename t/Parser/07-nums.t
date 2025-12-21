#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Parser;
use Sq::Test;

# Go's definition of numbers. Expressed in EBNF
# https://go.dev/ref/spec#decimal_digit
#
# int_lit        = decimal_lit | binary_lit | octal_lit | hex_lit .
# decimal_lit    = "0" | ( "1" … "9" ) [ [ "_" ] decimal_digits ] .
# binary_lit     = "0" ( "b" | "B" ) [ "_" ] binary_digits .
# octal_lit      = "0" [ "o" | "O" ] [ "_" ] octal_digits .
# hex_lit        = "0" ( "x" | "X" ) [ "_" ] hex_digits .
#
# decimal_digits = decimal_digit { [ "_" ] decimal_digit } .
# binary_digits  = binary_digit { [ "_" ] binary_digit } .
# octal_digits   = octal_digit { [ "_" ] octal_digit } .
# hex_digits     = hex_digit { [ "_" ] hex_digit } .
#
# decimal_digit = "0" … "9" .
# binary_digit  = "0" | "1" .
# octal_digit   = "0" … "7" .
# hex_digit     = "0" … "9" | "A" … "F" | "a" … "f" .


my $decimal_lit = p_matchf(qr/\A ([0-9]) _? ([0-9] (?:_? [0-9])* )\z/x, sub($d,$r) {
    return $d . ($r =~ s/_//gr );
});
my $binary_lit  = p_matchf(qr/\A 0[bB] _? ([01] (?:_? [01])* )\z/x, sub($bin){
    oct("0b" . $1)
});
my $octal_lit   = p_matchf(qr/\A 0[oO] _? ([0-7] (?:_? [0-7])* )\z/x, sub($oct){
    oct($1);
});
my $hex_lit     = p_matchf(qr/\A 0x _? ([0-9a-f] (?:_? [0-9a-f])* )\z/xi, sub($hex) {
    oct("0x" . $hex);
});

my $int_lit = p_or($decimal_lit, $binary_lit, $octal_lit, $hex_lit);

# This is already a "compact" version how i would write it. Every lit
# as a single regex. But you also could seperate every lit into more components
# like:
#
# my $decimal_digit  = p_match(qr/[0-9]/);
# my $decimal_digits =
#    p_and(
#        $decimal_digit,
#        p_many0(
#            p_maybe(p_str('_')),
#            $decimal_digit));
#
# But making this work is just more code and slower for no reason.
#
# Just as a note.
#
# In EBNF [] is basically just the star "*" or "?" in regex. You can put it
# behind everything including a whole group and it makes it optional or
# reapeats 0 or more time. The EBNF {} is just a "+" behind a group
# Alternation is also |.
#
# With some more work you probably even can make a single regex from everything.
# Consider you also can write:
#
# my $decimal_digit = qr/[0-9]/;
#
# in perl and it just saves this regex in a variable. This again can be used
# inside another regex.
#
# my $decimal_digits = qr/$decimal_digit (?: _? $decimal_digit)*/x;
#
# ...
#
# my $int_lit = qr/(?: $decimal_lit | $binary_lit | $hex_lit | $oct_lit )/x;

sub parse_int($str) {
    p_runr($int_lit, $str)->map(sub($p) { $p->{matches}[0] })
}

my $err = Err({pos => 0, valid => 0});
is(parse_int(  "0b0"),    Ok(0), 'binary 0');
is(parse_int(  "0b1"),    Ok(1), 'binary 1');
is(parse_int( "0b10"),    Ok(2), 'binary 2');
is(parse_int( "0b11"),    Ok(3), 'binary 3');
is(parse_int("0b100"),    Ok(4), 'binary 4');
is(parse_int("0b101"),    Ok(5), 'binary 5');
is(parse_int("0b110"),    Ok(6), 'binary 6');
is(parse_int("0b111"),    Ok(7), 'binary 7');
is(parse_int("0b1_1_1"),  Ok(7), 'binary 8');
is(parse_int("0b1__1"),    $err, 'binary 9');

is(parse_int(   "42"),     Ok(42), 'int 1');
is(parse_int(  "4_2"),     Ok(42), 'int 2');
is(parse_int( "0600"), Ok("0600"), 'int 3');
is(parse_int("0_600"), Ok("0600"), 'int 4');
is(
    parse_int("170141183460469231731687303715884105727"),
    Ok("170141183460469231731687303715884105727"),
    'int 5');

is(
    parse_int("170_141183_460469_231731_687303_715884_105727"),
    Ok("170141183460469231731687303715884105727"),
    'int 6');

is(parse_int("0o600"), Ok(384), 'oct 1');
is(parse_int("0O600"), Ok(384), 'oct 2');

is(parse_int("0xBadFace"),            Ok(195951310),       'hex 1');
is(parse_int("0xBad_Face"),           Ok(195951310),       'hex 2');
# TODO
# Emits warning; so disabled.
# it works but complains about non-portability because hex number is bigger than 32bit
# is(parse_int("0x_67_7a_2f_cc_40_c6"), Ok(113774485586118), 'hex 3');

is(parse_int("_42"),        $err, "invalid 1"); # an identifier, not an integer literal
is(parse_int("42_"),        $err, "invalid 2"); # invalid: _ must separate successive digits
is(parse_int("4__2"),       $err, "invalid 3"); # invalid: only one _ at a time
is(parse_int("0_xBadFace"), $err, "invalid 4"); # invalid: _ must separate successive digits

done_testing;
