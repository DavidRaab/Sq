#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

print "This program reads from STDIN\n";
print "Test it by running:\n";
print "  perl -E \'print \"a\\nb\\nc\\nd\\ne\\nf\\n\"\' | ./stdin.pl\n";
Seq->stdin->windowed(2)->iter(sub($array){
    dump $array;
});
