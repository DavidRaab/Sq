#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use Getopt::Long::Descriptive;
use Sq;
use Test2::V0;
use Benchmark qw(cmpthese);

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;

my $list = List->range(1,1000);

my $mut_append = sub($list, $x) {
    my $new    = bless([], 'List');
    $list->[0] = $x;
    $list->[1] = $new;
    return $new;
};

sub mut_append($list, $x) {
    my $new    = bless([], 'List');
    $list->[0] = $x;
    $list->[1] = $new;
    return $new;
};

sub is_empty_v1($list) {
    return 1 if Scalar::Util::reftype $list eq 'ARRAY' && @$list == 0;
    return 0;
}

sub head_v1($list) {
    return $list->[0];
}

sub head_v2($list) {
    return undef if Scalar::Util::reftype $list ne 'ARRAY' || @$list == 0;
    return $list->[0];
}

sub head_v3($list) {
    return undef if @$list == 0;
    return $list->[0];
}

# most readable implementation
sub foldBack_stack_v1($list, $state, $folder) {
    my $l = $list;

    # First build a stack from list
    my @stack;
    while ( not is_empty_v1($l) ) {
        push @stack, $l->[0];
        $l = $l->[1];
    }

    # build new state by pop every element from stack
    my $s = $state;
    while ( my $x = pop @stack ) {
        $s = $folder->($s, $x);
    }

    return $s;
}

# head_v2 instead of is_empty call
sub foldBack_stack_v2($list, $state, $folder) {
    my $l = $list;

    # First build a stack from list
    my @stack;
    my $x;
    while ( $x = head_v2($l) ) {
        push @stack, $x;
        $l = $l->[1];
    }

    # build new state by pop every element from stack
    my $s = $state;
    while ( my $x = pop @stack ) {
        $s = $folder->($s, $x);
    }

    return $s;
}

# removed is_empty or head alltogether and just test array count
sub foldBack_stack_v3($list, $state, $folder) {
    my $l = $list;

    # First build a stack from list
    my @stack;
    my $x;
    while ( @$l != 0 ) {
        push @stack, $l->[0];
        $l = $l->[1];
    }

    # build new state by pop every element from stack
    my $s = $state;
    while ( my $x = pop @stack ) {
        $s = $folder->($s, $x);
    }

    return $s;
}

# index instead of pop
sub foldBack_stack_v4($list, $state, $folder) {
    my $l = $list;

    # First build a stack from list
    my @stack;
    my $x;
    while ( @$l != 0 ) {
        push @stack, $l->[0];
        $l = $l->[1];
    }

    # build new state by pop every element from stack
    my $s = $state;
    for (my $idx = $#stack; $idx >= 0; $idx--) {
        $s = $folder->($s, $stack[$idx]);
    }

    return $s;
}

# reverse @stack before running through it forwards
sub foldBack_stack_v5($list, $state, $folder) {
    my $l = $list;

    # First build a stack from list
    my @stack;
    my $x;
    while ( @$l != 0 ) {
        push @stack, $l->[0];
        $l = $l->[1];
    }
    @stack = reverse @stack;

    # build new state
    my $s = $state;
    for my $x ( @stack ) {
        $s = $folder->($s, $x);
    }

    return $s;
}

# index based for-loop
sub foldBack_stack_v6($list, $state, $folder) {
    my $l = $list;

    # First build a stack from list
    my @stack;
    my $x;
    while ( @$l != 0 ) {
        push @stack, $l->[0];
        $l = $l->[1];
    }
    @stack = reverse @stack;

    # build new state
    my $s = $state;
    for (my $idx=0; $idx < @stack; $idx++) {
        $s = $folder->($s, $stack[$idx]);
    }

    return $s;
}

# first implementation
sub map_v1($list, $f) {
    return foldBack_stack_v1($list, List->empty, sub($state, $x) {
        List->cons($f->($x), $state);
    });
}

# uses head_v2 instead of is_empty & head
sub map_v2($list, $f) {
    return foldBack_stack_v2($list, List->empty, sub($state, $x) {
        List->cons($f->($x), $state);
    });
}

# implementation using $mut_append instead of foldBack
sub map_v3($list, $f) {
    my $new  = List::empty('List');
    my $tail = $new;
    while ( not is_empty_v1($list) ) {
        $tail = $mut_append->($tail, $f->( $list->[0] ));
        $list = $list->[1];
    }
    return $new;
}

# no anoymous function compared to map_v3
sub map_v4($list, $f) {
    my $new  = List::empty('List');
    my $tail = $new;
    while ( not is_empty_v1($list) ) {
        $tail = mut_append($tail, $f->( $list->[0] ));
        $list = $list->[1];
    }
    return $new;
}

# removing $mut_append call
sub map_v5($list, $f) {
    my $new  = List::empty('List');
    my $tail = $new;
    while ( not is_empty_v1($list) ) {
        my $empty = bless([], 'List');
        $tail->[0] = $f->( $list->[0] );
        $tail->[1] = $empty;
        $tail      = $empty;
        $list      = $list->[1];
    }
    return $new;
}

# removing $mut_append call
sub map_v6($list, $f) {
    my $new  = List::empty('List');
    my $tail = $new;
    while ( @$list != 0 ) {
        my $empty = bless([], 'List');
        $tail->[0] = $f->( $list->[0] );
        $tail->[1] = $empty;
        $tail      = $empty;
        $list      = $list->[1];
    }
    return $new;
}

# uses head_v2 instead of is_empty & head
sub map_v7($list, $f) {
    return foldBack_stack_v3($list, List->empty, sub($state, $x) {
        List->cons($f->($x), $state);
    });
}

# uses foldback_stack_v4
sub map_v8($list, $f) {
    return foldBack_stack_v4($list, List->empty, sub($state, $x) {
        List->cons($f->($x), $state);
    });
}

# uses foldback_stack_v5
sub map_v9($list, $f) {
    return foldBack_stack_v5($list, List->empty, sub($state, $x) {
        List->cons($f->($x), $state);
    });
}

# uses foldback_stack_v6
sub map_v10($list, $f) {
    return foldBack_stack_v6($list, List->empty, sub($state, $x) {
        List->cons($f->($x), $state);
    });
}

# Testing if implementations are correct
my $tl = List->range(1,10);
my $double = sub($x) { $x * 2 };
for my $func ( qw/map_v1 map_v2 map_v3 map_v4 map_v5 map_v6 map_v7 map_v8 map_v9 map_v10/ ) {
    no strict 'refs';
    is($tl->map($double), *{$func}->($tl, $double), $func);
}
done_testing;

# Benchmarking
print "\nBenchmarking foldBack implementations\n";
cmpthese(-1, {
    'List->map' => sub { my $xs = $list->map($double) },
    'map_v1'  => sub { my $xs = map_v1($list, $double) },
    'map_v2'  => sub { my $xs = map_v2($list, $double) },
    'map_v7'  => sub { my $xs = map_v7($list, $double) },
    'map_v8'  => sub { my $xs = map_v8($list, $double) },
    'map_v9'  => sub { my $xs = map_v9($list, $double) },
    'map_v10' => sub { my $xs = map_v10($list, $double) },
});
print "\n";

print "Benchmarking map implementations\n";
cmpthese(-1, {
    'List->map' => sub { my $xs = $list->map($double) },
    'map_v3' => sub { my $xs = map_v3($list, $double) },
    'map_v4' => sub { my $xs = map_v4($list, $double) },
    'map_v5' => sub { my $xs = map_v5($list, $double) },
    'map_v6' => sub { my $xs = map_v6($list, $double) },
});

