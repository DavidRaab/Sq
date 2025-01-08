#!perl
use 5.036;
use Sq;
use Sq::Parser -sig => 1;
use Sq::Test;
use Sq::Sig;

# This is the Test file created while writing the intro to Sq::Parser

# start
{
    my $zero = p_strc('0');

    is(p_run($zero,   "0"), Some([0]), 'parses 0');
    is(p_run($zero,   "1"),      None, 'do not parse 1');
    is(p_run($zero, "012"), Some([0]), 'parses 0');
}

# or: alternatives
{
    my $digit = p_or(
        p_strc('0'),
        p_strc('1'),
        p_strc('2'),
        p_strc('3'),
        p_strc('4'),
        p_strc('5'),
        p_strc('6'),
        p_strc('7'),
        p_strc('8'),
        p_strc('9'),
    );

    is(p_run($digit, "012"), Some([0]), 'parses 0');
    is(p_run($digit, "123"), Some([1]), 'parses 1');
    is(p_run($digit, "666"), Some([6]), 'parses 6');
    is(p_run($digit, "a12"),      None, 'no digit');
}

# or: alternative
{
    my $digit = p_or(map { p_strc($_) } 0 .. 9);

    is(p_run($digit, "012"), Some([0]), 'parses 0');
    is(p_run($digit, "123"), Some([1]), 'parses 1');
    is(p_run($digit, "666"), Some([6]), 'parses 6');
    is(p_run($digit, "a12"),      None, 'no digit');
}

# and: chaining
{
    my $digit  = p_or(map { p_strc($_) } 0 .. 9);
    my $digit3 = p_and($digit, $digit, $digit);

    is(p_run($digit3, "012"), Some([0,1,2]), 'parses 012');
    is(p_run($digit3, "123"), Some([1,2,3]), 'parses 123');
    is(p_run($digit3, "666"), Some([6,6,6]), 'parses 666');
    is(p_run($digit3, "a12"),          None, 'no digit');
}

# map
{
    my $digit3 = assign {
        my $digit = p_or(map { p_strc($_) } 0 .. 9);
        my $three = p_and($digit, $digit, $digit);
        return p_map(sub(@xs) { join '', @xs }, $three);
    };

    is(p_run($digit3, "012"), Some(["012"]), 'parses 012');
    is(p_run($digit3, "123"), Some(["123"]), 'parses 123');
    is(p_run($digit3, "666"), Some(["666"]), 'parses 666');
    is(p_run($digit3, "a12"),          None, 'no digit');
}

# Joining
{
    my $digit3 = assign {
        my $digit = p_or(map { p_strc($_) } 0 .. 9);
        return p_join('', p_and($digit, $digit, $digit));
    };

    is(p_run($digit3, "012"), Some(["012"]), 'parses 012');
    is(p_run($digit3, "123"), Some(["123"]), 'parses 123');
    is(p_run($digit3, "666"), Some(["666"]), 'parses 666');
    is(p_run($digit3, "a12"),          None, 'no digit');
}

# Quantity
{
    my $digit10 = assign {
        my $digit = p_or(map { p_strc($_) } 0 .. 9);
        return p_join('', p_qty(1, 10, $digit));
    };

    is(p_run($digit10,       "0"),      Some(["0"]), 'parses 0');
    is(p_run($digit10,      "12"),     Some(["12"]), 'parses 12');
    is(p_run($digit10,  "666666"), Some(["666666"]), 'parses 666666');
    is(p_run($digit10, "666f666"),    Some(["666"]), 'parses 666');
    is(p_run($digit10,     "a12"),             None, 'no digit');
}

# +: one or many
{
    my $digits = assign {
        my $digit = p_or(map { p_strc($_) } 0 .. 9);
        return p_join('', p_many($digit));
    };

    is(p_run($digits,       "0"),      Some(["0"]), 'parses 0');
    is(p_run($digits,      "12"),     Some(["12"]), 'parses 12');
    is(p_run($digits,  "666666"), Some(["666666"]), 'parses 666666');
    is(p_run($digits, "666f666"),    Some(["666"]), 'parses 666');
    is(p_run($digits,     "a12"),             None, 'no digit');
}

