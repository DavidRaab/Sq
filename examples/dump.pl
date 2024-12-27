#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;

my $test = sq {
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
    opt7 => Some(1,2,3),
    seq1 => Seq->init(10_000, sub($idx) { $idx+1 }),
    seq2 => Seq->new(1,2,3),
    seq3 => Seq->new(1,2,3,4),
};

warn dump($test), "\n";
dumpw Seq->replicate(5, "x");
