#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

like(
    dies {
        Some(10)->match(
            some => sub($x) { $x + 1 },
            none => sub()   { 0      },
        );
    },
    qr/\AOption::match/,
    'Option::match 1');

like(
    dies {
        Some(10)->match(
            Some => sub($x) { $x + 1 },
            none => sub()   { 0      },
        );
    },
    qr/\AOption::match/,
    'Option::match 2');

like(
    dies {
        Some(10)->match(
            some => sub($x) { $x + 1 },
            None => sub()   { 0      },
        );
    },
    qr/\AOption::match/,
    'Option::match 3');

like(
    dies {
        Some(10)->match(
            Some => "",
            None => sub()   { 0      },
        );
    },
    qr/\AOption::match/,
    'Option::match 4');

like(
    dies {
        Some(10)->match(
            Some => sub($x) { $x + 1 },
            None => "",
        );
    },
    qr/\AOption::match/,
    'Option::match 5');

done_testing;
