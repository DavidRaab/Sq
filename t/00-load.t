#!perl
use 5.036;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Sq' ) || print "Bail out!\n";
}

diag( "Testing Sq $Sq::VERSION, Perl $], $^X" );
