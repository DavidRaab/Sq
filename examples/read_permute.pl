#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
# use Sq -sig => 1;

if ( !-e "permute_10.txt.gz" ) {
    print "Run 'write_permute.pl' first.\n";
}

Sq->bench->it(sub {
    my @permute = ('A' .. 'J');
    Sq->fs->read_text_gz('permute_10.txt.gz')->split(qr/,/)->iter(sub($array) {
        print @permute[@$array], "\n";
    });
});