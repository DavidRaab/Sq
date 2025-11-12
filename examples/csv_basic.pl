#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['file|f=s', 'filename to read', {default      => 'csv/csv_basic.csv'}],
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

# Every CSV Entry should be like this
my $csv_entry = type [hash => [keys =>
    date      => [parser => Sq->p->date_ymd],
    operation => [enum   => 'ADD', 'SUB', 'CURRENT'],
    balance   => ['num'],
    comment   => ['str'],
]];

# Reads CSV file. Uses a default for balance and comment. Only keeps entries
# of the above defined type.
my $data =
    Sq->io->csv_read($opt->file)
    ->map(call with_default => balance => 0, comment => "", current => 0)
    ->keep_type($csv_entry)
    ->sort_by(by_str, key 'date');

# dump($data);

my $previous_current = 0;
$data->iter(dispatch(key 'operation', {
    CURRENT => sub($row) {
        $previous_current = $row->{balance};
        $row->{balance}   = sprintf "%+10.02f", $row->{balance};
        $row->{current}   = sprintf "%8.2f", $previous_current;
    },
    SUB => sub($row) {
        $previous_current -= $row->{balance};
        $row->{balance}    = sprintf "%+10.02f", -$row->{balance};
        $row->{current}    = sprintf "%8.2f", $previous_current;
    },
    ADD => sub($row) {
        $previous_current += $row->{balance};
        $row->{balance}    = sprintf "%+10.02f", $row->{balance};
        $row->{current}    = sprintf "%8.2f", $previous_current;
    },
}));

Sq->fmt->table({
    header => [qw/date current balance comment/],
    data   => $data,
    border => 0,
});
