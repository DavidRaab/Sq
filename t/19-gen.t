#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;
use Sq::Type qw(t_run);
use Sq::Gen;
use Sq::Parser qw(p_run);

{
    # Example: ["12","06","1450"]
    my $dmy = gen_and(
        gen_format("%02d", gen_int(1,28)),
        gen_format("%02d", gen_int(1,12)),
        gen_format("%04d", gen_int(0,3000)),
    );

    # Array with hundreds of 3 elements arrays
    my $dmy_100 = gen_repeat(100, $dmy);

    # the Type what $hundreds should be
    my $dates = type
        [array =>
            [length => 100,100],
            [of =>
                [tuple =>
                    [int => [range => 1,28]],
                    [int => [range => 1,12]],
                    [int => [range => 0,3000]]]]];

    # Consider that this is a declarative definition. Actualy very LISP-style.
    # I just describe what the data should be. The t_run() later executes that
    # type definition and checks if $dates is of that type. Without such a type
    # definition we had to manually write the for-loop and if checks
    # for the inner array and it's indexes. It's possible to write, it
    # also will be faster with for-loop, but writing "complex" logic becomes a pain
    # really fast. Also the t_run() immediately aborts if something isn't right.
    # I like reading/writing the definition above a lot more than writing the low-level
    # code.
    ok(t_run($dates, gen_run($dmy_100)), '100 dates');

    # Technically those are a hundreds tests in one single test combined.
    # I also could loop over the $dmy_100 and then do a type test for every
    # single inner element. Then i just test if the inner array is a tuple of
    # three ints in the range.
    #
    # The whole thing shows how to generated random data, and how to test random data.
    #
    # This kind of testing is named "Property Based Testing". Still this is far from
    # being complete in Sq. In a proper test system the testing system shrinks
    # and tries to generate a minimal test when a random test fails. See Property
    # based testing in Haskell or F# and watch some Youtube videos about it.

    # Here are another 100 tests that test the Parser
    my $str_dates = gen_repeat(100, gen_join('.', $dmy));
    gen_run($str_dates)->iter(sub($date) {
        ok(p_run(Sq->p->date_dmy, $date), "is '$date' valid");
    });
}

done_testing;
