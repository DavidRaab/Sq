#!perl
use 5.036;
use List::Util qw(reduce);
use Seq qw(id fst snd key);
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use DDP;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $add1    = sub($x) { $x + 1      };
my $double  = sub($x) { $x * 2      };
my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

#----------

sub range($start, $stop) {
    # NO CODE SHOULD BE HERE
    # OTHERWISE WILL BE CAUSE OF BUGS
    return Seq->from_sub(sub {
        # Initialization code for a sequence
        my $current = $start;

        # The iterator returning one element when asked
        return sub {
            # As long $current is equal or smaller
            if ( $current <= $stop ) {
                # return $current and +1 it
                return $current++;
            }
            # otherwise return undef to indicate end of sequence
            else {
                return undef;
            }
        }
    });
}

my $r = range(1,10);
is($r->to_array, Seq->range(1,10)->to_array, 'from_sub');
is($r->to_array, Seq->range(1,10)->to_array, 'from_sub');

done_testing;
