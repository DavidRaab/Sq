#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Test;
use Benchmark qw(cmpthese);

sub rev1($array) {
    my @array;
    my $idx  = $array->$#*;
    while ( $idx >= 0 ) {
        push @array, $array->[$idx--];
    }
    return \@array;
}

sub rev2($array) {
    return CORE::bless([reverse @$array], 'Array');
}

sub rev3($array) {
    my $new = [reverse @$array];
    return CORE::bless($new, 'Array');
}

sub rev4($array) {
    my @new = reverse @$array;
    return CORE::bless(\@new, 'Array');
}

my $data = [1..10_000];

# check if it is really the same
my @funcs = (qw/rev1 rev2 rev3 rev4/);
for my $func ( @funcs ) {
    no strict 'refs'; ## no critic
    my $fn = *{$func}{CODE};
    is($fn->($data), [reverse @$data], "check $func");
    # short check that array did not change
    is($data, [1..10_000], '$data did not change');
}
done_testing();

# Benchmarking
cmpthese(-1, {
    rev1       => sub { my $n2 = rev1($data)       },
    rev2       => sub { my $n2 = rev2($data)       },
    rev3       => sub { my $n2 = rev3($data)       },
    rev4       => sub { my $n2 = rev4($data)       },
    current    => sub { my $n2 = Array::rev($data) },
    'built-in' => sub { my $n2 = [ reverse @$data ]  },
});
