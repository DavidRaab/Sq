#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);


sub choose_extract($array, $f_opt) {
    my $new = Array->new;
    my ($is_some, $v);
    for my $x ( @$array ) {
        ($is_some, $v) = Option->extract($f_opt->($x));
        push @$new, $v if $is_some;
    }
    return $new;
}

sub choose_some($array, $f_opt) {
    my $new = Array->new;
    for my $x ( @$array ) {
        my $opt = Option::Some($f_opt->($x));
        push @$new, $opt->[0] if @$opt;
    }
    return $new;
}

sub choose_iter($array, $f_opt) {
    my $new = Array->new;
    for my $x ( @$array ) {
        Option::Some($f_opt->($x))->iter(sub($x){
            push @$new, $x;
        });
    }
    return $new;
}

sub choose_iter2($array, $f_opt) {
    my $new = Array->new;;
    my $f = sub($x){ push @$new, $x };
    for my $x ( @$array ) {
        Option::Some($f_opt->($x))->iter($f);
    }
    return $new;
}

my $data = Array->range(1, 10_000);
my $f    = sub ($x) { $x % 2 == 0 ? $x*2 : undef };
cmpthese(-2, {
    choose_extract => sub {
        my $evens = choose_extract($data,$f);
    },
    choose_some => sub {
        my $evens = choose_some($data,$f);
    },
    choose_iter => sub {
        my $evens = choose_iter($data,$f);
    },
    choose_iter2 => sub {
        my $evens = choose_iter2($data,$f);
    },
});