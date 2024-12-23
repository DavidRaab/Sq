#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

# Testing some function that expects the lambdas to return optional values.
# Those functions are written in a way that it also should work with returning
# normal values/undef

# unfold
{
    my $nums_def = Seq->unfold(0, sub($x) {
        if ( $x < 20 ) {
            return $x, $x+1;
        }
        return undef;
    });
    is($nums_def, seq{0..19}, 'unfold with list');


    my $nums_opt = Seq->unfold(0, sub($x) {
        if ( $x < 20 ) {
            return Some($x, $x+1);
        }
        return None;
    });
    is($nums_opt, seq{0..19}, 'unfold with option');


    my $nums_list = Seq->unfold(0, sub($x) {
        if ( $x < 20 ) {
            return $x, $x+1;
        }
        return;
    });
    is($nums_opt, seq{0..19}, 'unfold with just return');
}

# choose
{
    my $range  = Seq->range(10,20);
    my $result = seq { 20,24,28,32,36,40 };

    my $evens_opt = $range->choose(sub($x) { $x % 2 == 0 ? Some($x*2) : None  });
    is($evens_opt, $result, 'choose with option');

    my $evens_def = $range->choose(sub($x) { $x % 2 == 0 ? $x*2       : undef });
    is($evens_def, $result, 'choose with defined');

    my $evens_lst = $range->choose(sub($x) { $x % 2 == 0 ? $x*2       : ()    });
    is($evens_lst, $result, 'choose with list');
}

# pick
{
    my $range = Seq->range(10,20);

    # tests that returns Some
    is(
        $range->pick(sub($x) { $x > 15 ? Some($x*$x) : None }),
        Some(256),
        'pick with opt');

    is(
        $range->pick(sub($x) { $x > 15 ? $x*$x : undef }),
        Some(256),
        'pick with undef');

    is(
        $range->pick(sub($x) { $x > 15 ? $x*$x : () }),
        Some(256),
        'pick with list');

    # tests that returns None
    is(
        $range->pick(sub($x) { $x > 20 ? Some($x*$x) : None }),
        None,
        'pick with opt');

    is(
        $range->pick(sub($x) { $x > 20 ? $x*$x : undef }),
        None,
        'pick with undef');

    is(
        $range->pick(sub($x) { $x > 20 ? $x*$x : () }),
        None,
        'pick with list');
}

done_testing;