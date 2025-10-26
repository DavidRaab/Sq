#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

dies {
    Some(10)->match(
        some => sub($x) { $x + 1 },
        none => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 1';


dies {
    Some(10)->match(
        Some => sub($x) { $x + 1 },
        none => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 2';


dies {
    Some(10)->match(
        some => sub($x) { $x + 1 },
        None => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 3';


dies {
    Some(10)->match(
        Some => "",
        None => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 4';


dies {
    Some(10)->match(
        Some => sub($x) { $x + 1 },
        None => "",
    );
}
qr/\AOption::match/,
'Option::match 5';

done_testing;
