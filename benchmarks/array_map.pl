#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Sq;
use Benchmark qw(cmpthese);
use Test2::V0;

# this is the fastest way to write in Perl, without arguments and no undef checking
sub map_builtin($array) {
    local $_;
    my @new = map { $_ * 2 } @$array;
    return CORE::bless(\@new, 'Array');
}

# somehow not using an extra line to assign to @new makes it A LOT (15%+) slower
sub map_builtin_inline($array) {
    local $_;
    return CORE::bless([map { $_ * 2 } @$array], 'Array');
}

# same as builtin - but don't uses signature feature - old school perl
sub map_builtin_ns {
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
    my @new;
    for my $x ( @$array ) {
        my $value = $f->($x);
        push @new, $value if defined $value;
    }
    return CORE::bless(\@new, 'Array');
}

# lambda + undef checking + lambda returns list
# closest to perl built-in with added undef checking
sub map_lambda_list($array, $f) {
    my @new;
    for my $x ( @$array ) {
        push @new, grep { defined } $f->($x);
    }
    return CORE::bless(\@new, 'Array');
}

# same as before but mapping and greping in two invocations
sub map_lambda_list2($array, $f) {
    my @new =
        grep { defined  }
        map  { $f->($_) } @$array;
    return CORE::bless(\@new, 'Array');
}

sub map_lambda_list2_i($array, $f) {
    return CORE::bless([
        grep { defined  }
        map  { $f->($_) } @$array
    ], 'Array');
}

# same as lambda, but used default variable instead of passing it as argument
sub map_lambda_def($array, $f) {
    my @new;
    local $_;
    for ( @$array ) {
        my $value = $f->();
        push @new, $value if defined $value;
    }
    return CORE::bless(\@new, 'Array');
}

# lambda, but no udef checking
sub map_wo_undef($array, $f) {
    return CORE::bless([map { $f->($_) } @$array], 'Array');
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
my @numbers    = (1 .. 10);
my @result     = (2,4,6,8,10,12,14,16,18,20);
my @maps = (
    map_builtin       (\@numbers),
    map_builtin_ns    (\@numbers),
    map_builtin_inline(\@numbers),
    map_lambda        (\@numbers, sub($x) { $x * 2 }),
    map_lambda_list   (\@numbers, sub($x) { $x * 2 }),
    map_lambda_list2  (\@numbers, sub($x) { $x * 2 }),
    map_lambda_list2_i(\@numbers, sub($x) { $x * 2 }),
    map_wo_undef      (\@numbers, sub($x) { $x * 2 }),
    map_undef_eval    (\@numbers, '$_ * 2'),
    map_eval          (\@numbers, '$_ * 2'),
    map_list_eval     (\@numbers, '$_ * 2'),
    map_lambda_def    (\@numbers, sub { $_ * 2 }),
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

cmpthese(-1, {
    builtin        => sub { my $r = map_builtin       ($bench) },
    builtin_ns     => sub { my $r = map_builtin_ns    ($bench) },
    builtin_inline => sub { my $r = map_builtin_inline($bench) },
    lambda         => sub { my $r = map_lambda        ($bench, sub($x) { $x * 2 }) },
    lambda_list    => sub { my $r = map_lambda_list   ($bench, sub($x) { $x * 2 }) },
    lambda_list2   => sub { my $r = map_lambda_list2  ($bench, sub($x) { $x * 2 }) },
    lambda_list2_i => sub { my $r = map_lambda_list2_i($bench, sub($x) { $x * 2 }) },
    without_undef  => sub { my $r = map_wo_undef      ($bench, sub($x) { $x * 2 }) },
    undef_eval     => sub { my $r = map_undef_eval    ($bench, '$_ * 2') },
    eval           => sub { my $r = map_eval          ($bench, '$_ * 2') },
    list_eval      => sub { my $r = map_list_eval     ($bench, '$_ * 2') },
    lambda_def     => sub { my $r = map_lambda_def    ($bench, sub { $_ * 2 }) },
});
