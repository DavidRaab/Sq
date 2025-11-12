#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

# Started implementing MultiLine Support for table as an Example. The idea
# is as following: Currently table only accepts an Array of Array of Strings.
# The first array are the lines, and every sub-array are the columns.
#
# Now every column can be arrays again. If that happens, then the array
# must be transformed again to just an array of array of strings. When this
# transformation is done the data can be called with table() again.
#
# So MultiLines are just converted to the table format.

sub multiline($data) {
    my @new;
    for my $line ( @$data ) {
        if ( Array::any($line, \&is_array) ) {
            my $lines =
                # first convert every entry into an array
                Array::map($line, sub($x) {
                    return is_array($x) ? $x : array($x);
                })
                # then fill AoA with empty strings
                ->fill2d(sub { "" })
                # then transpose
                ->transpose;
            # add all new lines into @new
            push @new, @$lines;
        }
        # when columns don't contain any array, nothing must be done
        else {
            push @new, copy($line);
        }
    }
    return bless(\@new, 'Array');
}

is(
    multiline([
        ["foo", ["kaz","faz"], "baz"],
    ]),
    [
        ["foo", "kaz", "baz"],
        ["",    "faz",    ""],
    ],
    'multiline 1');

is(
    multiline([
        ["foo", ["kaz","faz"], "baz"],
        ["maz", "raz", "haz"],
    ]),
    [
        ["foo", "kaz", "baz"],
        ["",    "faz",    ""],
        ["maz", "raz", "haz"],
    ],
    'multiline 2');

done_testing;