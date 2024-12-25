#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long::Descriptive;
use Path::Tiny;
use Sq;
use Sq::Sig;

my $folders =
    seq { path('t')->children }
    ->filter(call 'is_dir')
    ->map(sub ($str) { $str =~ s[\At/][ + ]r })
    ->join("\n");

my $use =
    join("\n",
        q(USAGE:),
        qq(\t%c %o),
        q(),
        q(EXAMPLE:),
        qq(\t\$ new_test.pl -f Seq -t hello),
        qq(\tCreated 't/Seq/02-hello.t' ...),
        q(),
        q(FOLDERS:),
        $folders,
        q(),
        q(OPTIONS:)
    );

my ($opt, $usage) = describe_options(
    $use,
    ['folder|f=s', 'folder inside t/ to create test-file',    {default      => '.'}],
    ['test|t=s',   'name of the test. Without number and .t', {required     =>   1}],
    ['help|h',     'Print this message',                      {shortcircuit =>   1}],
);

$usage->die if $opt->help;


# get the maximum id from test-files so far
my $maximum_id =
    seq { path('t', $opt->folder)->children }
    ->map(call 'basename')
    ->regex_match(qr/\A(\d+) .* \.t\z/xms)
    ->flatten
    ->max
    ->or(-1);

# Load DATA into array
my @content = <DATA>;

# file to create
my $basename = sprintf "%02d-%s.t", ($maximum_id + 1), $opt->test;
my $file     = path('t', $opt->folder => $basename);

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
