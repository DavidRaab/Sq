#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Test2::V0 qw(is done_testing);
use Benchmark qw(cmpthese);

# Using goto on a subroutine reference means that no call-stack is created.
# It basically is a so called "tail-call optimization".
#
# But it doesn't mean it is faster or has better performance. A tail-call
# optimization can be helpful with multiple nested callbacks that only
# go forward as it reduces memory consumption a lot. Tail-call function
# can work properly with recursive calls that call itself even if the
# recursion depth is 10,000+ or any other higher number. Because the call
# stack depth stays at 1.
#
# 2024-11-15: At this moment benchmark results on my machine shows
#             that match_opt is around 50% faster with a nearly empty
#             function body.

sub match_opt($opt, %args) {
    my $fSome = $args{Some} or Carp::croak "Some not defined";
    my $fNone = $args{None} or Carp::croak "None not defined";
    if ( @$opt ) {
        return $fSome->($opt->[0]);
    }
    else {
        return $fNone->();
    }
}

sub match_goto {
    my ($opt, %args) = @_;
    my $fSome = $args{Some} or Carp::croak "Some not defined";
    my $fNone = $args{None} or Carp::croak "None not defined";
    if ( @$opt ) {
        @_ = $opt->[0];
        goto $fSome;
    }
    else {
        @_ = ();
        goto $fNone;
    }
}

# test if same
{
    my $x = Some 10;
    my $y = None;

    my $some = sub($x) { $x + 1 };
    my $none = sub     { 0      };

    is(
        match_opt ($x, Some => $some, None => $none),
        match_goto($x, Some => $some, None => $none),
        'match on x');

    is(
        match_opt ($y, Some => $some, None => $none),
        match_goto($y, Some => $some, None => $none),
        'match on y');

    done_testing;
}

my $opts = Array->init(10_000, sub($idx) { Some $idx });
cmpthese(-1, {
    match_opt => sub {
        for my $opt ( @$opts ) {
            match_opt($opt,
                Some => sub($x) { $x },
                None => sub($x) { 0  },
            );
        }
    },
    match_goto => sub {
        for my $opt ( @$opts ) {
            match_goto($opt,
                Some => sub($x) { $x },
                None => sub($x) { 0  },
            );
        }
    },
});
