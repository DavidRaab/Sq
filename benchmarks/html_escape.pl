#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Gen;
# use Sq::Sig;
use HTML::Escape;
use HTML::Entities;

# getting the function first from a static is faster
my $escape = Sq->fmt->escape_html;

# generates 1000 random strings with size 10-100
my $txts = gen_run gen [repeat => 1000 => [str_from => 10, 100, 'a'..'f', qw/< > & { } ' `/]];
Sq->bench->compare(-3, {
    "HTML::Escape" => sub {
        for my $txt ( @$txts ) {
            escape_html($txt);
        }
    },
    "HTML::Entities" => sub {
        for my $txt ( @$txts ) {
            encode_entities($txt);
        }
    },
    current => sub {
        for my $txt ( @$txts ) {
            $escape->($txt);
        }
    },
});