#!/usr/bin/env perl
use 5.040;
use utf8;
use open ':std', ':encoding(UTF-8)';

package Shape::Base;
use Moose::Role;
requires 'area';

package Shape::Square;
use Moose;
with 'Shape::Base';

has 'side' => (is => 'ro', isa => 'Num');

sub area($self) {
    return $self->side * $self->side;
}

__PACKAGE__->meta->make_immutable();

package Shape::Rectangle;
use Moose;
with 'Shape::Base';

has 'width'  => (is => 'ro', isa => 'Num');
has 'height' => (is => 'ro', isa => 'Num');

sub area($self) {
    return $self->width * $self->height;
}

__PACKAGE__->meta->make_immutable();

package Shape::Triangle;
use Moose;
with 'Shape::Base';

has 'base'   => (is => 'ro', isa => 'Num');
has 'height' => (is => 'ro', isa => 'Num');

sub area($self) {
    return $self->base * $self->height * 0.5;
}

__PACKAGE__->meta->make_immutable();

package Shape::Circle;
use Moose;
with 'Shape::Base';

has 'radius'  => (is => 'ro', isa => 'Num');

sub area($self) {
    return $self->radius * $self->radius * 3.141592654;
}

__PACKAGE__->meta->make_immutable();


package main;
use Benchmark qw(timestr timeit);

# Whewre does this method go in OOP anyway?
sub totalArea(@shapes) {
    my $accum = 0;
    for my $shape ( @shapes ) {
        $accum += $shape->area;
    }
    return $accum;
}

my @shapes;
my $time = timeit(10, sub {
    @shapes = ();
    for ( 1 .. 10_000 ) {
        my $rng = int rand 4;
        my $shape;
        if ( $rng == 0 ) {
            push @shapes, Shape::Square->new(side => 2);
        }
        elsif ( $rng == 1 ) {
            push @shapes, Shape::Rectangle->new(width => 2, height => 3);
        }
        elsif ( $rng == 2 ) {
            push @shapes, Shape::Triangle->new(base => 3, height => 1);
        }
        else {
            push @shapes, Shape::Circle->new(radius => 3);
        }
    }
});
printf "Creation 10K: %s\n", timestr($time);

my $area = 0;
$time = timeit(100, sub {
    $area = totalArea(@shapes);
});
printf "Area 10K: %f %s\n", $area, timestr($time);

__END__
Creation 10K:  0 wallclock secs ( 0.14 usr +  0.01 sys =  0.15 CPU) @ 66.67/s (n=10)
Area 10K: 100166.175389  0 wallclock secs ( 0.37 usr +  0.00 sys =  0.37 CPU) @ 270.27/s (n=100)
