#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Getopt::Long::Descriptive;
use Path::Tiny;
use Sq;
use Sq::Sig;

# This makes the code Lazy. That means the code is basically just wrapped
# in a subroutine. But it has an intent over just a sub-ref. The idea is that
# this code is not executed immediately, but maybe at a later time. lazy {}
# returns a lazy object. This object ensures that when it is run, only runs
# a single time.
my $use = lazy {
    my $folders =
        Sq->fs->children('t')
        ->keep(call 'is_dir')
        ->rxs (qr{\At/}, sub { " + " })
        ->sort(by_str)
        ->join("\n");

    return join("\n",
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
};

# Here lazy{} not really makes sense, because the `$use->force` is always evaluated.
# So we don't really need that. But what makes lazy different is that another new
# call `$use->force` will not run the function twice. Code is only runned once
# and the result is saved/cached.
my ($opt, $usage) = describe_options(
    $use->force,
    ['folder|f=s', 'folder inside t/ to create test-file',    {default      => '.'}],
    ['test|t=s',   'name of the test. Without number and .t', {required     =>   1}],
    ['help|h',     'Print this message',                      {shortcircuit =>   1}],
);

$usage->die if $opt->help;

# get the maximum id from test-files so far
my $maximum_id =
    Sq->fs
    ->children('t', $opt->folder  )
    ->map(call 'basename'         )
    ->rxm(qr/\A(\d+) .* \.t\z/xms )
    ->fsts
    ->max
    ->or(-1);

# Load DATA into array
my @content = <DATA>;

# file to create
my $basename = sprintf "%02d-%s.t", ($maximum_id + 1), $opt->test;
my $file     = path('t', $opt->folder => $basename);

# abort when file exists
if ( -e $file ) {
    die "Abort: Requested file already exists. Not created.\n";
}
# create test file from template
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
