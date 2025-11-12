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
    return $data;
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