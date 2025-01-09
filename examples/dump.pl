#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;
use Path::Tiny qw(path);

# Control if Dump should show color or not.
$Sq::Dump::COLOR  = 1;
# When color is active this should be higher. At the moment i don't differentiate
# between printable characters and not. Color printing emits additional characters
# so this must be higher to be more compact.
$Sq::Dump::INLINE = 300;

my $test = sq {
    bonus => "with\nnewline",
    opt1  => Some(10),
    opt2  => None,
    opt3  => Some([
        [qw/a b c/],
        {
            foo => [
                Some(1), Some(2), Some({
                    what => [qw/cool and blue/]
                })
            ]
        }
    ]),
    opt4 => Some("text"),
    opt5 => Some(1,2,3),
    seq1 => Seq->init(10_000, sub($idx) { $idx+1 }),
    seq2 => seq { 1,2,3 },
    path => Path::Tiny->cwd,
};

warn dump($test), "\n";
dumpw Seq->replicate(5, "x");
