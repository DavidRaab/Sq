#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

# functional-style
my $countup = assign {
    my $bill1   = Seq->range(1,1_000_000_000);
    my $is_even = sub($x) { $x & 1 };

    Seq::merge(
        # Why does Seq::zip returns an sequence of array instead of sequence
        # of sequence?
        #
        # When zip runs, it immediately must read one element from each sequence.
        # So you have all data at once in an array. It doesn't make sense to
        # convert this array again to a sequence and pretend it would be a
        # sequence if it is not. That's why it stays an array. As a developer you
        # see that. You understand that the inner values of the sequence
        # are not again lazy evaluated. Usually that isn't that big of a problem.
        # But it makes operating on all elements faster. I mean that was the
        # reason you ziped those elements, right?
        Seq::zip(
            Seq::keep  ($bill1, $is_even),
            Seq::remove($bill1, $is_even),
        )
    );
};

run(sub {
    $countup->iter(sub($x){
        if ( $x % 10_000 == 0 ) {
            print "First: $x\n";
        }
    });
});

# procedural / oo-style
my $bill1   = Seq->range(1,1_000_000_000);
my $is_even = sub($x) { $x & 1 };
my $evens   = $bill1->keep  ($is_even);
my $unevens = $bill1->remove($is_even);
my $zip     = $evens->zip($unevens);
my $flatten = $zip->merge;

run(sub {
    $flatten->iter(sub($x){
        if ( $x % 10_000 == 0 ) {
            print "Second: $x\n";
        }
    });
});

# Basic concept of lambdas. You run some other code and maybe do something
# before/after it. Instead of side-effects like here you also could process
# the input, change/modify it, or do something on the return value. Nothing
# special. In OO you achieve the same by creating a new class, in a new
# file (because clean code tells you so, right?) and inherit from a base
# class and override a method. Or other kind of boilerplate-code crap.
# Seriously stop coding like that!
sub run($f) {
    my $start = time();

    $f->();

    my $stop = time();
    printf "Time: %d seconds\n", ($stop - $start);
}
