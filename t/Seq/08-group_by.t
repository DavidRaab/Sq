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
    return sub() { return {} };
}

sub by_num() {
    return sub($x,$y) { $x <=> $y };
}

# Build Test Data
sub entry($id, $name, $tag) {
    return { id => $id, name => $name, tag => $tag }
}

my @data = (
    entry(1, 'David', 'WoW'),
    entry(1, 'David', 'How'),
    entry(1, 'David', 'Super'),
    entry(2, 'Alex',  'Mega'),
    entry(2, 'Alex',  'Huhu'),
    entry(3, 'Bob',   'Toll'),
);

# group_by
{
    my $grouped = Seq->from_array(\@data)->group_by(key 'id');
    is($grouped->count, 3, '3 elements');

    # turn seq of seq into AoA
    my $data =
        $grouped
        ->map(sub($group) { $group->to_array })
        ->sort(sub($x,$y) { $x->[0]{id} <=> $y->[0]{id} })
        ->to_array;

    is(
        $data,
        [
            [
                { id => 1, name => 'David', tag => 'WoW'   },
                { id => 1, name => 'David', tag => 'How'   },
                { id => 1, name => 'David', tag => 'Super' },
            ],
            [
                { id => 2, name => 'Alex', tag => 'Mega' },
                { id => 2, name => 'Alex', tag => 'Huhu' },
            ],
            [
                { id => 3, name => 'Bob', tag => 'Toll' },
            ]
        ],
        'group_by');
}

# group_fold
{
    my $grouped =
        Seq->from_array(\@data)->group_fold(
            new_hash(),
            key 'id',
            sub($hash, $entry) {
                $hash->{id}   = $entry->{id};
                $hash->{name} = $entry->{name};
                push $hash->{tags}->@*, $entry->{tag};
                return $hash;
            }
        )
        ->sort(sub($x,$y) { $x->{id} <=> $y->{id} });

    is(
        $grouped->to_array,
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
