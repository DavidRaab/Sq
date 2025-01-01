#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Sig;

# It started by bechmarking and looking at different filtering implementation
# especially looking at the performance of a full mutable version that
# mutates an array and removes entries instead of createing a new on. This
# version is `by_splice`. Because it mutates and correct benchmarking behaviour
# must be ensured there are versions that copies the array first to really
# compare the difference of the algorithms. But there are also version without
# copies that shows a more practical version.

# creates array with 10_000 random integer numbers
my $amount  = 10_000;
my $numbers = Array->init($amount, sub($idx) {
    return int (rand(100_000));
});

# evens with perl built-in grep
sub by_grep {
    my $numbers = $numbers->copy;
    my @evens   = grep { $_ % 2 == 0 } @$numbers;
    return;
}

# same but c-style
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

# full mutable version that changes array
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

sub by_seq {
    my $numbers = $numbers->copy;
    my $evens =
        Seq
        ->from_array($numbers)
        ->keep(sub($x) { $x % 2 == 0 })
        ->to_array;
    return;
}

## no copy versions

# like grep but without copies (nc = no copy)
sub by_grep_nc {
    my @evens = grep { $_ % 2 == 0 } @$numbers;
    return;
}

sub by_seq_nc {
    my $evens =
        Seq
        ->from_array($numbers)
        ->keep(sub($x) { $x % 2 == 0 })
        ->to_array;
    return;
}

# this is like the grep version
sub array_keep {
    my $evens = $numbers->keep(sub($x) { $x % 2 == 0 });
    return;
}

# same as keep but uses string-eval to build up query
sub array_keep_e {
    my $evens = $numbers->keep_e('$_ % 2 == 0');
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

## first_5_* versions

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

# getting first 5 even numbers, but code is still abstract like using grep
sub first_5_seq {
    my $numbers = $numbers->copy;
    my $evens =
        Seq
        ->from_array($numbers)
        ->keep(sub($x) { $x % 2 == 0 })
        ->take(5)
        ->to_array;
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

# when @numbers changes, then $evens will evaluate to the latest updates on trying to fetch data from it.
sub first_5_seq_nc {
    my $evens =
        Seq
        ->from_array($numbers)
        ->keep(sub($x) { $x % 2 == 0 })
        ->to_array(5);
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
        Array::keep($numbers, sub($x) { $x % 2 == 0})
        ->take(5);
    return;
}

# doing grep and then just picking first 5
sub first_5_grep {
    my @evens   = grep { $_ % 2 == 0 } @$numbers;
    my @first_5 = @evens[0..4];
    return;
}


printf "Benchmarking versions with array copies.\n";
Sq->bench->compare(-1, {
    'seq'            => \&by_seq,
    'splice'         => \&by_splice,
    'manual'         => \&by_manual,
    'grep'           => \&by_grep,
    'first_5_seq'    => \&first_5_seq,
    'first_5_manual' => \&first_5_manual,
});

printf "\nKeep all with different data-structures. No Array copies.\n";
Sq->bench->compare(-1, {
    'list'    => \&list_filter,
    'list_nm' => \&list_filter_nm,
    'seq'     => \&by_seq_nc,
    'array'   => \&array_keep,
    'array_e' => \&array_keep_e,
    'grep'    => \&by_grep_nc,
});

printf "\nGetting only first 5 even numbers.\n";
Sq->bench->compare(-1, {
    'first_5_list'      => \&first_5_list,
    'first_5_array'     => \&first_5_array,
    'first_5_grep'      => \&first_5_grep,
    'first_5_seq'       => \&first_5_seq_nc,
    'first_5_manual_nc' => \&first_5_manual_nc,
});

print(
    ($numbers->length == $amount)
    ? "\nok - correct \$numbers count\n"
    : "\nnot ok - \$numbers length should be $amount but got ". $numbers->length . "\n"
);