#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
# use Sq::Test;
# use Getopt::Long::Descriptive;

# my ($opt, $usage) = describe_options(
#     'Usage: %c %o',
#     ['help|h', 'Print this message', {shortcircuit => 1}],
# );

# $usage->die if $opt->help;

my @fields  = qw/format_id format fps ext vcodec protocol quality vbr/;

my $data    = Sq->io->youtube($ARGV[0]);
my $formats = $data->{formats};
my $videos  = $formats->map(sub($fmt) {
    $fmt->slice(@fields)
});

dump $formats;

Sq->fmt->table({
    header => \@fields,
    data   => $videos,
    border => 0,
});