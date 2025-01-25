package Sq::Rand;
use 5.036;
use Sq;

sub load_signature($) {
    # require Sq::Sig::Rand;
}

static int => sub($min,$max) {
    bless(sub{
        my $diff = ($max - $min) + 0.5;
        return sub {
            return int($min + rand($diff));
        }
    }, 'Seq');
};

1;