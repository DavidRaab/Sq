#!perl
use 5.036;
use Sq;
use Sq::Parser;
use Test2::V0 ':DEFAULT';

# Some parsers
my $word = p_match(qr/([a-zA-Z]+)/);
my $ws   = p_is(qr/\s++/);
my $int  = p_match(qr/(\d++)/);
my $hex  = p_map(p_match(qr/0x([0-9a-zA-Z]+)/), sub($hex) { hex $hex });

# Helper function to build result
sub result(@xs) { Some([@xs]) }

# basics
{
    my $p_hello = p_match(qr/(Hello)/);
    my $p_world = p_match(qr/(World)/);
    my $length  = p_map($p_hello, sub($str) { length $str });

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
    my sub pmap($p, $f) {
        p_bind($p, sub(@xs) { p_return $f->(@xs) });
    }

    my $int  = p_match(qr/(\d+)/);
    my $incr = pmap($int, sub($x) { $x + 1 });
    is(p_run($incr, "12"), result(13), 'map through bind');
}

# p_and
{
    my $p_comma  = p_is(qr/,/);
    my $greeting = p_and($word, $p_comma, $ws, $word);

    is(p_run($greeting, "HELLO, WORLD!"),   result("HELLO", "WORLD"), 'parse greeting 1');
    is(p_run($greeting, "hello, world!"),   result("hello", "world"), 'parse greeting 2');
    is(p_run($greeting, "hElLo,   wOrLd!"), result("hElLo", "wOrLd"), 'parse greeting 3');
    is(p_run($greeting, "helloworld!"),                             None, 'no greeting');
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

    my $jint = p_join($int, '');
    is(p_run($jint, '1234foo'),  result( '1234'), '$jint parses just int');
    is(p_run($jint, '+1234foo'), result('+1234'), '$jint with + sign');
    is(p_run($jint, '-1234foo'), result('-1234'), '$jint with - sign');
}

# p_many, p_many0
{
    # Regex: (\d+) (?: (\d+) , )+
    my $int1 = p_and($int, p_many (p_and(p_str(','), $int)));
    # Regex: (\d+) (?: (\d+) , )*
    my $int0 = p_and($int, p_many0(p_and(p_str(','), $int)));

    is(p_run($int0, '123'),                          result(123), '$int0 list');
    is(p_run($int1, '123'),                                 None, '$int1 list');
    is(p_run($int0, '123,12,300,420'), result(123, 12, 300, 420), '$int0 list 2');
    is(p_run($int1, '123,12,300,420'), result(123, 12, 300, 420), '$int1 list 2');

    my $p_array = p_map($int0, sub(@xs) { [@xs] });
    is(p_run($p_array, '1,2,3,420'), result([1,2,3,420]), 'parses to array');
}

# p_match with many captures
{
    my $time = p_match(qr/(\d\d?):(\d\d?)/);
    is(p_run($time, '12:34'), result(12,34), 'extracts 2 vars 1');
    is(p_run($time, '1:3'),     result(1,3), 'extracts 2 vars 2');
    is(p_run($time, '123:12'),         None, 'no time');
}

done_testing;
