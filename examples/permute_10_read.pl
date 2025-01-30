#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
# use Sq -sig => 1;

if ( !-e "permute_10.cache.gz" ) {
    print "Run 'permute_10_write.pl' first.\n";
    exit;
}

Sq->bench->it(sub {
    my @permute = ('A' .. 'J');
    Sq->fs->read_text_gz('permute_10.cache.gz')->split(qr/,/)->iter(sub($array) {
        print @permute[@$array], "\n";
    });
});