#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Parser qw(p_run);
use Sq::Test;

is(
    p_run(Sq->p->date_ymd, "2025-03-13"),
    Some([2025,3,13]),
    'Date Parser 1');

# it doesn't check for valid date (at the moment)
is(
    p_run(Sq->p->date_ymd, "9999-99-99"),
    Some([9999,99,99]),
    'Date Parser 3');

# Format must be exact. Always two digits for month/day
is(
    p_run(Sq->p->date_ymd, "2010-2-1"),
    None,
    'Date Parser 3');

done_testing;
