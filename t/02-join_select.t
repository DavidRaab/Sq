#!perl
use 5.036;
use List::Util qw(reduce);
use Seq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use DDP;

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

# Some data tables
my $objects = Seq->wrap(
    {id => 1, name => 'David'},
    {id => 2, name => 'Bob'  },
    {id => 3, name => 'Alex' },
);

my $tags = Seq->wrap(
    {id => 1, name => 'WoW'     },
    {id => 2, name => 'Super'   },
    {id => 3, name => 'Awesome' },
);

my $objects_to_tags = Seq->wrap(
    {id => 1, object_id => 1, tag_id => 1},
    {id => 2, object_id => 1, tag_id => 2},
    {id => 3, object_id => 2, tag_id => 3},
    {is => 4, object_id => 3, tag_id => 2},
);

# A query to join the data together
my $query =
    $objects
    ->join($objects_to_tags, sub($obj, $tag) {$obj->{id} == $tag->{object_id} })
    ->select({id => 'object_id', name => 'object_name'}, [qw/tag_id/])
    ->join($tags, sub($left, $tag) { $left->{tag_id} == $tag->{id} })
    ->select(ALL => {name => 'tag_name'});

# check if query contains correct data
is(
    $query->to_array,
    array {
        item hash {
            field object_id   => 1;
            field object_name => "David";
            field tag_id      => 1;
            field tag_name    => "WoW";
            end;
        };
        item hash {
            field object_id   => 1;
            field object_name => "David";
            field tag_id      => 2;
            field tag_name    => "Super";
            end;
        };
        item hash {
            field object_id   => 2;
            field object_name => "Bob";
            field tag_id      => 3;
            field tag_name    => "Awesome";
            end;
        };
        item hash {
            field object_id   => 3;
            field object_name => 'Alex';
            field tag_id      => 2;
            field tag_name    => 'Super';
            end;
        };
        end;
    },
    'join and select');

# reuse query again and get tags of specific perons
is(
    $query
    ->filter(sub($obj) { $obj->{object_name} eq 'David' })
    ->map(   sub($obj) { $obj->{tag_name} })
    ->to_array,

    [qw/WoW Super/],
    'davids tags');

is(
    $query
    ->filter(sub($obj) { $obj->{object_name} eq 'Bob' })
    ->map(   sub($obj) { $obj->{tag_name} })
    ->to_array,

    [qw/Awesome/],
    'Bobs Tags');

is(
    $query
    ->filter(sub($obj) { $obj->{object_name} eq 'Alex' })
    ->map(   sub($obj) { $obj->{tag_name} })
    ->to_array,

    [qw/Super/],
    'Bobs Tags');

done_testing;