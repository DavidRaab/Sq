#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['file|f=s', 'filename to read', {default      => 'csv/read_csv.csv'}],
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

# Every CSV Entry should be like this
my $csv_entry = type [hash => [keys =>
    date      => ['str'],
    operation => [enum => 'ADD', 'SUB', 'CURRENT'],
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

# Compute current and add it to the rows
my $previous_current = 0;
$data->iter(sub($row) {
    my $op      = $row->{operation};
    my $balance = $row->{balance};

    if ( $op eq 'CURRENT' ) {
        $previous_current = $balance;
        $row->{balance} = sprintf "%+10.02f", $row->{balance};
    }
    elsif ( $op eq 'SUB' ) {
        $previous_current -= $balance;
        $row->{balance} = sprintf "%+10.02f", -$row->{balance};
    }
    else {
        $row->{balance} = sprintf "%+10.02f", $row->{balance};
    }

    $row->{current} = $previous_current;
});

# TODO: table should support sequence
Sq->fmt->table({
    header => [qw/date current balance comment/],
    data   => $data->to_array,
    border => 0,
});
