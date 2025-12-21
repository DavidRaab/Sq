#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq; # -sig => 1;

sub add4s($x,$y,$z,$w) { $x + $y + $z + $w }
sub add4 {
    my ($x, $y, $z, $w) = @_;
    $x + $y + $z + $w;
}
sub maps($array, $f) {
    bless([map { $f->($_) } @$array], 'Array');
}
sub mapp {
    my ($array, $f) = @_;
    bless([map { $f->($_) } @$array], 'Array');
}

print "Benchmarking add4\n";
my $nums = Sq->rand->int(1,1E6)->take(4 * 10_000)->chunked(4)->to_array;
Sq->bench->compare(-1, {
    pure => sub {
        for my $args ( @$nums ) {
            add4(@$args);
        }
    },
    signature => sub {
        for my $args ( @$nums ) {
            add4s(@$args);
        }
    }
});

print "\nBenchmarking map\n";
my $add1 = sub { $_[0] + 1 };
Sq->bench->compare(-1, {
    mapp => sub {
        for my $args ( @$nums ) {
            mapp($args, $add1);
        }
    },
    maps => sub {
        for my $args ( @$nums ) {
            maps($args, $add1);
        }
    }
});

__END__
Benchmarking add4
           Rate signature      pure
signature 710/s        --      -14%
pure      830/s       17%        --

Benchmarking map
      Rate maps mapp
maps 171/s   --  -1%
mapp 172/s   1%   --