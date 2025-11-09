package Sq::Queue;
package Queue;
use 5.036;
use subs 'foreach';

sub new($class, @xs) {
    my $queue = bless([], 'Queue');
    push @$queue, @xs;
    return $queue;
}

sub length($queue) { return scalar @$queue }

sub add($queue, @xs) {
    push @$queue, @xs;
    return;
}

sub remove($self, $amount=1) {
    if ( $amount == 1 ) {
        return shift @$self;
    }
    elsif ( $amount > 1 ) {
        my @ret;
        my $x;
        for ( 1 .. $amount ) {
            $x = shift @$self;
            return @ret if !defined $x;
            push @ret, $x;
        }
        return @ret;
    }
    return;
}

sub to_array($queue) {
    return bless([@$queue], 'Array');
}

1;