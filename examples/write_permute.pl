#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
# use Sq::Test;

print "Generating file 'permute_10.txt.gz'\n";
Sq->bench->it(sub {
    my $permute = seq { 0 .. 9 }->permute->map(call 'join', ',');
    Sq->fs->write_text_gz('permute_10.txt.gz', $permute);
});
