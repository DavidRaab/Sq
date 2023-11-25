#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Getopt::Long::Descriptive;
use Path::Tiny;
use Seq qw(id fst snd key);

my $use =
    join("\n",
        q(USAGE:),
        qq(\t%c %o),
        q(),
        q(EXAMPLE:),
        qq(\t\$ new_test.pl -t hello),
        qq(\tCreated 't/02-hello.t' ...),
        q(),
        q(OPTIONS:)
    );

my ($opt, $usage) = describe_options(
    $use,
    ['test|t=s', 'name of the test. Without number and .t',
        {required => 1}],
    ['help|h',   'Print this message',
        {shortcircuit => 1}],
);

$usage->die if $opt->help;

# get the maximum id from test-files so far
my $maximum_id =
    Seq
    ->wrap( path('t')->children )
    ->map(  sub($x) { $x->basename })
    ->regex_match( qr/\A(\d+) .* \.t\z/xms, [1])
    ->fsts
    ->max(0);

# Load DATA into array
my @content = <DATA>;

# file to create
my $basename = sprintf "%02d-%s.t", ($maximum_id + 1), $opt->test;
my $file     = path(t => $basename);

# abort when file exists
if ( -e $file ) {
    die "Requested file to create already exists.\n";
}
# create template test file
else {
    $file->spew_utf8(@content);
    printf "Created '%s' ...\n", $file;
}


__DATA__
#!perl
use 5.036;
use Seq qw(id fst snd key assign);
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use DDP;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

done_testing;
