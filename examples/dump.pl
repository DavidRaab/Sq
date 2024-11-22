#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;

my $test = Hash->new(
    bonus => "with\nnewline",
    opt1  => Some(10),
    opt2  => None,
    opt3  => Some([]),
    opt4  => Some({}),
    opt5  => Some([
        [qw/a b c/],
        {
            foo => [
                Some(1), Some(2), Some({
                    what => [qw/cool and blue/]
                })
            ]
        }
    ]),
    opt6 => Some("text"),
);

printf "\$test: %s\n", $test->dump;
