#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
# Explicitly load all modules. Otherwise this program doesn't show
# much because all of them are lazily loaded
use Sq::Core::Str;
use Sq::Io;
use Sq::Fs;
use Sq::Math;
use Sq::Fmt;
use Sq::Gen;
use Sq::Rand;
use Sq::Bench;
use Sq::Reflection qw(statics signatures);

print "Currently defined statics.\n";
my $statics = statics();
Sq->fmt->table({
    data => $statics->sort(by_str)->columns(4),
});
print "\n";

my $missing = Array::diff($statics, signatures(), \&id);
if ( @$missing ) {
    print "Following statics are missing a signature.\n";
    say $missing->sort(by_str)->join(', ');
}
else {
    print "All statics have a signature.\n";
}