# ?: maybe
{
    my $digits = assign {
        my $digit       = p_or(map { p_strc($_) } 0 .. 9);
        my $sign        = p_maybe(p_or(p_strc('+'), p_strc('-')));
        my $sign_digits = p_and($sign, p_many($digit));
        return p_join('', $sign_digits);
    };

    is(p_run($digits,       "0"),      Some(["0"]), 'parses 0');
    is(p_run($digits,      "12"),     Some(["12"]), 'parses 12');
    is(p_run($digits,     "+13"),    Some(["+13"]), 'parses +13');
    is(p_run($digits,  "666666"), Some(["666666"]), 'parses 666666');
    is(p_run($digits, "666f666"),    Some(["666"]), 'parses 666');
    is(p_run($digits, "-666f666"),  Some(["-666"]), 'parses -666');
    is(p_run($digits,     "a12"),             None, 'no digit');
}

# No variables
{
    my $digits =
        p_join('',
            p_and(
                p_maybe(p_or(p_strc('+'), p_strc('-'))), # sign
                p_many (p_or(map { p_strc($_) } 0 .. 9))  # many digits
            )
        );

    is(p_run($digits,       "0"),      Some(["0"]), 'parses 0');
    is(p_run($digits,      "12"),     Some(["12"]), 'parses 12');
    is(p_run($digits,     "+13"),    Some(["+13"]), 'parses +13');
    is(p_run($digits,  "666666"), Some(["666666"]), 'parses 666666');
    is(p_run($digits, "666f666"),    Some(["666"]), 'parses 666');
    is(p_run($digits, "-666f666"),  Some(["-666"]), 'parses -666');
    is(p_run($digits,     "a12"),             None, 'no digit');
}

# Zero or More
{
    my $int =
        p_join('',
            p_and(
                p_maybe(p_or(p_strc('+'), p_strc('-'))),  # sign
                p_many0(p_strc(' ')),                     # zero or more ws
                p_many (p_or(map { p_strc($_) } 0 .. 9)), # many digits
            )
        );

    is(p_run($int,        "0"),     Some(["0"]), 'parses 0');
    is(p_run($int,       "12"),    Some(["12"]), 'parses 12');
    is(p_run($int,      "+13"),   Some(["+13"]), 'parses +13');
    is(p_run($int,    "- 666"), Some(["- 666"]), 'parses - 666');
    is(p_run($int,    "+ 666"), Some(["+ 666"]), 'parses + 666');
    is(p_run($int,  "666f666"),   Some(["666"]), 'parses 666');
    is(p_run($int, "-666f666"),  Some(["-666"]), 'parses -666');
    is(p_run($int,      "a12"),            None, 'no digit');
}

# No capture
{
    my $int =
        p_join('',
            p_and(
                p_maybe(p_or(p_strc('+'), p_strc('-'))),  # sign
                p_many0(p_str(' ')),                      # zero or more ws
                p_many (p_or(map { p_strc($_) } 0 .. 9)), # many digits
            )
        );

    is(p_run($int,        "0"),    Some(["0"]), 'parses 0');
    is(p_run($int,       "12"),   Some(["12"]), 'parses 12');
    is(p_run($int,      "+13"),  Some(["+13"]), 'parses +13');
    is(p_run($int,    "- 666"), Some(["-666"]), 'parses -666');
    is(p_run($int,    "+ 666"), Some(["+666"]), 'parses +666');
    is(p_run($int,  "666f666"),  Some(["666"]), 'parses 666');
    is(p_run($int, "-666f666"), Some(["-666"]), 'parses -666');
    is(p_run($int,      "a12"),           None, 'no digit');
}

