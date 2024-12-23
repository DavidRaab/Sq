package Sq::Test;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [qw/is ok nok done_testing/],
    groups  => {
        default => [qw/is ok nok done_testing/],
    }
};
# use Carp qw(carp);

# A simple Test system in the spirit of Sq. Just minimal functions
# that work, and do the stuff. Maybe it will just provide
# the functions. is, ok, nok, like, dies.

# In a data-centered approach all you really need is just comparing
# data for testing.

# Actually Testing is always just about comparing data!

my $count = 0;

sub ok($bool, $message) {
    $count++;
    if ( $bool ) {
        print "ok - $message\n"
    }
    else {
        print "not ok - $message\n";
    }
    return;
}

sub nok($bool, $message) {
    $count++;
    if ( $bool ) {
        print "not ok - $message\n";
    }
    else {
        print "ok - $message\n"
    }
    return;
}

sub is($got, $expected, $message) {
    $count++;
    if ( equal($got, $expected) ) {
        print "ok - $message\n";
    }
    else {
        print "not ok - $message\n";
        my $dump_1 = Sq::Dump::dump($got);
        my $dump_2 = Sq::Dump::dump($expected);
        # add # to beginning of every starting line
        $dump_1 =~ s/^/# /mg;
        $dump_2 =~ s/^/# /mg;
        print "# Got:\n", $dump_1, "\n# Expected:\n", $dump_2, "\n";
    }
    return;
}

sub done_testing() {
    print "1..$count\n";
}

1;