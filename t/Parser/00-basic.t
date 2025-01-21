#!perl
use 5.036;
use Sq;
use Sq::Parser -sig => 1;
use Sq::Test;
use Sq::Sig;

# check if "-sig => 1" loads Signature
like(
    dies { p_match("asd") },
    qr/\ASq::Parser::p_match/,
    'type check must fail because of signature'
);

# Some parsers
my $word = p_match(qr/([a-zA-Z]+)/);
my $ws   = p_match(qr/\s++/);
my $int  = p_match(qr/(\d++)/);
my $hex  = p_map(Str->hex, p_match(qr/0x([0-9a-zA-Z]+)/));

# Helper function to build result
sub result(@xs) { Some([@xs]) }

# basics
{
    my $p_hello = p_match(qr/(Hello)/);
    my $p_world = p_match(qr/(World)/);
    my $length  = p_map(Str->length, $p_hello);

    my $greeting = "Hello, World!";
    is(p_run($p_hello, $greeting), result('Hello'), 'starts with hello');
    is(p_run($length,  $greeting),       result(5), 'length of hello');
    is(p_run($p_world, $greeting),            None, 'does not start with world');
    is(p_run($int,    "12345foo"), result("12345"), 'extracted int');
    is(p_run($int,      "foo123"),            None, 'no int at start');
    is(p_run($hex,    "0xff 123"),     result(255), 'extract hex');
}

# bind correct?
{
    # for testing i implement map through bind, and then check if map works correctly
    my sub pmap($p, $f) {
        p_bind($p, sub(@xs) { p_return $f->(@xs) });
    }

    my $int  = p_match(qr/(\d+)/);
    my $incr = pmap($int, sub($x) { $x + 1 });
    is(p_run($incr, "12"), result(13), 'map through bind');
    is(
        p_run(p_and($incr, $ws, $incr, $ws, $incr), '12 13 14'),
        result(13, 14, 15),
        'extract and increment');
}

# p_and
{
    my $p_comma  = p_match(qr/,/);
    my $greeting = p_and($word, $p_comma, $ws, $word);

    is(p_run($greeting, "HELLO, WORLD!"),   result("HELLO", "WORLD"), 'parse greeting 1');
    is(p_run($greeting, "hello, world!"),   result("hello", "world"), 'parse greeting 2');
    is(p_run($greeting, "hElLo,   wOrLd!"), result("hElLo", "wOrLd"), 'parse greeting 3');
    is(p_run($greeting, "helloworld!"),                         None, 'no greeting');
}

# p_or
{
    my $num = p_or($hex, $int);

    is(p_run($num, '12345'), result(12345), '$num parses int');
    is(p_run($num, '0xff'),    result(255), '$num parses hex');
    is(p_run($num, 'abc'),            None, '$num on non-number');
}

# p_maybe / p_join
{
    my $sign = p_or(p_strc('+'), p_strc('-'));
    my $int  = p_and(p_maybe($sign), p_match(qr/(\d+)/)); # Regex: ([+-]?\d+)

    is(p_run($int, '1234foo'),  result('1234'),      '$int parses just int');
    is(p_run($int, '+1234foo'), result('+', '1234'), '$int with + sign');
    is(p_run($int, '-1234foo'), result('-', '1234'), '$int with - sign');

    my $jint = p_join('', $int);
    is(p_run($jint, '1234foo'),  result( '1234'), '$jint parses just int');
    is(p_run($jint, '+1234foo'), result('+1234'), '$jint with + sign');
    is(p_run($jint, '-1234foo'), result('-1234'), '$jint with - sign');
}

# p_many, p_many0
{
    # Regex: (\d+) (?: (\d+) , )*
    my $int0 = p_and($int, p_many0(p_and(p_str(','), $int)));
    # Regex: (\d+) (?: (\d+) , )+
    my $int1 = p_and($int, p_many (p_and(p_str(','), $int)));

    is(p_run($int0, '123'),                          result(123), '$int0 list');
    is(p_run($int1, '123'),                                 None, '$int1 list');
    is(p_run($int0, '123,12,300,420'), result(123, 12, 300, 420), '$int0 list 2');
    is(p_run($int1, '123,12,300,420'), result(123, 12, 300, 420), '$int1 list 2');

    my $p_array = p_map(sub(@xs) { [@xs] }, $int0);
    is(p_run($p_array, '1,2,3,420'), result([1,2,3,420]), 'parses to array');
}