# using regex
{
    my $int = p_match(qr/([+-]? \s* \d+)/x);

    is(p_run($int,        "0"),    Some(["0"]), 'parses 0');
    is(p_run($int,       "12"),   Some(["12"]), 'parses 12');
    is(p_run($int,      "+13"),  Some(["+13"]), 'parses +13');
    is(p_run($int,    "- 666"), Some(["- 666"]), 'parses -666');
    is(p_run($int,    "+ 666"), Some(["+ 666"]), 'parses +666');
    is(p_run($int,  "666f666"),  Some(["666"]), 'parses 666');
    is(p_run($int, "-666f666"), Some(["-666"]), 'parses -666');
    is(p_run($int,      "a12"),           None, 'no digit');
}

# using regex two matches
{
    my $int = p_match(qr/([+-])? \s* (\d+)/x);

    is(p_run($int,        "0"),    Some([undef, "0"]), 'parses 0');
    is(p_run($int,       "12"),   Some([undef, "12"]), 'parses 12');
    is(p_run($int,      "+13"),     Some(["+", "13"]), 'parses +13');
    is(p_run($int,    "- 666"),    Some(["-", "666"]), 'parses -666');
    is(p_run($int,    "+ 666"),    Some(["+", "666"]), 'parses +666');
    is(p_run($int,  "666f666"),  Some([undef, "666"]), 'parses 666');
    is(p_run($int, "-666f666"),    Some(["-", "666"]), 'parses -666');
    is(p_run($int,      "a12"),                  None, 'no digit');
}

# match and transform
{
    my $int = p_matchf(qr/([+-])? \s* (\d+)/x, sub($sign,$num) {
        if ( defined $sign ) {
            return $sign eq '-' ? $num*-1 : $num;
        }
        return $num;
    });

    is(p_run($int,        "0"),    Some([0]), 'parses 0');
    is(p_run($int,       "12"),   Some([12]), 'parses 12');
    is(p_run($int,      "+13"),   Some([13]), 'parses 13');
    is(p_run($int,    "- 666"), Some([-666]), 'parses -666');
    is(p_run($int,    "+ 666"),  Some([666]), 'parses 666');
    is(p_run($int,  "666f666"),  Some([666]), 'parses 666');
    is(p_run($int, "-666f666"), Some([-666]), 'parses -666');
    is(p_run($int,      "a12"),         None, 'no digit');
}

# match and keep
{
    my $hundred = p_matchf(qr/([+-])? \s* (\d+)/x, sub($sign,$num) {
        my $result = $num;
        if ( defined $sign && $sign eq '-' ) {
            $result = $result * -1;
        }
        if ( $result >= 0 && $result <= 100 ) {
            return $result;
        }
        return;
    });

    is(p_run($hundred,        "0"),    Some([0]), 'parses 0');
    is(p_run($hundred,       "12"),   Some([12]), 'parses 12');
    is(p_run($hundred,      "+13"),   Some([13]), 'parses 13');
    is(p_run($hundred,    "- 666"),         None, 'not valid');
    is(p_run($hundred,    "+ 666"),         None, 'not valid');
    is(p_run($hundred,  "666f666"),         None, 'not valid');
    is(p_run($hundred, "-666f666"),         None, 'not valid');
    is(p_run($hundred,      "a12"),         None, 'not valid');
}

# integer list
{
    my $int = p_matchf(qr/([+-])? \s* (\d+)/x, sub($sign,$num) {
        my $result = $num;
        $result *= -1 if defined $sign && $sign eq '-';
        return $result;
    });

    my $int_list =
        p_and(
            $int,
            p_many0(p_and(p_match(qr/\s* , \s*/x), $int)),
        );

    is(p_run($int_list,       "1"),           Some([1]), '1 int');
    is(p_run($int_list,     "1,2"),         Some([1,2]), '2 int');
    is(p_run($int_list,  "12,-23"),      Some([12,-23]), '2 int');
    is(p_run($int_list, "12,- 23, 0"), Some([12,-23,0]), '3 int');
}

done_testing;