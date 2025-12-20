#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

# This file contains multiple things that was previously
# a seperated file. They are merged together

# bind-flatten
{
    # lazy
    my $data1 = seq(
        seq(1,1),
        seq(2,3,5,8,13),
    );

    # non-lazy
    my $data2 = [
        [1,1],
        [2,3,5,8,13],
    ];

    # non lazy implementation of flatten
    sub flatten($aoa) {
        my @flattened;
        for my $outer ( @$aoa ) {
            for my $inner ( @$outer ) {
                push @flattened, $inner;
            }
        }
        return \@flattened;
    };

    # test both calling styles
    is(
        Seq::flatten($data1)->to_array,
        flatten($data2),
        'flatten fp - non-lazy');

    is(
        $data1->flatten->to_array,
        flatten($data2),
        'flatten oo - non-lazy');

    ## Implementing bind with map->flatten
    my $bind = sub($s, $f) {
        return $s->map($f)->flatten;
    };

    # check if bind is same as map->flatten
    is(
        $data1->bind(\&id),
        $bind->($data1, \&id),
        'bind implemented with map and flatten');
}

# Certesian
{
    my $cards =
        Seq::cartesian(
            seq(qw/clubs spades hearts diamond/),
            seq(qw/7 8 9 10 B D K A/),
        );

    # check cartesian first -- is used by join/select
    is(
        $cards,
        seq(
            (map { [clubs   => $_ ] } qw/7 8 9 10 B D K A/),
            (map { [spades  => $_ ] } qw/7 8 9 10 B D K A/),
            (map { [hearts  => $_ ] } qw/7 8 9 10 B D K A/),
            (map { [diamond => $_ ] } qw/7 8 9 10 B D K A/),
        ),
        'cartesian 1');

    # testing full output
    is(
        $cards,
        seq(
            ['clubs'  ,'7'],['clubs'  ,'8'],['clubs'  ,'9'],['clubs'  ,'10'],
            ['clubs'  ,'B'],['clubs'  ,'D'],['clubs'  ,'K'],['clubs'  ,'A' ],
            ['spades' ,'7'],['spades' ,'8'],['spades' ,'9'],['spades' ,'10'],
            ['spades' ,'B'],['spades' ,'D'],['spades' ,'K'],['spades' ,'A' ],
            ['hearts' ,'7'],['hearts' ,'8'],['hearts' ,'9'],['hearts' ,'10'],
            ['hearts' ,'B'],['hearts' ,'D'],['hearts' ,'K'],['hearts' ,'A' ],
            ['diamond','7'],['diamond','8'],['diamond','9'],['diamond','10'],
            ['diamond','B'],['diamond','D'],['diamond','K'],['diamond','A' ],
        ),
        'cartesian 2');

    is(
        $cards->to_array,
        Array::cartesian(
            [qw/clubs spades hearts diamond/],
            [qw/7 8 9 10 B D K A/],
        ),
        'Seq::cartesian vs Array::cartesian');
}

# Fibonacci numbers
{
    my $fib =
        Seq->concat(
            Seq->new(1,1),
            Seq->unfold([1,1], sub($state) {
                my $next = fst($state) + snd $state;
                return $next, [snd($state),$next];
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

# Another way of calculating fib
{
    my $fib =
        Seq->concat(
            seq(1,1),
            Seq->unfold([1,1], sub($state) {
                my $next = Array::sum($state);
                return $next, [$state->[1], $next];
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

# You also can use a hash as a state.
{
    my $fib =
        Seq->concat(
            seq(1,1),
            Seq->unfold({x => 1, y => 1}, sub($state) {
                my $next = $state->{x} + $state->{y};
                return $next, {x => $state->{y}, y => $next };
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

# Or probably most efficent is to use Seq->from_sub as this way we don't
# need to create a lot of arrays, we can use a queue instead.
{
    my $fib =
        Seq->concat(
            seq(1,1),
            Seq->from_sub(sub{
                # State of the sequence comes here
                my @queue = (1,1);

                # this function is executed every time you request a new value
                # from the sequence.
                return sub {
                    push @queue, ($queue[0] + $queue[1]);
                    shift @queue;
                    return $queue[1];
                }
            })
        );

    is(
        $fib->take(20)->to_array,
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 1');

    is(
        $fib->to_array(20),
        [1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765],
        'First 20 Fibonacci numbers 2');
}

# Stuff that is possible because arrayref are mutable
{
    my @data = (1,2,3,4,5);
    my $data = Seq->from_array(\@data);

    is($data->length, 5, 'length is 5');
    is($data->to_array, [1..5], '$data as array');

    # change @data
    push @data, 6;
    is($data->length, 6, 'length is 6');
    is($data->to_array, [1..6], '$data now contains 6 elements');
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
        $data->sort(by_str),
        ["1Foo", "2Bar", "3Baz"],
        'hash to sequence');

    # add entry to data
    $data{4} = 'Maz';

    is($data->length, 4, 'length from hashref is 4');
    is(
        $data->sort(by_str),
        ["1Foo", "2Bar", "3Baz", "4Maz"],
        'hash to sequence after added key');
}

# difference of wrap and from_array
{
    my @data = (1..10);

    # makes a copy at that time
    my $data1 = seq(@data);
    # just refers to the array
    my $data2 = Seq->from_array(\@data);

    is($data1->length, 10, '$data1 has 10 items');
    is($data2->length, 10, '$data2 has 10 items');

    # we now add an element to the array
    push @data, 11;

    is($data1->length, 10, '$data1 still has 10 items');
    is($data2->length, 11, '$data2 now has 11 items');
}

# OO and functional interface
{
    # chained
    is(
        Seq->new(1,2,3)->append(seq(4,5,6)),
        seq(1 .. 6),
        'append with chaining');

    # nested
    is(
        Seq::append(
            seq(1,2,3),
            seq(4,5,6),
        ),
        Seq->range(1,6),
        'append as function');

    # chained vs nested
    is(
        Seq::append(
            Seq->range(1,5),
            Seq->range(5,1),
        ),
        Seq
        ->range(1,5)
        ->append(Seq->range(5,1)),

        'chaining vs nesting');

    # another chained version
    is(
        Seq::append(
            Seq->range(1,5),
            Seq->range(5,1),
        ),

        Seq->empty
        ->append(Seq->range(1,5))
        ->append(Seq->range(5,1)),

        'chaining and starting with empty');
}

# group_by
{
    # Build Test Data
    fn entry => record(qw/id name tag/);
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

        # check if all values are blessed arrays
        $grouped->values->iter(sub($value) {
            is(ref($value), 'Array', 'is blessed Array');
        });
    }

    # group_fold
    {
        my $grouped =
            Seq->from_array(\@data)->group_fold(
                sub { Hash->new },
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
            $grouped->values->sort_by(by_num, key 'id'),
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
}

done_testing;
