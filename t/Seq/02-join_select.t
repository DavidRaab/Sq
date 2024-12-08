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

#--- ---

my $cards =
    Seq::cartesian(
        Seq->wrap(qw/clubs spades hearts diamond/),
        Seq->wrap(qw/7 8 9 10 B D K A/),
    );

# check cartesian first -- is used by join/select
is(
    $cards->to_array,
    [
        (map { [clubs   => $_ ] } qw/7 8 9 10 B D K A/),
        (map { [spades  => $_ ] } qw/7 8 9 10 B D K A/),
        (map { [hearts  => $_ ] } qw/7 8 9 10 B D K A/),
        (map { [diamond => $_ ] } qw/7 8 9 10 B D K A/),
    ],
    'cartesian 1');

# testing full output
is(
    $cards->to_array,
    [
        ['clubs'  ,'7'],['clubs'  ,'8'],['clubs'  ,'9'],['clubs'  ,'10'],
        ['clubs'  ,'B'],['clubs'  ,'D'],['clubs'  ,'K'],['clubs'  ,'A' ],
        ['spades' ,'7'],['spades' ,'8'],['spades' ,'9'],['spades' ,'10'],
        ['spades' ,'B'],['spades' ,'D'],['spades' ,'K'],['spades' ,'A' ],
        ['hearts' ,'7'],['hearts' ,'8'],['hearts' ,'9'],['hearts' ,'10'],
        ['hearts' ,'B'],['hearts' ,'D'],['hearts' ,'K'],['hearts' ,'A' ],
        ['diamond','7'],['diamond','8'],['diamond','9'],['diamond','10'],
        ['diamond','B'],['diamond','D'],['diamond','K'],['diamond','A' ],
    ],
    'cartesian 2');

# testing against non-lazy variant
sub cartesian($arrayA, $arrayB) {
    my @output;
    for my $a ( @$arrayA ) {
        for my $b ( @$arrayB ) {
            push @output, [$a, $b];
        }
    }
    return \@output;
}

is(
    $cards->to_array,
    cartesian(
        [qw/clubs spades hearts diamond/],
        [qw/7 8 9 10 B D K A/],
    ),
    'cartesian non-lazy');

#--- ---


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
    ->left_join($objects_to_tags, sub($obj, $tag) {$obj->{id} == $tag->{object_id} })
    ->select({id => 'object_id', name => 'object_name'}, [qw/tag_id/])
    ->left_join($tags, sub($left, $tag) { $left->{tag_id} == $tag->{id} })
    ->select(ALL => {name => 'tag_name'});

# check if query contains correct data
is(
    $query->to_array,
    [
        {
            object_id   => 1,
            object_name => "David",
            tag_id      => 1,
            tag_name    => "WoW",
        },
        {
            object_id   => 1,
            object_name => "David",
            tag_id      => 2,
            tag_name    => "Super",
        },
        {
            object_id   => 2,
            object_name => "Bob",
            tag_id      => 3,
            tag_name    => "Awesome",
        },
        {
            object_id   => 3,
            object_name => 'Alex',
            tag_id      => 2,
            tag_name    => 'Super',
        },
    ],
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


# filter->map can be replaced with choose
is(
    $query
    ->choose(sub($obj) { $obj->{object_name} eq 'David' ? Some $obj->{tag_name} : None })
    ->to_array,

    [qw/WoW Super/],
    'davids tags');

done_testing;