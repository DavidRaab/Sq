#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

my $persons = Sq->io->csv_read("csv/persons.csv");
my $tags    = Sq->io->csv_read("csv/tags.csv");

# This creates the Cartesian Product. Basically like SQL, it just creates
# a N:M mapping of every possible combination. The keep() call only keeps
# those entries where id is the same as the person_id in tags. It's like
# a "WHERE p.id = t.person_is" in SQL.
my $data = $persons->cartesian($tags)->keep(sub($args) {
        my ($p, $t) = @$args;
        $p->{id} == $t->{person_id}
    })
    # TODO: This will be a common operation. Should be put into its own function
    #
    #       Like in SQL you get a "flat" structure. For every possible match you
    #       get a single line. The fold_mut call builds a document-like structure
    #       out of it. So all "tags" are combined into an Array.
    ->fold_mut(Hash->empty, sub($row, $state) {
        my ($p,$t) = @$row;
        $state->get($p->{id})->match(
            None => sub {
                $state->{$p->{id}} = sq {
                    name => $p->{name},
                    tags => [$t->{tag}],
                };
            },
            Some => sub($person) {
                $person->push(tags => $t->{tag});
            },
        );
    });

# dump($data);
# {
#   0 => { name => "Cherry", tags => [ "hot", "beautiful" ]      },
#   1 => { name => "Anny",   tags => [ "babe", "red", "french" ] },
#   2 => { name => "Lilly",  tags => [ "hot+++", "latina" ]      },
#   3 => { name => "Sola",   tags => [ "beautiful", "russian" ]  },
# }

my $data_table =
    # This transforms the "tags" array on each entry into a string
    $data->map(sub($k,$v) {
        return $k, $v->withf(tags => sub($tags) { $tags->join(",") });
    })
    # than transforms into array of hashes
    ->to_array(sub($k,$v) {
        sq { id => $k, %$v }
    })
    # and sorts it by user id
    ->sort_by(by_num, key 'id');

# $data was not mutated
#
# dump($data);
# dump($data_table);

# $data_table is now
#
# [
#   { id => 0, name => "Cherry", tags => "hot,beautiful"     },
#   { id => 1, name => "Anny",   tags => "babe,red,french"   },
#   { id => 2, name => "Lilly",  tags => "hot+++,latina"     },
#   { id => 3, name => "Sola",   tags => "beautiful,russian" },
# ]

# print the data as table
Sq->fmt->table({
    header => [qw/id name tags/],
    data   => $data_table,
    border => 0,
});
