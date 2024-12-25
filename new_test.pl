#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long::Descriptive;
use Path::Tiny;
use Sq;

my $use =
    join("\n",
        q(USAGE:),
        qq(\t%c %o),
        q(),
        q(EXAMPLE:),
        qq(\t\$ new_test.pl -f Seq -t hello),
        qq(\tCreated 't/Seq/02-hello.t' ...),
        q(),
        q(OPTIONS:)
    );

my ($opt, $usage) = describe_options(
    $use,
    ['folder|f=s', 'folder to create test-file',              {default      => '.'}],
    ['test|t=s',   'name of the test. Without number and .t', {required     =>   1}],
    ['help|h',     'Print this message',                      {shortcircuit =>   1}],
);

$usage->die if $opt->help;

# get the maximum id from test-files so far
my $maximum_id =
    Seq
    ->new( path($opt->folder)->children )
    ->map( sub($x) { $x->basename })
    ->regex_match( qr/\A(\d+) .* \.t\z/xms)
    ->fsts
    ->max->or(-1);

# Load DATA into array
my @content = <DATA>;

# file to create
my $basename = sprintf "%02d-%s.t", ($maximum_id + 1), $opt->test;
my $file     = path($opt->folder => $basename);

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
use Sq;
use Sq::Sig;
use Sq::Test;

ok(1, 'Write a test');

done_testing;
