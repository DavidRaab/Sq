#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

die "TODO: Test different Some() implementations for maximum performance\n";
