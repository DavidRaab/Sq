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
        title  => $args{title}  // "",
        rating => $args{rating} // 0,
        desc   => $args{desc}   // "",
    }, $class);
}

# this is the fastest way i come up writing getter/setter. Not using shift,
# perl signature or unpacking @_ makes it fast, but ugly code.
# Avoiding the else{} branch makes a hhue performance impact. Don't really
# understand why.
sub title {
    # checking for defined is faster than checking array-length, but now
    # title cannot set to undef anymore.
    $_[0]->{title} = $_[1] if defined $_[1]; #@_ >= 2;
    return $_[0]->{title};
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

printf "Benchmarking initialization\n";
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
    sq => sub {
        for ( 1 .. 1_000 ) {
            my $m = sq {
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            };
        }
    },
    "Hash->new" => sub {
        for ( 1 .. 1_000 ) {
            my $m = Hash->new(
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            );
        }
    },
    "Hash->bless" => sub {
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
    sq_func_inlined => sub {
        for ( 1 .. 1_000 ) {
            my $m = Hash->new->lock(qw/title rating desc/)->set(
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
    # Fastest
    perl_hash => sub {
        for ( 1 .. 1_000 ) {
            my $m = {
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            };
        }
    },
    perl_hash_bless => sub {
        for ( 1 .. 1_000 ) {
            my $m = bless({
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            }, 'Hash');
        }
    },
});

# examples for benchmarks
my $hash = {
    title  => 'Terminator 2',
    rating => 5,
    desc   => 'Awesome',
};

my $locked = Hash->locked({
    title  => 'Terminator 2',
    rating => 5,
    desc   => 'Awesome',
});

my $obj = MoviePP->new(
    title  => 'Terminator 2',
    rating => 5,
    desc   => 'Awesome',
);

my $moose = Movie->new(
    title  => 'Terminator 2',
    rating => 5,
    desc   => 'Awesome',
);

printf "\nReading just title\n";
cmpthese(-1, {
    moose => sub {
        for ( 1 .. 1_000 ) {
            my $title = $moose->title;
        }
    },
    sq_locked => sub {
        for ( 1 .. 1_000 ) {
            my $title = $locked->{title};
        }
    },
    perl_class => sub {
        for ( 1 .. 1_000 ) {
            my $title = $obj->title;
        }
    },
    perl_hash => sub {
        for ( 1 .. 1_000 ) {
            my $title = $hash->{title};
        }
    },
});

printf "\nSetting title to a new value\n";
cmpthese(-1, {
    moose => sub {
        for ( 1 .. 1_000 ) {
            $moose->title('Terminator 3');
        }
    },
    sq_locked => sub {
        for ( 1 .. 1_000 ) {
            $locked->{title} = 'Terminator 3';
        }
    },
    perl_class => sub {
        for ( 1 .. 1_000 ) {
            $obj->title('Terminator 3');
        }
    },
    perl_hash => sub {
        for ( 1 .. 1_000 ) {
            $hash->{title} = 'Terminator 3';
        }
    },
});