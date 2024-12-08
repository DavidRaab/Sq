#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Sq;
use Benchmark qw(cmpthese);
use Test2::V0 qw(is done_testing);

# this is the fastest way to write in Perl, without arguments and no undef checking
sub map_pureperl($array) {
    local $_;
    my @new = map { $_ * 2 } @$array;
    return CORE::bless(\@new, 'Array');
}

# somehow not using an extra line to assign to @new makes it A LOT (15%+) slower
sub map_pureperl_inline($array) {
    local $_;
    return CORE::bless([map { $_ * 2 } @$array], 'Array');
}

# same as builtin - but don't uses signature feature - old school perl
sub map_pureperl_ns {
    my ( $array ) = @_;
    local $_;
    my @new = map { $_ * 2 } @$array;
    return CORE::bless(\@new, 'Array');
}

# lambda + undef checking - this way also can be used as filtering.
# Perl built-in is similar as an empty list in map does skip a value.
# but this variation only allows lambda to return one value. Perl built-in
# allows returning multiple values by default
sub map_lambda($array, $f) {
    local $_;
    my (@new, $value);
    for ( @$array ) {
        $value = $f->($_);
        last if !defined $value;
        push @new, $value;
    }
    return CORE::bless(\@new, 'Array');
}

# lambda + undef checking + lambda returns list
# closest to perl built-in with added undef checking
sub map_lambda_list($array, $f) {
    my @new;
    for ( @$array ) {
        push @new, grep { defined } $f->($_);
    }
    return CORE::bless(\@new, 'Array');
}

# same as before but mapping and greping in two invocations
sub map_lambda_list2($array, $f) {
    my $new = [
        grep { defined  }
        map  { $f->($_) } @$array
    ];
    return CORE::bless($new, 'Array');
}

sub map_lambda_list2_i($array, $f) {
    return CORE::bless([
        grep { defined  }
        map  { $f->($_) } @$array
    ], 'Array');
}

# same as lambda, but used default variable instead of passing it as argument
sub map_lambda_def($array, $f) {
    local $_;
    my (@new, $value);
    for ( @$array ) {
        $value = $f->();
        push @new, $value if defined $value;
    }
    return CORE::bless(\@new, 'Array');
}

# lambda, but no undef checking
sub map_wo_undef($array, $f) {
    my $new = [map { $f->($_) } @$array];
    return CORE::bless($new, 'Array');
}

sub map_defined_default($array, $f) {
    local $_;
    my $new = [grep { defined } map { $f->($_) } @$array];
    CORE::bless($new, 'Array');
}

# implemented using for, without undef
sub map_for($array, $f) {
    local $_;
    my @new;
    for ( @$array ) {
        push @new, $f->($_);
    }
    return CORE::bless(\@new, 'Array');
}

# implemented using for, without undef
sub map_for_default($array, $f) {
    local $_;
    my @new;
    for ( @$array ) {
        push @new, $f->($_);
    }
    return CORE::bless(\@new, 'Array');
}

sub map_for_only_default($array, $f) {
    local $_;
    my @new;
    for ( @$array ) {
        push @new, $f->();
    }
    return CORE::bless(\@new, 'Array');
}

# implemented using for, without undef
sub map_for_defined($array, $f) {
    local $_;
    my (@new, $x);
    for ( @$array ) {
        push @new, grep { defined } $f->($_);
    }
    return CORE::bless(\@new, 'Array');
}

# no undef checking, but using string-eval instead of lambda
sub map_eval($array, $expr) {
    local $_;
    my $new = eval "[map { $expr } \@\$array]";
    return CORE::bless($new, 'Array');
}

# $expr can return a list and defined checking
sub map_list_eval($array, $expr) {
    my $new = eval "[grep { defined } map { $expr } \@\$array]";
    return CORE::bless($new, 'Array');
}

# checks undef but uses eval instead of lambda
sub map_undef_eval($array, $expr) {
    local $_;
    my $code = "my \@new; for ( \@\$array ) { my \$v = $expr; push \@new, \$v if defined \$v; } return \\\@new;";
    my $new  = eval $code;
    return CORE::bless($new, 'Array');
}


