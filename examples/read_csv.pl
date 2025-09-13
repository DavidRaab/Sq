#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Getopt::Long::Descriptive;

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['file|f=s', 'filename to read', {default      => 'read_csv.csv'}],
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

my $data = Sq->io->csv_read($opt->file)->sort_by(by_str, key 'date');
# TODO: table should support sequence
# Sq->fmt->table({
#     header => [qw/date balance comment/],
#     data   => $data->to_array,
#     border => 0,
# });
# dump($data);

my ($current, $balance, $op, $comment) = (0, 0, "", "");
$data->iter(sub($row){
    printf "%s ", $row->{date};
    $balance = $row->{balance} // 0;
    $op      = $row->{operation};
    $comment = $row->{comment} // "";
    if ( $op eq 'CURRENT' ) {
        $current = $balance;
        printf "%8.2f %s\n", $current, $comment;
    }
    elsif ( $op eq 'SUB' ) {
        $current -= $balance;
        printf "%8.2f %8.2f %s\n", $current, -$balance, $comment;
    }
    elsif ( $op eq 'ADD' ) {
        $current += $balance;
        printf "%8.2f %+8.2f %s\n", $current, $balance, $comment;
    }
    else {
        die sprintf("Operation '%s' not implemented.", $op);
    }
});
