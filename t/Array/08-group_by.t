#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

# Build Test Data
fn entry => record(qw/id name tag/);

my $data = sq [
    entry(1, 'David', 'WoW'),
    entry(1, 'David', 'How'),
    entry(1, 'David', 'Super'),
    entry(2, 'Alex',  'Mega'),
    entry(2, 'Alex',  'Huhu'),
    entry(3, 'Bob',   'Toll'),
];

# group_by
{
    my $grouped = $data->group_by(key 'id');
    check_isa($grouped, 'Hash', 'group_by return Hash');
    is($grouped->length, 3, '3 elements');

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
            sub { hash },
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
        );

    is(
        $grouped,
        {
            1 => {
                'id'   => 1,
                'tags' => ['WoW','How','Super'],
                'name' => 'David'
            },
            2 => {
                'name' => 'Alex',
                'id'   => 2,
                'tags' => ['Mega', 'Huhu']
            },
            3 => {
                'id'   => 3,
                'tags' => ['Toll'],
                'name' => 'Bob'
            }
        },
        'group_fold');

    is(
        $grouped->values->sort_hash(by_num, 'id'),
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
        'group_fold 2');
}

done_testing;
