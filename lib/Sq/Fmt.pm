package Sq::Fmt;
use 5.036;
use Sq;

# This will be a module that help in formating/printing things.
# For example pass it an array of array and it prints a table.

sub table($, $href) {
    my $header = $href->{header};
    my $aoa    = $href->{data};

    my $maxY = $aoa->length;
    my $maxX = $aoa->map(call 'length')->max->or(0);
    return if $maxX == 0;

    # just turn AoA into string lengths
    my $sizes = assign {
        my $sizes = $aoa;
        if ( defined $header ) {
            $sizes = sq [$header, @$aoa];
        }

        $sizes->map(sub($array) {
            $array->map(sub ($str) { length $str })
        });
    };

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