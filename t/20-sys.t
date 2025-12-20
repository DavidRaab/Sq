#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

check_isa(Sq->sys->dir, 'Path::Tiny', 'dir is a Path::Tiny');
check_isa(Sq->sys->env, 'Hash',       'env is a Hash');

$ENV{WHATEVER} = 1;
is(Sq->sys->env->{WHATEVER}, 1, 'check if it return %ENV');

done_testing;
