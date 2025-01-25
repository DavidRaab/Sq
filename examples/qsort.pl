#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
# use Sq -sig => 1;
use Sq::Gen;
use IO::Handle;

# Haskell's slow "QuickSort"
print "This sorts/prints a sequence of 5_000 random integers.\n";
print "It takes around ~30 seconds to start.\n";

sub qsort($seq) {
    return $seq if $seq->is_empty;
    my $pivot = $seq->head;
    my $rest  = $seq->tail;
    Seq->concat(
        qsort($rest->keep(sub($x) { $x <= $pivot })),
        Seq->one($pivot),
        qsort($rest->keep(sub($x) { $x >  $pivot })),
    );
}

# generate an array with random 1_000 ints
my $seq = gen_run(gen [repeat => 5_000, [int => 1_000, 5_000]])->to_seq;

# print elements of sorted sequence
qsort($seq)->iter(sub($x) {
    STDOUT->printflush($x, ", ");
});
print "\n";
