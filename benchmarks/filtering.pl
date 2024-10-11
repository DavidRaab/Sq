#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

# creates array with 10_000 random integer numbers
my $numbers = Array->init(10_000, sub($idx) {
    return int (rand(100_000));
});

# evens with grep
sub by_grep {
    my $numbers = $numbers->copy;
    my @evens   = grep { $_ % 2 == 0 } @$numbers;
    return;
}

sub by_grep_nc {
    my @evens = grep { $_ % 2 == 0 } @$numbers;
    return;
}

sub by_manual {
    my $numbers = $numbers->copy;
    my @evens;
    for my $num ( @$numbers ) {
        if ( $num % 2 == 0 ) {
            push @evens, $num;
        }
    }
    return;
}

# full mutable version that changes array, hard to understand
sub by_splice {
    my $numbers = $numbers->copy;
    my $idx     = 0;
    while ( $idx < @$numbers ) {
        if ( $numbers->[$idx] % 2 == 1 ) {
            splice @$numbers, $idx, 1;
            next;
        }
        $idx++;
    }
    return;
}

# only getting first 5 even numbers
sub first_5_manual {
    my $numbers = $numbers->copy;
    my $count   = 0;
    my @evens;
    for my $x ( @$numbers ) {
        if ( $x % 2 == 0 ) {
            push @evens, $x;
            last if ++$count >= 5;
        }
    }
    return;
}

sub first_5_manual_nc {
    my $count = 0;
    my @evens;
    for my $x ( @$numbers ) {
        if ( $x % 2 == 0 ) {
            push @evens, $x;
            last if ++$count >= 5;
        }
    }
    return;
}

# getting first 5 even numbers, but code is still abstract like using grep
sub first_5_sq {
    my $numbers = $numbers->copy;
    my $evens =
        Seq
        ->from_array($numbers)
        ->filter(sub($x) { $x % 2 == 0 })
        ->take(5)
        ->to_array;
    return;
}

# when @numbers changes, then $evens will evaluate to the latest updates on trying to fetch data from it.
sub first_5_sq_nc {
    my $evens =
        Seq
        ->from_array($numbers)
        ->filter(sub($x) { $x % 2 == 0 })
        ->take(5)
        ->to_array;
    return;
}

sub all_sq {
    my $numbers = $numbers->copy;
    my $evens =
        Seq
        ->from_array($numbers)
        ->filter(sub($x) { $x % 2 == 0 })
        ->to_array;
    return;
}

sub all_sq_nc {
    my $evens =
        Seq
        ->from_array($numbers)
        ->filter(sub($x) { $x % 2 == 0 })
        ->to_array;
    return;
}

# this is like the grep version
sub array_filter {
    my $evens = Array::filter($numbers, sub($x) { $x % 2 == 0 });
    return;
}

# this creates an "immutable linked list" from array
my $list = List->from_array($numbers);

sub list_filter {
    my $evens = $list->filter(sub($x) { $x % 2 == 0 });
    return;
}

# same, but with functional call
sub list_filter_nm {
    my $evens = List::filter($list, sub($x) { $x % 2 == 0 });
    return;
}

sub first_5_list {
    my $evens =
        $list
        ->filter(sub($x) { $x % 2 == 0})
        ->take(5);
    return;
}

sub first_5_array {
    my $evens =
        Array::filter($numbers, sub($x) { $x % 2 == 0})
        ->take(5);
    return;
}

# doing grep and then just picking first 5
sub first_5_grep {
    my @evens   = grep { $_ % 2 == 0 } @$numbers;
    my @first_5 = @evens[0..4];
    return;
}


printf "Benchmarking version with array copies.\n";
cmpthese(-1, {
    'all_sq'         => \&all_sq,
    'splice'         => \&by_splice,
    'manual'         => \&by_manual,
    'grep'           => \&by_grep,
    'first_5_sq    ' => \&first_5_sq,
    'first_5_manual' => \&first_5_manual,
});

printf "\nWithout array copies.\n";
cmpthese(-1, {
    'all_sq_nc'         => \&all_sq_nc,
    'grep_nc',          => \&by_grep_nc,
    'first_5_manual_nc' => \&first_5_manual_nc,
    'first_5_sq_nc'     => \&first_5_sq_nc,
});

printf "\nFiltering all with different data-structures.\n";
cmpthese(-1, {
    'list'    => \&list_filter,
    'list_nm' => \&list_filter_nm,
    'seq'     => \&all_sq_nc,
    'array'   => \&array_filter,
    'grep'    => \&by_grep_nc,
});

printf "\nGetting only first 5 even numbers.\n";
cmpthese(-1, {
    'first_5_list'      => \&first_5_list,
    'first_5_array'     => \&first_5_array,
    'first_5_grep'      => \&first_5_grep,
    'first_5_seq'       => \&first_5_sq_nc,
    'first_5_manual_nc' => \&first_5_manual_nc,
});

print(
    ($numbers->count == 10_000)
    ? "\nok - correct \$numbers count\n"
    : "\nnot ok - \$numbers count should be 10000\n"
);