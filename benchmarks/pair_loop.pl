#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
# use Sq -sig => 1;
use List::MoreUtils qw(natatime);

sub splice_mojo(@pairs) {
    my @cookies;
    while (my ($name, $value) = splice @pairs, 0, 2) {
        push @cookies, {name => $name, value => $value };
    }
}

# while, array slice
sub idx_while_slice(@pairs) {
    my (@cookies, $name, $value);
    my $idx = 0;
    my $max = @pairs;
    while ( $idx < $max ) {
        ($name, $value) = @pairs[$idx, $idx+1];
        push @cookies, {name => $name, value => $value};
        $idx += 2;
    }
}

# while, no array slice
sub idx_while_noslice(@pairs) {
    my (@cookies, $name, $value);
    my $idx = 0;
    my $max = @pairs;
    while ( $idx < $max ) {
        $name  = $pairs[$idx];
        $value = $pairs[$idx+1];
        push @cookies, {name => $name, value => $value};
        $idx += 2;
    }
}

sub idx_for_noslice(@pairs) {
    my (@cookies, $name, $value);
    my $max = @pairs;
    for (my $idx=0; $idx<$max; $idx+=2) {
        $name  = $pairs[$idx];
        $value = $pairs[$idx+1];
        push @cookies, {name => $name, value => $value};
    }
}

sub idx_for_slice(@pairs) {
    my (@cookies, $name, $value);
    my $max = @pairs;
    for (my $idx=0; $idx<$max; $idx+=2) {
        ($name,$value) = @pairs[$idx, $idx+1];
        push @cookies, {name => $name, value => $value};
    }
}

sub builtin(@pairs) {
    my @cookies;
    # Added with 5.036; not experimental anymore with 5.040
    for my ($name,$value) ( @pairs ) {
        push @cookies, {name => $name, value => $value};
    }
}

sub natatime_lmu(@pairs) {
    my @cookies;
    my $it = natatime 2, @pairs;
    while ( my @vals = $it->() ) {
        push @cookies, {name => $vals[0], value => $vals[1]};
    }
}

# Does something completely different as the other stuff, but i was
# still interested in it's performance as it also needs to loop over
# multiple values at once.
sub chunked(@pairs) {
    Array::chunked(\@pairs, 2)->iter(sub {});
}

# Same as chunked(), was curious. But disabled by default in benchmark
# because those functions do something fundamental different and cannot
# really be compared at all.
sub windowed(@pairs) {
    Array::windowed(\@pairs, 2);
}

my @data = map { (foo => $_) } 1 .. 100;
Sq->bench->compare(-1, {
    splice => sub {
        for ( 1 .. 1_000 ) {
            splice_mojo(@data);
        }
    },
    idx_while_slice => sub {
        for ( 1 .. 1_000 ) {
            idx_while_slice(@data);
        }
    },
    idx_while_noslice => sub {
        for ( 1 .. 1_000 ) {
            idx_while_noslice(@data);
        }
    },
    idx_for_slice => sub {
        for ( 1 .. 1_000 ) {
            idx_for_slice(@data);
        }
    },
    idx_for_noslice => sub {
        for ( 1 .. 1_000 ) {
            idx_for_noslice(@data);
        }
    },
    builtin => sub {
        for ( 1 .. 1_000 ) {
            builtin(@data);
        }
    },
    natatime => sub {
        for ( 1 .. 1_000 ) {
            natatime_lmu(@data);
        }
    },
    array_itern => sub {
        # an array_itern function is not created because this somehow
        # creates one function call overhead more than the other examples.
        # Directly calling itern() makes it more compareable. Still this
        # is not exactly the same as the other examples, also not the builtin
        # because it always goes over exact two values, when for example
        # an uneven amount is passed the last missing value with "undef" is
        # skipped. It still will always be slower because it is based on
        # lambdas and calling a function for every iteration.
        # That doesn't make it obsolete. As the whole goal is to also have a
        # Seq::itern() that works the same, but in a lazy way. Still when
        # you have have an array and you know exactly how many items you want
        # to loop and you know the amount of items is correct, then just
        # use the Perl built-in for-loop available since 5.36
        for ( 1 .. 1_000 ) {
            my @cookies;
            Array::itern(\@data, 2, sub($k,$v) {
                push @cookies, {name => $k, value => $v};
            });
        }
    },
    # chunked => sub {
    #     for ( 1 .. 1_000 ) {
    #         chunked(@data);
    #     }
    # },
    # windowed => sub {
    #     for ( 1 .. 1_000 ) {
    #         windowed(@data);
    #     }
    # },
});