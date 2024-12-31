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
