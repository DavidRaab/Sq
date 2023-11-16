#!perl
use 5.036;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Seq' ) || print "Bail out!\n";
}

diag( "Testing Seq $Seq::VERSION, Perl $], $^X" );
