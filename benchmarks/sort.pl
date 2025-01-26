#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use List::MoreUtils qw(qsort);
# use Sq::Test;

# my $data = Sq->rand->int(1,10_000)->to_array(100);
# $data->qsort(by_num)->dump;

# my $num  = by_num();
# sub num($x,$y) { $x <=> $y };

my @data = map { int rand(10_000) } 1..10;
dump(\@data);

### DOES NOT WORK
### I don't have a clue why. Basic example from documentation doesn't work
### it works with directly using $a <=> $b, but passing the arguments
### to a function returns some warning of uninitialized variables and
### nothing is sorted.

sub ext_cmp { $_[0] <=> $_[1] }
qsort {
    # dump([$a,$b]);
    ext_cmp($a,$b);
    # $a <=> $b
} @data;

dump(\@data);

=pod

exit;
# my $by_num = by_num;
# my @sorted = sort $by_num @$data;

Sq->bench->compare(-1, {
    pure_perl => sub {
        my @new = sort { $a <=> $b } @$data;
    },
    current_sort => sub {
        my $new = Array::sort($data, by_num);
    },
    current_qsort => sub {
        my $new = Array::qsort($data, by_num);
    },
});
