#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Sq::Sig;

dump(array(qw/A B C D/)->permute);