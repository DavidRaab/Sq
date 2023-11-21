#!perl
use 5.036;
use Seq qw(key);
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash array item end bag float U/;
#use DDP;

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
is($range->min,                   1, 'min');
is(Seq->range(-100, -50)->min, -100, 'min with negative values');
is(Seq->empty->min,             U(), 'min on empty');
is(Seq->empty->min(0),            0, 'min on empty with default');

# max
is($range->max,                  10, 'max');
is($range->max(100),             10, 'max with default');
is(Seq->range(-100, -50)->max,  -50, 'max with negative values');
is(Seq->empty->max,             U(), 'max on empty');
is(Seq->empty->max(0),            0, 'max on empty with default');

my $words = Seq->wrap(qw/Hello World you Are welcome/);

# min_str
is($words->min_str,        'Are', 'min_str');
is($words->min_str('AAA'), 'Are', 'min_str with default');
is(Seq->empty->min_str,      U(), 'min_str on empty');
is(Seq->empty->min_str('Z'), 'Z', 'min_str on empty with default');

# max_str
is($words->max_str,        'you', 'max_str');
is($words->max_str('foo'), 'you', 'max_str with default');
is(Seq->empty->max_str,      U(), 'max_str on empty');
is(Seq->empty->max_str('A'), 'A', 'max_str on empty with default');


# --- ---


my $data = Seq->wrap(
    { id => 1, name => 'A' },
    { id => 2, name => 'B' },
    { id => 3, name => 'C' },
);

my $by_id   = key "id";
my $by_name = key "name";

# min_by
is($data->min_by(key "id"),           1, 'min_by');
is($data->min_by(key "id", 0),        1, 'min_by with default');
is(Seq->empty->min_by(key "id"),    U(), 'min_by on empty');
is(Seq->empty->min_by(key "id", 0),   0, 'min_by on empty with default');

# min_by_str
is($data->min_by_str($by_name),           'A', 'min_by_str');
is($data->min_by_str($by_name, '0'),      'A', 'min_by_str with default');
is(Seq->empty->min_by_str($by_name),      U(), 'min_by_str on empty');
is(Seq->empty->min_by_str($by_name, '0'),   0, 'min_by_str on empty with default');

# max_by
is($data->max_by($by_id),           3, 'max_by');
is($data->max_by($by_id, 0),        3, 'max_by with default');
is(Seq->empty->max_by($by_id),    U(), 'max_by on empty');
is(Seq->empty->max_by($by_id, 0),   0, 'max_by on empty with default');

# max_by_str
is($data->max_by_str($by_name),           'C', 'max_by_str');
is($data->max_by_str($by_name, '0'),      'C', 'max_by_str with default');
is(Seq->empty->max_by_str($by_name),      U(), 'max_by_str on empty');
is(Seq->empty->max_by_str($by_name, '0'),   0, 'max_by_str on empty with default');

done_testing;