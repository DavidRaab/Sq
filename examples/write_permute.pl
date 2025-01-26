#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
# use Sq::Test;

Sq->fs->write_text('permute_10.txt', seq { 0 .. 9 }->permute->map(call 'join', ','));