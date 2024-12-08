#!perl
use 5.036;
use Sq;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $id      = sub($x) { $x          };
my $add1    = sub($x) { $x + 1      };
my $double  = sub($x) { $x * 2      };
my $square  = sub($x) { $x * $x     };
my $is_even = sub($x) { $x % 2 == 0 };

my $fst     = sub($array) { $array->[0] };
my $snd     = sub($array) { $array->[1] };


#----------


# min
is($range->min,                   Some(1), 'min');
is(Seq->range(-100, -50)->min, Some(-100), 'min with negative values');
is(Seq->empty->min,                  None, 'min on empty');
is(Seq->empty->min->or(0),              0, 'min on empty with default');

# max
is($range->max,                   Some(10), 'max');
is($range->max->or(100),                10, 'max with option::or');
is(Seq->range(-100, -50)->max,   Some(-50), 'max with negative values');
is(Seq->empty->max,                   None, 'max on empty');
is(Seq->empty->max->or(0),               0, 'max on empty with option::or');

my $words = Seq->wrap(qw/Hello World you Are welcome/);

# min_str
is($words->min_str,              Some('Are'), 'min_str');
is($words->min_str->or('dope'),       'Are' , 'min_str with option::or');
is(Seq->empty->min_str,                 None, 'min_str on empty');
is(Seq->empty->min_str->or('Z'),         'Z', 'min_str on empty with option::ot');

# max_str
is($words->max_str,             Some('you'), 'max_str');
is($words->max_str->or('foo'),        'you', 'max_str with option::ot');
is(Seq->empty->max_str,                None, 'max_str on empty');
is(Seq->empty->max_str->or('A'),        'A', 'max_str on empty with option::or');


# --- ---


my $data = Seq->wrap(
    { id => 1, name => 'A' },
    { id => 2, name => 'B' },
    { id => 3, name => 'C' },
);

my $by_id   = key "id";
my $by_name = key "name";

# min_by
is($data->min_by(key "id"),        Some({id => 1, name => 'A'}), 'min_by');
is($data->min_by(key "id")->or(1),      {id => 1, name => 'A'} , 'min_by with default');
is(Seq->empty->min_by(key "id"),                           None, 'min_by on empty');
is(Seq->empty->min_by(key "id")->or(0),                       0, 'min_by on empty with default');

# min_by_str
is($data->min_str_by($by_name),       Some({ id => 1, name => 'A' }), 'min_by_str');
is($data->min_str_by($by_name)->or(0),     { id => 1, name => 'A' } , 'min_by_str with option::or');
is(Seq->empty->min_str_by($by_name),                            None, 'min_by_str on empty');
is(Seq->empty->min_str_by($by_name)->or(0),                        0, 'min_by_str on empty with option::or');

# max_by
is($data->max_by($by_id),      Some({ id => 3, name => 'C' }), 'max_by');
is($data->max_by($by_id)->or(0),    { id => 3, name => 'C' } , 'max_by with default');
is(Seq->empty->max_by($by_id),                           None, 'max_by on empty');
is(Seq->empty->max_by($by_id)->or(0),                       0, 'max_by on empty with default');

# max_by_str
is($data->max_str_by($by_name),       Some({ id => 3, name => 'C' }), 'max_by_str');
is($data->max_str_by($by_name)->or(0),     { id => 3, name => 'C' } , 'max_by_str with option::or');
is(Seq->empty->max_str_by($by_name),                            None, 'max_by_str on empty');
is(Seq->empty->max_str_by($by_name)->or(0),                        0, 'max_by_str on empty with option::or');

done_testing;