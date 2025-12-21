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

__END__
           Rate signature      pure
signature 710/s        --      -13%
pure      815/s       15%        --