# p_match with many captures
{
    my $time = p_match(qr/(\d\d?):(\d\d?)/);
    is(p_run($time, '12:34'), result(12,34), 'extracts 2 vars 1');
    is(p_run($time, '1:3'),     result(1,3), 'extracts 2 vars 2');
    is(p_run($time, '123:12'),         None, 'no time');

    # valid_time with bind
    my $valid_time_b = p_bind($time, sub($hour,$min) {
        $hour < 24 && $min < 60
            ? p_return $hour,$min
            : p_fail;
    });

    is(p_run($valid_time_b, '23:59'), result(23,59), 'valid time bind 1');
    is(p_run($valid_time_b,   '0:0'),   result(0,0), 'valid time bind 2');
    is(p_run($valid_time_b, '23:60'),          None, 'valid time bind 3');
    is(p_run($valid_time_b,  '0:60'),          None, 'valid time bind 4');
    is(p_run($valid_time_b,  '24:0'),          None, 'valid time bind 5');

    # valid_time with choose
    my $valid_time_c = p_choose($time, sub($hour,$min) {
        $hour < 24 && $min < 60 ? Some $hour,$min : None;
    });

    is(p_run($valid_time_c, '23:59'), result(23,59), 'valid time choose 1');
    is(p_run($valid_time_c,   '0:0'),   result(0,0), 'valid time choose 2');
    is(p_run($valid_time_c, '23:60'),          None, 'valid time choose 3');
    is(p_run($valid_time_c,  '0:60'),          None, 'valid time choose 4');
    is(p_run($valid_time_c,  '24:0'),          None, 'valid time choose 5');

    # valid_time with matchf
    my $valid_time_m = p_matchf(qr/(\d\d?):(\d\d?)/, sub($hour,$min) {
        $hour < 24 && $min < 60 ? ($hour,$min) : ();
    });

    is(p_run($valid_time_m, '23:59'), result(23,59), 'valid time matchf 1');
    is(p_run($valid_time_m,   '0:0'),   result(0,0), 'valid time matchf 2');
    is(p_run($valid_time_m, '23:60'),          None, 'valid time matchf 3');
    is(p_run($valid_time_m,  '0:60'),          None, 'valid time matchf 4');
    is(p_run($valid_time_m,  '24:0'),          None, 'valid time matchf 5');
}

# p_matchf
{
    my $hex1 = p_map(Str->hex, p_match(qr/0x([0-9a-zA-Z]+)/));
    my $hex2 = p_matchf(qr/0x([0-9a-zA-Z]+)/, Str->hex);

    is(p_run($hex1, "0xff 123"), result(255), '$hex1 ff');
    is(p_run($hex2, "0xff 123"), result(255), '$hex2 ff');

    is(p_run($hex1, "0xffff 123"), result(65535), '$hex1 ffff');
    is(p_run($hex2, "0xffff 123"), result(65535), '$hex2 ffff');

    # parses percentage only between 0% - 100%
    my $percent = p_matchf_opt(qr/(\d{1,3}) \s* %/x, sub($num) {
        $num >= 0 && $num <= 100 ? Some $num : None;
    });

    is(p_run($percent,   '0%'),   result(0),   '0%');
    is(p_run($percent,  '10%'),  result(10),  '10%');
    is(p_run($percent, '100%'), result(100), '100%');
    is(p_run($percent, '110%'),        None, '110%');
    is(p_run($percent, '10 %'),  result(10), '10 %');
}

# p_ignore
{
    # Regex: [+-](\d+)
    my $sign = p_or(p_strc('+'), p_strc('-'));
    my $pint = p_and( p_ignore($sign), $int );

    is(p_run($pint, '+1234'), result(1234), 'ignore 1');
    is(p_run($pint, '-1234'), result(1234), 'ignore 2');
}

