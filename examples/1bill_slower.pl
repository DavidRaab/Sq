#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;

# functional-style
my $countup = assign {
    my $bill1   = Seq->range(1,1_000_000_000);
    my $is_even = sub($x) { $x & 1 };

    Seq::merge(
        # Hmm, i think Seq::zip should built a sequence too instead.
        # Or not? The reason behind this behavior:
        # When zip runs, it defenitely must read on element from each list.
        # (maybe in future from multiple list). So you have all data at once
        # in an array. It doesn't make sense to save it as a sequence again
        # and pretend it would be a sequence if it is not. That's why it stays
        # an array. As a developer you see that. You understand that it isn't
        # lazy evaluated. Usually that isn't that big of a problem. But it makes
        # operating on all elements faster. I mean that was the reason you
        # ziped those elements, right?
        Seq::zip(
            Seq::filter($bill1, $is_even),
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
my $evens   = $bill1->filter($is_even);
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

sub run($f) {
    my $start = time();

    $f->();

    my $stop = time();
    printf "Time: %d seconds\n", $stop;
}
