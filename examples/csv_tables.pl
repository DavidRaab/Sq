#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

my $persons = Sq->io->csv_read("csv/persons.csv");
my $tags    = Sq->io->csv_read("csv/tags.csv");

# TODO: I still don't like it, even if it improved somehow. The choose() is
#       still too much clutter.
my $data =
    # This creates the Cartesian Product. Basically like SQL, it just creates
    # a N:M mapping of every possible combination.
    $persons->cartesian($tags)
    # choose is similar to keep(). Only those entries that return Some() are picked,
    # None are skipped. But this way, you also can change or return different values.
    # choose is like a keep()->map() in one operation.
    #
    # Here we only pick those combination where "person.id" is the same as "tag.person_id"
    # then we combine both hashes into one single hash, but we change some keys of
    # the second, so the second hash don't overrides the ones in the first hash.
    # Very similar to SQL.
    #
    # SELECT p.id, p.name, t.id AS tid, t.person_id, t.tag AS tags
    # FROM   persons p, tags t
    # WHERE  p.id = t.person_id
    ->choose(sub($args) {
        my ($p, $t) = @$args;
        if ( $p->{id} == $t->{person_id} ) {
            return Some(Hash::append(
                $p,
                $t->rename_keys(id => 'tid', tag => 'tags')
            ));
        }
        return None;
    })
    ->combine(key id => 'tags');

# dump($data);
#
# TODO: DS changed
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
    ->to_array(sub($k,$v) { $v })
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
