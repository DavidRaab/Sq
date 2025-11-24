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

my $data = Sq->io->youtube($ARGV[0])->match(
    Ok  => \&id,
    Err => sub($msg) { die $msg },
);

Sq->fmt->table({
    header => [qw/format_id format fps ext vcodec protocol quality vbr/],
    data   => $data->{formats},
    border => 0,
});