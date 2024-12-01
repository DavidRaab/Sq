#!perl
use 5.036;
use Sq;
use Sq::Parser;
use Test2::V0 ':DEFAULT';

# basics
{
    my $p_hello = p_match(qr/(Hello)/);
    my $p_world = p_match(qr/(World)/);
    my $length  = p_map($p_hello, sub($str) { length $str });
    my $int     = p_match(qr/(\d+)/);
    my $hex     = p_match(qr/0x([0-9a-zA-Z]+)/);
    my $hex_num = p_map($hex, sub($hex) { hex $hex });

    my $greeting = "Hello, World!";
    is(p_run($p_hello, $greeting), Some([{pos => 5}, 'Hello']), 'starts with hello');
    is(p_run($length, $greeting),        Some([{pos => 5}, 5]), 'length of hello');
    is(p_run($p_world, $greeting),                        None, 'does not start with world');
    is(p_run($int, "12345foo"),    Some([{pos => 5}, "12345"]), 'extracted int');
    is(p_run($int, "foo123"),                             None, 'no int at start');
    is(p_run($hex_num, "0xff 123"),    Some([{pos => 4}, 255]), 'extract hex');
}

# p_and
{
    my $word     = p_match(qr/([a-zA-Z]+)/);
    my $p_comma  = p_is(qr/,/);
    my $ws       = p_is(qr/\s+/);
    my $greeting = p_and($word, $p_comma, $ws, $word);

    is(p_run($greeting, "HELLO, WORLD!"),   Some([{pos => 12}, "HELLO", "WORLD"]), 'parse greeting 1');
    is(p_run($greeting, "hello, world!"),   Some([{pos => 12}, "hello", "world"]), 'parse greeting 2');
    is(p_run($greeting, "hElLo,   wOrLd!"), Some([{pos => 14}, "hElLo", "wOrLd"]), 'parse greeting 3');
    is(p_run($greeting, "helloworld!"),                                      None, 'no greeting');
}

done_testing;