# p_qty
{
    # Regex: ( \d{1,3} ){1,3}
    my $three = p_qty(1, 3, p_match(qr/(\d{1,3})/));

    is(p_run($three,          '1'),             result(1), 'p_qty 1');
    is(p_run($three,        '123'),           result(123), 'p_qty 2');
    is(p_run($three,    '1234567'),   result(123, 456, 7), 'p_qty 3');
    is(p_run($three, '1234567890'), result(123, 456, 789), 'p_qty 4');

    # Regex: \d{3}
    my $d3 = p_repeat(3, p_match(qr/(\d)/));
    is(p_run($d3,    '1'),          None, 'p_repeat 1');
    is(p_run($d3,   '12'),          None, 'p_repeat 2');
    is(p_run($d3,  '123'), result(1,2,3), 'p_repeat 3');
    is(p_run($d3, '1234'), result(1,2,3), 'p_repeat 4');
}

# p_keep
{
    # silly way to only extract 0,1 from a number
    my $binary =
        p_join('',
            p_keep(
                p_many(p_match(qr/([0-9])/)),
                sub($x) { $x==0 || $x==1 ? 1 : 0 }));

    is(p_run($binary, '0123041'), result('0101'), 'p_keep 1');
    is(p_run($binary,    '1234'),    result('1'), 'p_keep 2');
    is(p_run($binary,     '234'),       result(), 'p_keep 3');

    # integers that are allowed to contain -_
    my $int1 =
        p_join('',
            p_keep(
                p_split('',
                    p_match(qr/([0-9-_]+)/)),
                sub($x) { $x =~ m/[0-9]/ }));
    my $int2 = p_matchf(qr/([0-9-_]+)/, sub($str) { $str =~ s/[-_]+//gr });
    for my $int ( $int1, $int2 ) {
        is(p_run($int, '1000'),         result("1000"), 'int 1');
        is(p_run($int, '1_000'),        result("1000"), 'int 2');
        is(p_run($int, '-1-0-0-0-'),    result("1000"), 'int 3');
        is(p_run($int, '1-00-00'),     result("10000"), 'int 4');
        is(p_run($int, '1_000_000'), result("1000000"), 'int 5');
    }
}

# p_not
{
    my $digit = p_match(qr/(\d)/);
    my $wd    =
        p_join('',
            p_and(
                p_many0(p_not($digit)),
                p_many($digit)));

    is(p_run($wd, "123"), result("123"), 'p_not 1');
    is(p_run($wd, "ab3"),   result("3"), 'p_not 2');
    is(p_run($wd, "some3"), result("3"), 'p_not 3');
}

# p_str and p_strc can have multiple values
{
    my $int  =
        p_map(
            sub($x) { $x+0 },
            p_join('', p_and(
                p_maybe(p_strc(qw/+ -/)),
                p_many(p_strc(0 .. 9)),
            ))
        );

    is(p_run($int,  '1234'), Some([ 1234]), 'p_strc many 1');
    is(p_run($int, '+1234'), Some([ 1234]), 'p_strc many 2');
    is(p_run($int, '-1234'), Some([-1234]), 'p_strc many 3');
}

{
    my $int  =
        p_and(
            p_maybe(p_str('+', '-')),
            p_many (p_str(0 .. 9)),
        ),
    my $word    = p_match(qr/([a-zA-Z]+)/);
    my $intword = p_and($int, $word);

    is(p_run($intword,  '1234abc'), Some(["abc"]), 'p_str many 1');
    is(p_run($intword, '+1234foo'), Some(["foo"]), 'p_str many 2');
    is(p_run($intword, '-1234bar'), Some(["bar"]), 'p_str many 3');
}

{
    my $num = parser
        [map =>
            sub {
                my ($num,$suffix) = @_;
                return $num               if !defined $suffix;
                return $num * 1024        if lc $suffix eq 'k';
                return $num * 1204 * 1204 if lc $suffix eq 'm';
            },
            [and =>
                [match => qr/\s* (\.\d+ | \d+ | \d+\.\d+) \s*/x],
                [maybe => [match => qr/([km]) \s* \z/xi]]]];

    is(p_run($num, "123"),         Some([123]), 'num 1');
    is(p_run($num, "123 k"),    Some([125952]), 'num 2');
    is(p_run($num, "123 m"), Some([178302768]), 'num 3');
}

done_testing;
