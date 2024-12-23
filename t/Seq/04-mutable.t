#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

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

# Stuff that is possible because arrayref are mutable
{
    my @data = (1,2,3,4,5);
    my $data = Seq->from_array(\@data);

    is($data->length, 5, 'length is 5');
    is($data->to_array, [1..5], '$data as array');

    # change @data
    push @data, 6;
    is($data->length, 6, 'length is 6');
    is($data->to_array, [1..6], '$data is now 6');
}

# Same mutable tests with a hashref
{
    my %data = (
        1 => "Foo",
        2 => "Bar",
        3 => "Baz",
    );

    my $data = Seq->from_hash(\%data, sub($key, $value) {
        return $key . $value;
    });

    is($data->length, 3, 'length from hashref is 3');
    is(
        $data->to_array->sort_str,
        ["1Foo", "2Bar", "3Baz"],
        'hash to sequence');

    # add entry to data
    $data{4} = 'Maz';

    is($data->length, 4, 'length from hashref is 4');
    is(
        $data->to_array->sort_str,
        ["1Foo", "2Bar", "3Baz", "4Maz"],
        'hash to sequence after added key');
}

# difference of wrap and from_array
{
    my @data = (1..10);

    # makes a copy at that time
    my $data1 = Seq->wrap(@data);
    # just refers to the array
    my $data2 = Seq->from_array(\@data);

    is($data1->length, 10, '$data1 has 10 items');
    is($data2->length, 10, '$data2 has 10 items');

    # we now add an element to the array
    push @data, 11;

    is($data1->length, 10, '$data1 still has 10 items');
    is($data2->length, 11, '$data2 now has 11 items');
}

done_testing;