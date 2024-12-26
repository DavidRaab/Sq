#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Getopt::Long::Descriptive;
use Benchmark qw(cmpthese);
use Devel::Size qw(size);

my ($opt, $usage) = describe_options(
    'Usage: %c %o',
    ['help|h', 'Print this message', {shortcircuit => 1}],
);

$usage->die if $opt->help;


sub queue() {
    my $queue = Queue->new(1..10_000);
    my $x     = 0;
    for ( 1 .. 1_000 ) {
        my ($one,$two) = $queue->remove(2);
        # my $two = $queue->remove;
        $queue->add($x .. ($x+4));
        $x = $x + 4;
    }
    # printf "Queue: %d\n", size($queue->{data});
    return;

}

sub perl_array() {
    my @queue = (1 .. 10_000);
    my $x     = 0;
    for ( 1 .. 1_000 ) {
        my $one = shift @queue;
        my $two = shift @queue;
        push @queue, $x .. ($x+4);
        $x = $x + 4;
    }
    # printf "Array: %d\n", size(\@queue);
    return;
}

# queue();
# perl_array();


cmpthese(-1, {
    'Queue'      => sub { queue()      },
    'Perl Array' => sub { perl_array() },
});
