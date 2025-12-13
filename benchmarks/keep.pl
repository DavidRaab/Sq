#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;

# In this benchmark i check different implementations for Array::keep. Basically
# a grep {}. But i also wanted to look into a mutable version. Even the Perl
# built-in creates a new array. And often people think that creating new data
# instead of mutation always must be slower. But in the case of filtering
# implemting a mutable version is not really easy.
#
# The version that mutates an array is `by_splice`. Because it mutates the array
# i always must start on a fresh new array. So i make a copy first. But for
# correct comparison i just do a copy in all different versions even if that
# is not needed. So the overhead of copying does not effect relative performance
# to the different solutions.

# creates array with 10_000 random integer numbers
my $amount  = 10_000;
my $numbers = Array->init($amount, sub($idx) {
    return int (rand(100_000));
});

# evens with perl built-in grep
sub by_grep {
    my $numbers = copy($numbers);
    my @evens   = grep { $_ % 2 == 0 } @$numbers;
    return;
}

# same but c-style
sub by_manual {
    my $numbers = copy($numbers);
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
    my $numbers = copy($numbers);
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
    my $numbers = copy($numbers);
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
    my $numbers = copy($numbers);
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
    my $numbers = copy($numbers);
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

__END__
Benchmarking versions with array copies.
                Rate      seq  splice  manual    grep first_5_manual first_5_seq
seq            251/s       --     -8%    -52%    -53%           -62%        -62%
splice         272/s       8%      --    -48%    -50%           -59%        -59%
manual         523/s     108%     92%      --     -3%           -22%        -22%
grep           540/s     115%     98%      3%      --           -19%        -19%
first_5_manual 667/s     165%    145%     27%     24%             --         -0%
first_5_seq    667/s     165%    145%     27%     24%            -0%          --

Keep all with different data-structures. No Array copies.
          Rate    list list_nm     seq   array    grep array_e
list     298/s      --      0%    -25%    -59%    -89%    -89%
list_nm  298/s      0%      --    -25%    -59%    -89%    -89%
seq      399/s     34%     34%      --    -45%    -85%    -85%
array    731/s    145%    145%     83%      --    -73%    -73%
grep    2669/s    795%    795%    569%    265%      --     -2%
array_e 2715/s    811%    811%    580%    271%      2%      --

Getting only first 5 even numbers.
                       Rate first_5_list first_5_array first_5_grep first_5_seq first_5_manual_nc
first_5_list          294/s           --          -59%         -89%       -100%             -100%
first_5_array         725/s         147%            --         -72%       -100%             -100%
first_5_grep         2619/s         791%          261%           --        -99%             -100%
first_5_seq        229681/s       78060%        31590%        8668%          --              -88%
first_5_manual_nc 1971879/s      670927%       271969%       75179%        759%                --
