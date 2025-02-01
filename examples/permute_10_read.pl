#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 0;

# The generation of the permutation itself contains a lot of array copying/creation
# permute_10_write.pl creates the permutation just of the number 0..9 so it basically
# creates the indexes in the exact order for one permutation. It saves this order
# in a file.
#
# This file then just re-reads the generated indexes to directly create the permutation.
# This can be potential faster. The generated permutation works for any 10 keys
# but someone can generate the index for any amount.

if ( !-e "permute_10.cache.gz" ) {
    print "Run 'permute_10_write.pl' first.\n";
    exit;
}

# It is interesting to see behaviour change when you add "->cache" here at the
# end.
#
# Without cache() running through both sequences consumes around 20 MiB of memory
# and it takes around 16 seconds (on my machine) to finish for both cases. The cache
# here is directly served from the file.
#
# When you add ->cache() at the end then the cache itself creates a small overhead
# for the first iteration and it takes around 19 seconds to finish. But Memory
# consumption goes up to around 3.5 GiB of RAM because all permutation have to be
# re-created in RAM.
#
# After that, the second iteration then only needs around ~9 seconds to finish
# because all permutations are served from RAM instead from reading from disk.
#
# Still both iteration immediately start. So a sequence can create computation that
# still immediately start and gives you a result and while working creates a
# cache that after the first running can speed up repeatedely runned code.
my $cache = Sq->fs->read_text_gz('permute_10.cache.gz')->split(qr/,/); #->cache;

my $b1 = Sq->bench->it(sub {
    my @permute = ('A' .. 'J');
    $cache->iter(sub($array) {
        print @permute[@$array], "\n";
    });
});

my $b2 = Sq->bench->it(sub {
    my @permute = (qw/C A G T L P 1 2 3 4/);
    $cache->iter(sub($array) {
        print @permute[@$array], "\n";
    });
});

dump($b1);
dump($b2);
