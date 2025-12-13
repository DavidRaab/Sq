#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Benchmark qw(cmpthese);

cmpthese(-1, {
    mod => sub {
        my $b;
        for my $x ( 1 .. 1_000 ) {
            $b = $x % 2 == 0;
        }
    },
    binary => sub {
        my $b;
        for my $x ( 1 .. 1_000 ) {
            $b = $x & 1 == 0;
        }
    },
});

__END__
          Rate    mod binary
mod    27306/s     --   -46%
binary 50243/s    84%     --
