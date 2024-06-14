#!perl
use 5.036;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;
use DDP;

# Some values, functions, ... for testing
my $range     = Seq->range(1, 10);
my $rangeDesc = Seq->range(10, 1);

my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------


# Helpers
sub new_hash() {
    return sub() { return Hash->new };
}

sub by_num() {
    return sub($x,$y) { $x <=> $y };
}

# Build Test Data
sub entry($id, $name, $tag) {
    return { id => $id, name => $name, tag => $tag }
}

my $data = Array->new(
    entry(1, 'David', 'WoW'),
    entry(1, 'David', 'How'),
    entry(1, 'David', 'Super'),
    entry(2, 'Alex',  'Mega'),
    entry(2, 'Alex',  'Huhu'),
    entry(3, 'Bob',   'Toll'),
);

# group_by
{
    my $grouped = $data->group_by(key 'id');
    is($grouped, check_isa('Hash'), 'group_by return Hash');
    is($grouped->count, 3, '3 elements');

    is(
        $grouped,
        {
            1 => [
                { id => 1, name => 'David', tag => 'WoW'   },
                { id => 1, name => 'David', tag => 'How'   },
                { id => 1, name => 'David', tag => 'Super' },
            ],
            2 => [
                { id => 2, name => 'Alex', tag => 'Mega' },
                { id => 2, name => 'Alex', tag => 'Huhu' },
            ],
            3 => [
                { id => 3, name => 'Bob', tag => 'Toll' },
            ]
        },
        'group_by');
}

# group_fold
{
    my $grouped =
        $data->group_fold(
            new_hash(),
            key 'id',
            sub($hash, $entry) {
                # this will execute multiple times for each entry, but the
                # values are the same in the example data.
                $hash->set(
                    id   => $entry->{id},
                    name => $entry->{name}
                );
                $hash->push(tags => $entry->{tag});
                return $hash;
            }
        )
        ->sort(sub($x,$y) { $x->{id} <=> $y->{id} });

    is(
        $grouped,
        [
            {
                'id'   => 1,
                'tags' => ['WoW','How','Super'],
                'name' => 'David'
            },
            {
                'name' => 'Alex',
                'id'   => 2,
                'tags' => ['Mega', 'Huhu']
            },
            {
                'id'   => 3,
                'tags' => ['Toll'],
                'name' => 'Bob'
            }
        ],
        'group_fold');
}

done_testing;
