#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;

if ( not $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

require DDP;
DDP->import('p', 'np');

# Some values, functions, ... for testing
my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

# optionals
{
    my $ten = Some(10);
    is(np($ten), 'Some(10)', 'stringify some');

    my $none = None;
    is(np($none), 'None', 'stringify none');

    my $array = Some([]);
    is(np($array), 'Some([])', 'stringify array');

    my $hash = Some({});
    is(np($hash), 'Some({})', 'stringify hash');
}

# my $movie = {
#     title  => Some('Terminator 2'),
#     rating => Some(5),
#     desc   => None,
# };

# p($movie);

done_testing;
