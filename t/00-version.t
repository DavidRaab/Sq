#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT';

diag( "Testing Sq $Sq::VERSION, Perl $], $^X" );
is($Sq::VERSION, number_ge("0.006"), 'Check minimum version number');

done_testing;
