#!perl
use 5.036;
use Sq;
use Sq::Parser;
use Test2::V0 qw(is ok done_testing);

{
    my $num = assign {
        my $to_num = sub($num,$suffix) {
            return $num                      if $suffix eq 'b';
            return $num * 1024               if $suffix eq 'kb';
            return $num * 1024 * 1024        if $suffix eq 'mb';
            return $num * 1024 * 1024 * 1024 if $suffix eq 'gb';
        };

        p_many(
            p_maybe(p_match(qr/\s* , \s*/x)), # optional ,
            p_map(
                $to_num,
                p_many (p_strc(0 .. 9)), # digits
                p_match(qr/\s*/),        # whitespace
                p_strc (qw/b kb mb gb/), # suffix
            )
        );
    };

    is(p_run($num, "1  b, 1kb"),         Some([1, 1024]), '1 b & 1kb');
    is(p_run($num, "1 kb, 1gb"), Some([1024,1073741824]), '1 kb & 1gb');
    is(p_run($num, "1 mb"),              Some([1048576]), '1 mb');
    is(p_run($num, "1 gb"),           Some([1073741824]), '1 gb');
}

{
    my $num = assign {
        my $to_num = sub($num,$suffix) {
            return $num                      if $suffix eq 'b';
            return $num * 1024               if $suffix eq 'kb';
            return $num * 1024 * 1024        if $suffix eq 'mb';
            return $num * 1024 * 1024 * 1024 if $suffix eq 'gb';
        };

        p_many(
            p_matchf(qr/\s* (?: , )? \s* (\d+) \s* (b|kb|mb|gb)/xi, $to_num),
        );
    };

    is(p_run($num, "1  b, 1kb"),         Some([1, 1024]), '1 b & 1kb');
    is(p_run($num, "1 kb, 1gb"), Some([1024,1073741824]), '1 kb & 1gb');
    is(p_run($num, "1 mb"),              Some([1048576]), '1 mb');
    is(p_run($num, "1 gb"),           Some([1073741824]), '1 gb');
}


done_testing;