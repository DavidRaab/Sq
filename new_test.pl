#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Getopt::Long::Descriptive;
use Path::Tiny;

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['test|t=s', 'new testfile script', {required => 1}],
    ['help|h',   'Print this message',  {shortcircuit => 1}],
);

$usage->die if $opt->help;

# Load DATA into array
my @content = <DATA>;

# file to create
my $file = path('t', $opt->test);

# abort when file exists
if ( -e $file ) {
    die "Requested file to create already exists.\n";
}
# create template test file
else {
    $file->spew_utf8(@content);
}


__DATA__
#!perl
use 5.036;
use List::Util qw(reduce);
use Seq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float/;
# use DDP;

diag( "Testing Seq $Seq::VERSION, Perl $], $^X" );
is($Seq::VERSION, number_ge("0.001"), 'Check minimum version number');

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $id      = sub($x) { $x          };
my $add1    = sub($x) { $x + 1      };
my $double  = sub($x) { $x * 2      };
my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

my $fst     = sub($array) { $array->[0] };
my $snd     = sub($array) { $array->[1] };

#----------

