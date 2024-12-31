package Sq::Test;
use 5.036;
use builtin 'blessed';
use Sq;
use Sq::Exporter;
our @EXPORT = qw/is ok nok done_testing dies like check_isa/;

BEGIN {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon  += 1;
    my $srand = sprintf("%04d%02d%02d", $year,$mon,$mday);
    srand($srand);
    printf "# Seeded srand with seed '%s' from local date.\n", $srand;
}

my $count = 0;

sub ok($bool, $message) {
    $count++;
    if ( is_num $bool ) {
        Carp::croak "Error: ok() only expects 0 or 1 as numbers. Got: $bool\n" if ($bool != 0 && $bool != 1);
        if ( $bool ) {
            print "ok $count - $message\n"
        }
        else {
            print "not ok $count - $message\n";
            warn  "# not ok $count - $message\n";
            warn  "# Expected 1, Some() or Ok()\n";
        }
        return;
    }
    else {
        my $type = ref $bool;
        if ( $type eq 'Option' ) {
            if ( @$bool ) {
                print "ok $count - $message\n"
            }
            else {
                print "not ok $count - $message\n";
                warn  "# not ok $count - $message\n";
                warn  "# Expected 1, Some() or Ok()\n";
            }
            return;
        }
        elsif ( $type eq 'Result' ) {
            if ( $bool->[0] == 1 ) {
                print "ok $count - $message\n"
            }
            else {
                print "not ok $count - $message\n";
                warn  "# not ok $count - $message\n";
                warn  "# Expected 1, Some() or Ok()\n";
                my $msg = dump($bool->[1]);
                $msg =~ s/^/# /mg;
                warn $msg, "\n";
            }
            return;
        }

        Carp::croak "Error: ok() got: $bool\n" if $type eq "";
        Carp::croak "Error: ok() got ref: $type\n";
    }
    return;
}

sub nok($bool, $message) {
    $count++;
    if ( is_num($bool) ) {
        Carp::croak "Error: ok() only expects 0 or 1 as numbers Got: $bool\n" if ($bool != 0 && $bool != 1);
        if ( $bool == 0 ) {
            print "ok $count - $message\n"
        }
        else {
            print "not ok $count - $message\n";
            warn  "# not ok $count - $message\n";
            warn  "# Expected 0, None or Err()\n";
        }
        return;
    }
    else {
        my $type = ref $bool;
        if ( $type eq 'Option' ) {
            if ( @$bool ) {
                print "not ok $count - $message\n";
                warn  "# not ok $count - $message\n";
                warn  "# Expected 0, None or Err()\n";
            }
            else {
                print "ok $count - $message\n"
            }
            return;
        }
        elsif ( $type eq 'Result' ) {
            if ( $bool->[0] == 1 ) {
                print "not ok $count - $message\n";
                warn  "# not ok $count - $message\n";
                warn  "# Expected 0, None or Err()\n";
            }
            else {
                print "ok $count - $message\n"
            }
            return;
        }
        # only for is_num(). This function is looks_like_number() but when
        # number is not a number it returns empty string. So empty string
        # is also considered a failurre or in the case of nok() as valid.
        # Important, so someone can write:
        #
        # nok(is_num($whatever), "not a number");
        elsif ( $type eq "" && $bool eq "" ) {
            print "ok $count - $message\n";
            return;
        }

        Carp::croak "Error: nok got: $bool\n" if ref eq "";
        Carp::croak "Error: nok() got ref: $type\n";
    }
    return;
}

sub is :prototype($$$) {
    my ($got, $expected, $message) = @_;
    $count++;
    if ( equal($got, $expected) ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
        my $dump_1 = dump($got);
        my $dump_2 = dump($expected);
        # add # to beginning of every starting line
        $dump_1 =~ s/^/# /mg;
        $dump_2 =~ s/^/# /mg;
        # but remove leading "#" on starting string
        $dump_1 =~ s/\A#\s*//;
        $dump_2 =~ s/\A#\s*//;
        warn "# not ok $count - $message\n",
             "# Got:      ", $dump_1, "\n",
             "# Expected: ", $dump_2, "\n";
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
        warn "# not ok $count - $message\n",
             "# Got:      $str\n",
             "# Expected: $regex\n";
    }
    return;
}

sub check_isa($any, $class, $message) {
    Carp::croak "Not a valid class name" if $class =~ m/\s/;
    $count++;
    if ( $any isa $class ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
        my $type = blessed $any;
        if ( defined $type ) {
            warn "# not ok $count - $message\n",
                 "# Got:      $type\n",
                 "# Expected: $class\n";
        }
        else {
            warn "# not ok $count - $message\n",
                 "# Expected an object of $class, got unblessed value\n";
        }
    }
}

1;