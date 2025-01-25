#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
# use Sq -sig => 1;
use IO::Handle;

# Haskell's slow "QuickSort"
print "This sorts/prints a sequence of 5_000 random integers.\n";
print "Because ->cache is used on the sequences, it is faster\n";
print "but consumes more memory.\n";

sub qsort($seq) {
    return $seq if $seq->is_empty;
    my $pivot = $seq->head;
    my $rest  = $seq->tail;
    Seq->concat(
        qsort($rest->keep(sub($x) { $x <= $pivot })->cache),
        Seq->one($pivot),
        qsort($rest->keep(sub($x) { $x >  $pivot })->cache),
    );
}

# generate a sequence with random 5_000 ints between 1-5000
# without cache() this will not work correctly, because then everytime
# $seq is iterated you get a new random sequence and this cannot be
# sorted. So at least here you must call cache() so the sequence is
# only populated once.
my $seq = Sq->rand->int(1, 5_000)->take(5_000)->cache;

# print elements of sorted sequence
qsort($seq)->iter(sub($x) {
    STDOUT->printflush($x, ", ");
});
print "\n";
