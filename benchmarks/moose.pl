#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;

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
    return hash->lock(qw/title rating desc/)->set(@args);
}

printf "Benchmarking initialization\n";
Sq->bench->compare(-1, {
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
    'hash()'    => sub {
        for ( 1 .. 1_000 ) {
            my $m = hash(
                title  => 'Terminator 2',
                rating => 5,
                desc   => 'Awesome',
            );
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
    sq_func_locked => sub {
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
            my $m = hash->lock(qw/title rating desc/)->set(
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
    manual_hash_bless => sub {
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
Sq->bench->compare(-1, {
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
Sq->bench->compare(-1, {
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

__END__
Benchmarking initialization
                    Rate sq_func_locked sq_func_inlined moose   sq sq_bless_locked sq_locked perl_class Hash->new Hash->bless hash() manual_hash_bless perl_hash
sq_func_locked     411/s             --            -12%  -27% -51%            -68%      -75%       -77%      -79%        -87%   -87%              -90%      -92%
sq_func_inlined    469/s            14%              --  -16% -45%            -63%      -71%       -74%      -76%        -85%   -85%              -89%      -91%
moose              560/s            36%             19%    -- -34%            -56%      -66%       -69%      -71%        -82%   -83%              -87%      -89%
sq                 845/s           106%             80%   51%   --            -34%      -49%       -53%      -56%        -72%   -74%              -80%      -83%
sq_bless_locked   1274/s           210%            172%  128%  51%              --      -23%       -30%      -34%        -59%   -61%              -70%      -75%
sq_locked         1644/s           300%            250%  194%  94%             29%        --        -9%      -15%        -46%   -49%              -61%      -67%
perl_class        1810/s           341%            286%  223% 114%             42%       10%         --       -6%        -41%   -44%              -57%      -64%
Hash->new         1932/s           370%            312%  245% 129%             52%       18%         7%        --        -37%   -40%              -54%      -62%
Hash->bless       3070/s           647%            554%  449% 263%            141%       87%        70%       59%          --    -5%              -27%      -39%
hash()            3229/s           686%            588%  477% 282%            153%       96%        78%       67%          5%     --              -23%      -36%
manual_hash_bless 4186/s           919%            792%  648% 395%            229%      155%       131%      117%         36%    30%                --      -17%
perl_hash         5024/s          1123%            971%  798% 494%            294%      206%       178%      160%         64%    56%               20%        --

Reading just title
              Rate      moose perl_class  perl_hash  sq_locked
moose       6981/s         --        -5%       -72%       -72%
perl_class  7313/s         5%         --       -71%       -71%
perl_hash  24888/s       257%       240%         --        -1%
sq_locked  25048/s       259%       242%         1%         --

Setting title to a new value
              Rate      moose perl_class  sq_locked  perl_hash
moose       5119/s         --       -42%       -80%       -81%
perl_class  8805/s        72%         --       -65%       -67%
sq_locked  25121/s       391%       185%         --        -5%
perl_hash  26305/s       414%       199%         5%         --
