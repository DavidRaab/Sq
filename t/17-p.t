#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;
use Sq::Parser qw(p_run);
use Sq::Gen;

# date_ymd
{
    my $date = Sq->p->date_ymd;

    is(p_run($date, "2025-03-13"), Some([2025,3,13]),
        'date_ymd 1');
    # it has a limited check for valid date. checks if month is 1-12 and day is 1-31
    is(p_run($date, "9999-99-99"), None,
        'date_ymd 3');
    is(p_run($date, "2000-02-31"), Some([2000,2,31]),
        'date_ymd feb 31 still valid');
    is(p_run($date, "2000-02-32"), None,
        'date_ymd feb 32 not valid');
    is(p_run($date, "2010-2-1"),   None,
        'date_ymd format must be exact with leading zero');
    is(p_run($date, "2000-00-01"), None,
        'date_ymd 00 for month is invalid');
    is(p_run($date, "2000-01-00"), None,
        'date_ymd 00 for day is invalid');
}

# date_dmy
{
    my $date = Sq->p->date_dmy;

    is(p_run($date, "13.03.2025"), Some([13,3,2025]),
        'date_dmy 1');
    # it has a limited check for valid date. checks if month is 1-12 and day is 1-31
    is(p_run($date, "99.99.9999"), None,
        'date_dmy 3');
    is(p_run($date, "31.02.2000"), Some([31,2,2000]),
        'date_dmy feb 31 still valid');
    is(p_run($date, "32.02.2000"), None,
        'date_dmy feb 32 not valid');
    is(p_run($date, "1.2.2010"),   None,
        'date_dmy format must be exact with leading zero');
    is(p_run($date, "01.00.2000"), None,
        'date_dmy 00 for month is invalid');
    is(p_run($date, "00.01.2000"), None,
        'date_dmy 00 for day is invalid');
}

# Random dates testing
{
    my $date =
        gen_and(
            gen_format("%02d", gen_int(1,28)),
            gen_format("%02d", gen_int(1,12)),
            gen_format("%04d", gen_int(0,3000)),
        );

    my $dates_dot   = gen_repeat(100, gen_join('.', $date));
    my $dates_slash = gen_repeat(100, gen_join('-', $date));

    gen_run($dates_dot)->iter(sub($date) {
        ok(p_run(Sq->p->date_dmy, $date), "is '$date' valid");
    });

    gen_run($dates_slash)->iter(sub($date) {
        ok(p_run(Sq->p->date_dmy('-'), $date), "is '$date' valid");
    });
}

done_testing;
