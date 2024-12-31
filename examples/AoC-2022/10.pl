#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::Util qw(any);

my $processor = {
    register => 1,
    cycle    => 0,
    queue    => [],
};


# Adds a command to the queue, but does a transformation on it
sub add_command ($cmd, @args) {
    if ( $cmd eq 'noop' ) {
        push $processor->{queue}->@*, ['noop'];
    }
    elsif ( $cmd eq 'addx' ) {
        push $processor->{queue}->@*, (
            ['noop'],
            ['noop'],
            ['add', $args[0]],
        );
    }
    else {
        die "unknown command.\n";
    }
    return;
}

# Just funny object-orientet prototype like crap
sub add_method($obj, $name, $f) {
    $obj->{$name} = sub { return $f->($obj) };
}

# Add next as a function on the hash. Much like Prototype stuff
# Advance the processor for ony cycle
add_method($processor, next => sub ($self) {
    COMMAND:
    # Do nothing if queue is empty
    return if $self->{queue}->@* == 0;

    # otherwise read command
    my $command      = shift $self->{queue}->@*;
    my ($cmd, @args) = @$command;

    if ( $cmd eq 'noop' ) {
        $self->{cycle}++;
    }
    elsif ( $cmd eq 'add' ) {
        $self->{register} = $self->{register} + $args[0];
        goto COMMAND;
    }
    else {
        die "unknown command.\n";
    }

    return 1;
});

# parse the input and fill processor queue
while ( my $line = <> ) {
    if ( $line =~ m/\A noop \Z/xms ) {
        add_command('noop');
    }
    elsif ( $line =~ m/\A addx \s+ (-? \d+) \Z/xms ) {
        add_command('addx', $1);
    }
    else {
        die "unknown command\n";
    }
}

# p $processor;

sub show ($processor) {
    printf "Cycle: %d Register: %d\n", $processor->@{qw/cycle register/};
}

# run the processor
my $sum   = 0;
my $pixel = 0;
while ( $processor->{next}() ) {
    my ($cycle, $reg) = $processor->@{qw/cycle register/};

    # Calculate the sum
    if ( any { $cycle eq $_ } 20, 60, 100, 140, 180, 220 ) {
        # show $processor;
        $sum += $cycle * $reg;
    }

    # Draw Pixel
    my $char = (any { $pixel == $_ } $reg-1, $reg, $reg+1) ? "#" : ".";
    print $char;

    if ( ++$pixel == 40 ) {
        print "\n";
        $pixel = 0;
    }
}

printf "Signal strength: %d\n", $sum;
