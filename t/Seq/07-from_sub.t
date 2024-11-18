#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use FindBin qw($Bin);
use Path::Tiny;
use IO::File;
# use DDP;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };


#------ range wit Seq->from_sub ------#

# Example to implement own range() with Seq->from_sub(). not completely
# identical to built-in. But demonstrates the concept behind it

sub range($start, $stop) {
    ###-- -- -- -- -- IMPORTANT -- -- -- -- --###
    #          NO CODE SHOULD BE HERE           #
    #    Otherwise it will be CAUSE of BUGS.    #
    # You also should never manipulate function #
    # arguments not even assign a new value to  #
    # it. Do an explicit new assignment in the  #
    #          INITIALIZATION STAGE             #
    ###-- -- -- -- -- -- --- -- -- -- -- -- --###
    return Seq->from_sub(sub {
        # INITIALIZATION STAGE:
        my $current = $start;

        # The iterator returning one element when asked
        return sub {
            # As long $current is equal or smaller
            if ( $current <= $stop ) {
                # return $current and increase by 1
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
is($r->to_array, Seq->range(1,10)->to_array, 'testing that $r is not exhausted');


#------ Creating iterator from file ------#

sub from_file($file) {
    return Seq->from_sub(sub {
        open my $fh, '<', $file or die "Cannot open: $!\n";

        return sub {
            if ( defined $fh ) {
                if (defined(my $line = <$fh>)) {
                    return $line;
                }
                else {
                    close $fh;
                    $fh = undef;
                }
            }
            return undef;
        };
    });
}

# open a file from test directory
my $test_dir = path($Bin, qw/data 07-from_sub/);
my $file     = from_file($test_dir->child('text.txt'));

is(
    $file->to_array,
    [
        "Testing\n",
        "File\n",
        "Handle\n",
    ],
    'check content of file');

is($file->length, 3, 'line count');
is($file->length, 3, 'should return 3 again');
is(
    $file
    ->filter(sub($x) { $x =~ m/test/i })
    ->length,

    1,
    'one line containing test');

is($file->skip(1) ->first->or('EMPTY'), "File\n", 'getting second line');
is($file->skip(10)->first->or('EMPTY'), "EMPTY",  'getting default value');
is($file->skip(10)->first,        None, 'getting undef');

my $length_of_lines =
    $file->map(sub($line) { length $line });

is($length_of_lines->to_array, [8, 5, 7],    'line lengths');
is($length_of_lines->reduce($add), Some(20), 'characters in file');


#------ Create a temp-file for testing lazyiness

my $temp_name = Path::Tiny->tempfile('PerlSeqTmpXXXXXX');
my $fh        = $temp_name->openrw;

my $temp   = from_file($temp_name);
my $first  = $temp->filter(sub ($x) { $x =~ m/first/i  });
my $second = $temp->filter(sub ($x) { $x =~ m/second/i });
my $third  = $temp->filter(sub ($x) { $x =~ m/third/i  });

# on empty file
is($temp->length,     0, '0 - empty file');
is($first->first,  None, '0 - no first');
is($second->first, None, '0 - no second');
is($third->first,  None, '0 - no third');

# add one line to file
$fh->printflush("First Line\n");

# run tests again
is($temp->length,                      1, '1 - 1 line');
is($first->first,   Some("First Line\n"), '1 - first line');
is($second->first,                  None, '1 - no second');
is($third->first,                   None, '1 - no third');

# add second line
$fh->printflush("Second Line\n");

# run tests again
is($temp->length,                       2, '2 - 2 lines');
is($first->first,   Some( "First Line\n"), '2 - first line');
is($second->first,  Some("Second Line\n"), '2 - second line');
is($third->first,                    None, '2 - no third');

# add third line
$fh->printflush("Third Line\n");

# run tests again
is($temp->length,                       3, '3 - 3 lines');
is($first->first,    Some("First Line\n"), '3 - first line');
is($second->first,  Some("Second Line\n"), '3 - second line');
is($third->first,    Some("Third Line\n"), '3 - third lines');

close $fh;
undef $temp;


my $always = Seq->from_sub(sub {
    return sub {
        return 1;
    }
});

is($always->take(10)->to_array, [1,1,1,1,1,1,1,1,1,1], '10 times 1');


#------ Check if from_sub stops on first undef ------#

my $contains_undef = Seq->from_sub(sub {
    my @data = (1,2,3,undef,4,5,6);
    my $idx  = 0;
    return sub {
        # This ust work because of two reason.
        #  1. index 3 returns undef, so it should abort there
        #  2. index 7+ also returns undef
        return $data[$idx++];
    }
});

is($contains_undef->to_array,      [1,2,3], 'contains undef 1');
is($contains_undef->skip(2)->to_array, [3], 'contains undef 2');
is($contains_undef->skip(3)->to_array,  [], 'contains undef 3');
is($contains_undef->skip(4)->to_array,  [], 'contains undef 4');
is($contains_undef->skip(5)->to_array,  [], 'contains undef 5');

# test internal
my $it = $contains_undef->();
is($it->(), 1,     'it 1');
is($it->(), 2,     'it 2');
is($it->(), 3,     'it 3');
is($it->(), undef, 'it 4');
is($it->(), undef, 'it 5');
is($it->(), undef, 'it 6');

done_testing;