# testing if implementations are correct
my @numbers = (1 .. 10);
my @result  = (2,4,6,8,10,12,14,16,18,20);
my @maps = (
    map_pureperl        (\@numbers),
    map_pureperl_ns     (\@numbers),
    map_pureperl_inline (\@numbers),
    map_lambda          (\@numbers, sub($x) { $x * 2 }),
    map_lambda          (\@numbers, sub     { $_ * 2 }),
    map_lambda_list     (\@numbers, sub($x) { $x * 2 }),
    map_lambda_list2    (\@numbers, sub($x) { $x * 2 }),
    map_lambda_list2_i  (\@numbers, sub($x) { $x * 2 }),
    map_wo_undef        (\@numbers, sub($x) { $x * 2 }),
    map_undef_eval      (\@numbers, '$_ * 2'),
    map_eval            (\@numbers, '$_ * 2'),
    map_list_eval       (\@numbers, '$_ * 2'),
    map_lambda_def      (\@numbers, sub     { $_ * 2 }),
    map_for             (\@numbers, sub($x) { $x * 2 }),
    map_for_default     (\@numbers, sub($x) { $x * 2 }),
    map_for_default     (\@numbers, sub     { $_ * 2 }),
    map_for_defined     (\@numbers, sub($x) { $x * 2 }),
    map_for_defined     (\@numbers, sub     { $_ * 2 }),
    map_for_only_default(\@numbers, sub     { $_ * 2 }),
    map_defined_default (\@numbers, sub     { $_ * 2 }),
);
my $idx = 0;
for my $array ( @maps ) {
    is($array, \@result, "checking $idx");
    $idx++;
}
done_testing;


# array used for benchmarking
my $bench = Array->init(10_000, sub($idx) {
    return int( rand(100_000) );
});

printf "Benchmarking pure perl map {} calls.\n";
cmpthese(-1, {
    pureperl        => sub { my $r = map_pureperl       ($bench) },
    pureperl_inline => sub { my $r = map_pureperl_inline($bench) },
    pureperl_ns     => sub { my $r = map_pureperl_ns    ($bench) },
    current         => sub { my $r = Array::map         ($bench, sub($x) { $x * 2 }) },
});

printf "\nmap versions that also filter undef.\n";
cmpthese(-1, {
    for_defined         => sub { my $r = map_for_defined    ($bench, sub($x) { $x * 2 }) },
    lambda_list         => sub { my $r = map_lambda_list    ($bench, sub($x) { $x * 2 }) },
    lambda_list2_i      => sub { my $r = map_lambda_list2_i ($bench, sub($x) { $x * 2 }) },
    lambda_list2        => sub { my $r = map_lambda_list2   ($bench, sub($x) { $x * 2 }) },
    for_defined_default => sub { my $r = map_for_defined    ($bench, sub     { $_ * 2 }) },
    lambda              => sub { my $r = map_lambda         ($bench, sub($x) { $x * 2 }) },
    lambda_default      => sub { my $r = map_lambda         ($bench, sub     { $_ * 2 }) },
    defined_default     => sub { my $r = map_defined_default($bench, sub     { $_ * 2 }) },
});

printf "\nno undef filtering.\n";
cmpthese(-1, {
    for              => sub { my $r = map_for             ($bench, sub($x) { $x * 2 }) },
    for_default_sig  => sub { my $r = map_for_default     ($bench, sub($x) { $x * 2 }) },
    for_default      => sub { my $r = map_for_default     ($bench, sub     { $_ * 2 }) },
    for_only_default => sub { my $r = map_for_only_default($bench, sub     { $_ * 2 }) },
    wo_undef         => sub { my $r = map_wo_undef        ($bench, sub($x) { $x * 2 }) },
});

printf "\ncurrent, pure-perl + eval versions.\n";
cmpthese(-1, {
    current         => sub { my $r = Array::map         ($bench, sub($x) { $x * 2 }) },
    current_default => sub { my $r = Array::map         ($bench, sub     { $_ * 2 }) },
    current_eval    => sub { my $r = Array::map_e       ($bench, '$_ * 2')           },
    pureperl        => sub { my $r = map_pureperl       ($bench) },
    eval            => sub { my $r = map_eval           ($bench, '$_ * 2') },
    undef_eval      => sub { my $r = map_undef_eval     ($bench, '$_ * 2') },
    list_eval       => sub { my $r = map_list_eval      ($bench, '$_ * 2') },
});

