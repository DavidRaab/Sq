#!/usr/bin/env perl
use 5.036;
use open ':std', ':encoding(UTF-8)';
use Benchmark qw(cmpthese);

# Sometimes we want to check if something like a string is inside
# another selection. like:
#
#    oneOf($str, @others);
#
# You could iterate the array. But in Perl you learn that this solution
# becomes pretty slow. Instead Perl users learn to built a hash with
# just a => 1 mapping, then use the hash for checking.
#
# This benchmark shows that hashing and selection is already faster
# with just 3 elements to scan. On my machine around ~3 times faster.
#
# With more elements the Array scanning becomes even more worse.

my @words = qw/yes hello world cool no what shakira maybe whatever/;
cmpthese(-1, {
    array => sub {
        my $count  = 0;
        my @valids = qw(yes no maybe);
        for ( 1 .. 1_000 ) {
            for my $word ( @words ) {
                for my $valid ( @valids ) {
                    if ( $word eq $valid ) {
                        $count++;
                        last;
                    }
                }
            }
        }
        die "\$count not 3000: $count\n" if $count != 3000;
    },
    hash => sub {
        my $count = 0;
        my %valid = map { $_ => 1 } qw(yes no maybe);
        for ( 1 .. 1_000 ) {
            for my $word ( @words ) {
                $count++ if $valid{$word};
            }
        }
        die "\$count not 3000: $count\n" if $count != 3000;
    },
    hash_exists => sub {
        my $count = 0;
        my %valid = map { $_ => 1 } qw(yes no maybe);
        for ( 1 .. 1_000 ) {
            for my $word ( @words ) {
                $count++ if exists $valid{$word};
            }
        }
        die "\$count not 3000: $count\n" if $count != 3000;
    },
});