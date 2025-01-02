package Sq::Fmt;
use 5.036;
use Sq;

# This will be a module that help in formating/printing things.
# For example pass it an array of array and it prints a table.

sub table($, $href) {
    my $header = $href->{header};
    my $aoa    = $href->{data};

    # Calling functions in function-style has the benefit that they always
    # work. You don't need to add a blessing to be sure. This can potential
    # increase performance. But the impact isn't that big.
    #
    # Instead of `sq` you also can use Array->bless, Hash->bless to just bless
    # the first level, sometimes that can also be enough, as every function
    # always returns blessed data.
    my $maxY = Array::length($aoa);
    return if $maxY == 0;
    my $maxX = Array::map($aoa, call 'length')->max->or(0);
    return if $maxX == 0;

    # just turn AoA into string lengths
    my $sizes = assign {
        my $sizes = defined $header ? [$header, @$aoa] : $aoa;
        Array::map($sizes, sub($array) {
            Array::map($array, sub ($str) { length $str })
        });
    };

    # dumpw($sizes);

    # determine max column sizes
    my @cols;
    for (my $x=0; $x < $maxX; $x++) {
        my $max = 0;
        for (my $y=0; $y < $maxY; $y++) {
            my $cur = $sizes->[$y][$x];
            $max = $cur > $max ? $cur : $max;
        }
        push @cols, $max;
    }

    # dumpw(\@cols)

    # Print header when defined
    if ( defined $header ) {
        print "| ";
        for (my $x=0; $x < $maxX; $x++ ) {
            my $length = $cols[$x];
            printf "%-${length}s", $header->[$x];
            print " | ";
        }
        print "\n";
        my $l     = @cols - 1;
        my $width = Array::sum(\@cols) + ($l * 3);
        print "| ", ('-' x $width), " |", "\n";
    }

    # print data
    for (my $y=0; $y < $maxY; $y++) {
        print "| ";
        for (my $x=0; $x < $maxX; $x++ ) {
            my $length = $cols[$x];
            printf "%-${length}s", $aoa->[$y][$x];
            print " | ";
        }
        print "\n";
    }

    return;
}

1;