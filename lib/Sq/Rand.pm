package Sq::Rand;
use 5.036;
use Sq;

sub load_signature($) {
    # require Sq::Sig::Rand;
}

static int => sub($min,$max) {
    my $diff = ($max - $min) + 0.5;
    bless(sub {
        return sub {
            return int($min + rand($diff));
        }
    }, 'Seq');
};

static num => sub($min,$max) {
    my $diff = ($max - $min);
    bless(sub {
        return sub {
            return $min + rand($diff);
        };
    }, 'Seq');
};

static str => with_dispatch(
    type [tuple => ['int'],['int']] => sub($min,$max) {
        state @chars = ('a' .. 'z', 'A' .. 'Z', 0 .. 9, ' ');
        state $count = @chars;
        my $diff     = $max - $min;
        return bless(sub {
            my $len;
            return sub {
                $len = $min + rand($diff);
                my $str;
                for ( 1 .. $len ) {
                    $str .= $chars[rand $count];
                }
                return $str;
            }
        }, 'Seq');
    },
    type [tuple => ['int'],['int'],['str']] => sub($min,$max,$str) {
        my @chars = split //, $str;
        my $count = @chars;
        my $diff  = $max - $min;
        return bless(sub {
            my $len;
            return sub {
                $len = $min + rand($diff);
                my $str;
                for ( 1 .. $len ) {
                    $str .= $chars[rand $count];
                }
                return $str;
            }
        }, 'Seq');
    },
);

1;