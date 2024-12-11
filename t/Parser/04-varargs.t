#!perl
use 5.036;
use Sq;
use Sq::Parser;
use Test2::V0 qw(is ok done_testing);

# Some functions now take multiple parsers and p_and or p_or them

# p_strc takes multiple args that are p_or
{
    my $digit = p_strc(0 .. 9);

    is(p_run($digit, "012"), Some([0]), 'parses 0');
    is(p_run($digit, "123"), Some([1]), 'parses 1');
    is(p_run($digit, "666"), Some([6]), 'parses 6');
    is(p_run($digit, "a12"),      None, 'no digit');
}

# +: one or many
{
    my $digits = p_join('', p_many(p_strc(0 .. 9)));

    is(p_run($digits,       "0"),      Some(["0"]), 'parses 0');
    is(p_run($digits,      "12"),     Some(["12"]), 'parses 12');
    is(p_run($digits,  "666666"), Some(["666666"]), 'parses 666666');
    is(p_run($digits, "666f666"),    Some(["666"]), 'parses 666');
    is(p_run($digits,     "a12"),             None, 'no digit');
}

# +: one or many
{
    my $num = assign {
        my $to_num = sub($num,$suffix) {
            return $num                      if $suffix eq 'b';
            return $num * 1024               if $suffix eq 'kb';
            return $num * 1024 * 1024        if $suffix eq 'mb';
            return $num * 1024 * 1024 * 1024 if $suffix eq 'gb';
        };

        p_many(
            p_maybe(p_match(qr/\s* , \s*/x)), # optional ,
            p_map(
                $to_num,
                p_many (p_strc(0 .. 9)), # digits
                p_match(qr/\s*/),        # whitespace
                p_strc (qw/b kb mb gb/), # suffix
            )
        );
    };

    is(p_run($num, "1  b, 1kb"),         Some([1, 1024]), '1 b & 1kb');
    is(p_run($num, "1 kb, 1gb"), Some([1024,1073741824]), '1 kb');
    is(p_run($num, "1 mb"),              Some([1048576]), '1 mb');
    is(p_run($num, "1 gb"),           Some([1073741824]), '1 gb');
}

# ?: maybe
{
    my $digits = assign {
        my $digit       = p_strc(0 .. 9);
        my $sign        = p_maybe(p_strc('+', '-'));
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
                p_maybe(p_strc('+', '-')), # sign
                p_many (p_strc(0 .. 9)),   # many digits
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
                p_maybe(p_strc('+', '-')),  # sign
                p_many0(p_strc(' ')),       # zero or more ws
                p_many (p_strc(0 .. 9)),    # many digits
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
                p_maybe(p_strc('+', '-')), # sign
                p_many0(p_str(' ')),       # zero or more ws
                p_many (p_strc(0 .. 9)),   # many digits
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
            p_many0(p_match(qr/\s* , \s*/x), $int)
        );

    is(p_run($int_list,       "1"),           Some([1]), '1 int');
    is(p_run($int_list,     "1,2"),         Some([1,2]), '2 int');
    is(p_run($int_list,  "12,-23"),      Some([12,-23]), '2 int');
    is(p_run($int_list, "12,- 23, 0"), Some([12,-23,0]), '3 int');
}

done_testing;