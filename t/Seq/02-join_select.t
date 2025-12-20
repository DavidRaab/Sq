#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

ok(1, 'No Tests');

# Some data tables
my $objects = seq(
    {id => 1, name => 'David'},
    {id => 2, name => 'Bob'  },
    {id => 3, name => 'Alex' },
);

my $tags = seq(
    {id => 1, name => 'WoW'     },
    {id => 2, name => 'Super'   },
    {id => 3, name => 'Awesome' },
);

my $objects_to_tags = seq(
    {id => 1, object_id => 1, tag_id => 1},
    {id => 2, object_id => 1, tag_id => 2},
    {id => 3, object_id => 2, tag_id => 3},
    {is => 4, object_id => 3, tag_id => 2},
);

# A query to join the data together
# my $query =
#     $objects
#     ->left_join($objects_to_tags, sub($obj, $tag) {$obj->{id} == $tag->{object_id} })
#     ->select({id => 'object_id', name => 'object_name'}, [qw/tag_id/])
#     ->left_join($tags, sub($left, $tag) { $left->{tag_id} == $tag->{id} })
#     ->select(ALL => {name => 'tag_name'});

# check if query contains correct data
# is(
#     $query,
#     seq {
#         {
#             object_id   => 1,
#             object_name => "David",
#             tag_id      => 1,
#             tag_name    => "WoW",
#         },
#         {
#             object_id   => 1,
#             object_name => "David",
#             tag_id      => 2,
#             tag_name    => "Super",
#         },
#         {
#             object_id   => 2,
#             object_name => "Bob",
#             tag_id      => 3,
#             tag_name    => "Awesome",
#         },
#         {
#             object_id   => 3,
#             object_name => 'Alex',
#             tag_id      => 2,
#             tag_name    => 'Super',
#         },
#     },
#     'join and select');

# reuse query again and get tags of specific perons
# is(
#     $query
#     ->filter(sub($obj) { $obj->{object_name} eq 'David' })
#     ->map(   sub($obj) { $obj->{tag_name} })
#     ->to_array,

#     [qw/WoW Super/],
#     'davids tags');

# is(
#     $query
#     ->filter(sub($obj) { $obj->{object_name} eq 'Bob' })
#     ->map(   sub($obj) { $obj->{tag_name} })
#     ->to_array,

#     [qw/Awesome/],
#     'Bobs Tags');

# is(
#     $query
#     ->filter(sub($obj) { $obj->{object_name} eq 'Alex' })
#     ->map(   sub($obj) { $obj->{tag_name} })
#     ->to_array,

#     [qw/Super/],
#     'Bobs Tags');


# filter->map can be replaced with choose
# is(
#     $query
#     ->choose(sub($obj) { $obj->{object_name} eq 'David' ? Some $obj->{tag_name} : None })
#     ->to_array,

#     [qw/WoW Super/],
#     'davids tags');

done_testing;