package Sq::Test;
use 5.036;
use builtin 'blessed';
use Sq;
use Sq::Exporter;
our @EXPORT = qw/is ok nok check one_of done_testing dies like check_isa/;

BEGIN {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon  += 1;
    my $srand = sprintf("%04d%02d%02d", $year,$mon,$mday);
    srand($srand);
    printf "# Seeded srand with seed '%s' from local date.\n", $srand;
}

# Global (package) variable that keeps track of the current amount of tests so far
my $count = 0;

# Helper function that takes any variable and makes a string out of it, and add
# comment tags "#" in front of every line, so it can be used in the warning
# in the TAP (Test Anything Protocol)
sub quote($any) {
    my $dump = dumps($any);
    # add # to beginning of every starting line
    $dump =~ s/^/+ /mg;
    # but remove leading "#" on starting string
    $dump =~ s/\A#\s*//;
    return $dump;
}

# Expects a valid value. A valid value is every number not "0", a not
# empty string. And every Some($value) value and every Ok($value).
sub ok($bool, $message) {
    $count++;
    if ( is_num $bool ) {
        Carp::croak "ok() only expects 0 or 1 as numbers. Got: $bool" if ($bool != 0 && $bool != 1);
        if ( $bool ) {
            print "ok $count - $message\n"
        }
        else {
            print "not ok $count - $message\n";
            warn  "# Expected 1, Some() or Ok()\n";
            warn  "# not ok $count - $message\n";
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
                warn  "# Expected 1, Some() or Ok()\n";
                warn  "# not ok $count - $message\n";
            }
            return;
        }
        elsif ( $type eq 'Result' ) {
            if ( $bool->[0] == 1 ) {
                print "ok $count - $message\n"
            }
            else {
                print "not ok $count - $message\n";
                warn  "# Expected 1, Some() or Ok()\n";
                warn  "# not ok $count - $message\n";
                my $msg = dumps($bool->[1]);
                $msg =~ s/^/# /mg;
                warn $msg, "\n";
            }
            return;
        }

        Carp::croak "ok() Got: Empty string" if $type eq "" && $bool eq "";
        Carp::croak "ok() Got: $bool" if $type eq "";
        Carp::croak "ok() Got ref: $type";
    }
    return;
}

# Expects a "not okay" value. In Sq this means 0 or the "None" or "Err" values
# from the Option/Result are considered as valid values.
sub nok($bool, $message) {
    $count++;
    if ( !defined $bool ) {
        Carp::croak "nok() expects 0 or 1. Got undef";
    }
    elsif ( is_num($bool) ) {
        Carp::croak "nok() only expects 0 or 1 as numbers Got: $bool" if ($bool != 0 && $bool != 1);
        if ( $bool == 0 ) {
            print "ok $count - $message\n";
            return;
        }
        goto ERROR;
    }
    else {
        my $type = ref $bool;
        if ( $type eq 'Option' ) {
            if ( @$bool == 0 ) {
                print "ok $count - $message\n";
                return;
            }
            goto ERROR;
        }
        elsif ( $type eq 'Result' ) {
            if ( $bool->[0] == 0 ) {
                print "ok $count - $message\n";
                return;
            }
            goto ERROR;
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

        Carp::croak "nok() Got: $bool" if ref eq "";
        Carp::croak "nok() Got ref: $type";
    }

    # C-style error handling without exception crap.
    # You know that throwing an exception and catch that, it would
    # logical the same as an goto? But the exceptions is maybe around
    # 100 times slower?
    ERROR:
    my ( $pkg, $file, $line ) = caller;
    my $place = sprintf "at %s: %d\n", $file, $line;
    warn  "# Expected 0, None() or Err()\n";
    warn  "# not ok $count - $message\n";
    return;
}

sub check :prototype($$$) {
    my ($got, $f_expected, $message) = @_;
    $count++;
    if ( $f_expected->($got) ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
        # warning
        my $dump = quote($got);
        my ( $pkg, $file, $line ) = caller;
        my $place = sprintf "at %s: %d", $file, $line;
        warn "\n",
             "# Got: $dump\n",
             "# not ok $count - $message $place\n";
    }
}

sub is :prototype($$$) {
    my ($got, $expected, $message) = @_;
    $count++;
    if ( equal($got, $expected) ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
        my $dump_1 = quote($got);
        my $dump_2 = quote($expected);
        # warning
        my ( $pkg, $file, $line ) = caller;
        my $place = sprintf "at %s: %d", $file, $line;
        warn "\n",
             "# Got:      $dump_1\n",
             "# Expected: $dump_2\n",
             "# not ok $count - $message $place\n";
    }
    return;
}

sub one_of :prototype($$$) {
    my ($got, $expects, $message) = @_;
    $count++;

    if ( Array::contains($expects, $got) ) {
        print "ok $count - $message\n";
    }
    else {
        print "not ok $count - $message\n";
        my $dump_g = quote($got);
        my $dump_e = quote($expects);
        # warning
        my ( $pkg, $file, $line ) = caller;
        my $place = sprintf "at %s: %d", $file, $line;
        warn "\n",
             "# Got:    ", $dump_g, "\n",
             "# One Of: ", $dump_e, "\n",
             "# not ok $count - $message $place\n";
    }
}

sub done_testing() {
    print "1..$count\n";
}

sub dies :prototype(&$$) {
    my ($fn, $regex, $message) = @_;
    $count++;
    local $@;
    eval { $fn->() };
    # when exception thrown
    if ( $@ ) {
        # when error is what was expected
        if ( $@ =~ $regex ) {
            print "ok $count - $message\n";
            return;
        }
        # when exception, but error is not what we expected
        else {
            print "not ok $count - $message\n";
            my ( $pkg, $file, $line ) = caller;
            my $place = sprintf "at %s: %d", $file, $line;
            my $got   = quote($@);
            warn "\n",
                "# Got:      $got\n",
                "# Expected: $regex\n",
                "# not ok $count - $message $place\n";
            return;
        }
    }
    # when no exception at all
    else {
        print "not ok $count - $message\n";
        my ( $pkg, $file, $line ) = caller;
        my $place = sprintf "at %s: %d", $file, $line;
        warn "\n",
             "# Expected exception but code didn't throw!\n",
             "# not ok $count - $message $place\n";
        return;
    }
}

sub like($str, $regex, $message) {
    $count++;
    if ( !defined $str ) {
        print "not ok $count - $message\n";
        my ( $pkg, $file, $line ) = caller;
        my $place = sprintf "at %s: %d", $file, $line;
        warn "\n",
             "# Got:      undef\n",
             "# Expected: $regex\n",
             "# not ok $count - $message $place\n";
    }
    elsif ( $str =~ $regex ) {
        print "ok $count - $message\n";
    }
    else {
        my ( $pkg, $file, $line ) = caller;
        my $place = sprintf "at %s: %d", $file, $line;
        print "not ok $count - $message $place\n";
        $str =~ s/^/# /mg;
        $str =~ s/\A# //;
        warn "\n",
             "# Got:      $str\n",
             "# Expected: $regex\n",
             "# not ok $count - $message $place\n";
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
            warn "# Got two objects, but classes didn't match\n",
                 "# Got:      $type\n",
                 "# Expected: $class\n",
                 "# not ok $count - $message\n";
        }
        else {
            my ( $pkg, $file, $line ) = caller;
            my $place = sprintf "at %s: %d", $file, $line;
            warn "# Expected two objects, but got unblessed value\n",
                 "# Got:      unblessed\n",
                 "# Expected: $class\n",
                 "# not ok $count - $message $place\n",
        }
    }
}

1;