#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Benchmark qw(cmpthese);

package Movie;
use Moose;

has 'title'  => ( is => 'rw', isa => 'Str' );
has 'rating' => ( is => 'rw', isa => 'Int' );
has 'desc'   => ( is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

package MoviePP;

sub new($class, %args) {
    return bless({
        title  => $args{title},
        rating => $args{rating},
        desc   => $args{desc},
    }, $class);
}

sub title($self, $title=undef) {
    if ( defined $title ) {
        $self->{title} = $title;
        return;
    }
    else {
        return $self->{title};
    }
}

sub rating($self, $rating=undef) {
    if ( defined $rating ) {
        $self->{rating} = $rating;
        return;
    }
    else {
        return $self->{rating};
    }
}

sub desc($self, $desc=undef) {
    if ( defined $desc ) {
        $self->{desc} = $desc;
        return;
    }
    else {
        return $self->{desc};
    }
}

package main;

sub movie(@args) {
    return Hash->new->lock(qw/title rating desc/)->set(@args);
}

cmpthese(-1, {
    moose => sub {
        for ( 1 .. 1_000 ) {
            my $m = Movie->new(
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            );
        }
    },
    sq_new => sub {
        for ( 1 .. 1_000 ) {
            my $m = Hash->new(
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            );
        }
    },
    sq_bless => sub {
        for ( 1 .. 1_000 ) {
            my $m = Hash->bless({
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            });
        }
    },
    sq_func => sub {
        for ( 1 .. 1_000 ) {
            my $m = movie(
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            );
        }
    },
    sq_bless_locked => sub {
        for ( 1 .. 1_000 ) {
            my $m = Hash->bless({
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            })->lock;
        }
    },
    sq_locked => sub {
        for ( 1 .. 1_000 ) {
            my $m = Hash->locked({
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            });
        }
    },
    perl_class => sub {
        for ( 1 ..  1_000 ) {
            my $m = MoviePP->new(
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            );
        }
    },
    perl_hash => sub {
        for ( 1 .. 1_000 ) {
            my $m = {
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            };
        }
    }
});
