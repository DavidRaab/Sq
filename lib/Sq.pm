package Sq;
use 5.036;
our $VERSION = '0.006';
use Sub::Exporter -setup => {
    exports => [
        qw(id fst snd key assign),
    ],
    groups => {
        default => [qw(id fst snd key assign)],
    },
};
use Sq::Collections::Seq;

# Important functions used in FP code. So adding them.
sub id  :prototype($) { return $_[0]    }
sub fst :prototype($) { return $_[0][0] }
sub snd :prototype($) { return $_[0][1] }

# a helper to create a function for selecting a hash-key
sub key :prototype($) {
    my $name = $_[0];
    return sub($hash) { return $hash->{$name} };
}

# allows writing a code block to create a value
sub assign :prototype(&) {
    return $_[0]->();
}

1;

=head1 NAME

Sq - The Sq language

=cut
