package Sq::Test;
use 5.036;
use Sq;
use Sub::Exporter -setup => {
    exports => [qw/is ok nok done_testing dies like check_isa/],
    groups  => {
        default => [qw/is ok nok done_testing dies like check_isa/],
    }
};
# use Carp qw(carp);

# A simple Test system in the spirit of Sq. Just minimal functions
# that work, and do the stuff. Maybe it will just provide
# the functions. is, ok, nok, like, dies.

# In a data-centered approach all you really need is just comparing
# data for testing.

# Actually Testing is always just about comparing data!

BEGIN {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon  += 1;
    my $srand = sprintf("%4d%2d%2d", $year,$mon,$mday);
    srand($srand);
    printf "# Seeded srand with seed '%s' from local date.\n", $srand;
}

my $count = 0;

sub ok($bool, $message) {
    $count++;
    if ( $bool ) {
        print "ok $count - $message\n"
    }
    else {
        print "not ok $count - $message\n";
    }
    return;
}

sub nok($bool, $message) {
    $count++;
    if ( $bool ) {
        print "not ok $count - $message\n";
    }
    else {
        print "ok $count - $message\n"
    }
    return;
}

sub is($got, $expected, $message) {
    $count++;
    if ( equal($got, $expected) ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
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

sub dies :prototype(&) {
    my ($fn) = @_;
    local $@;
    eval { $fn->() };
    return $@ eq "" ? undef : $@;
}

sub like($str, $regex, $message) {
    $count++;
    if ( $str =~ $regex ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
        $str =~ s/^/# /mg;
        $str =~ s/\A# //;
        print "Got: $str\n", "Expected: $regex\n";
    }
    return;
}

sub check_isa($any, $class, $message) {
    $count++;
    my $type = ref $any;
    if ( $type eq $class ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
        $class =~ s/\s+//g;
        print "# Got: $type Expected: $class\n";
    }
}

1;