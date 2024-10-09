#!perl
use 5.036;
use DDP;
use Sq;
use Test2::V0 ':DEFAULT', qw/number_ge check_isa dies hash field array item end bag float U/;

#----------

my $heap = Heap->new(sub($x,$y) { $x <=> $y });

is($heap->head,   undef, 'head on empty');
is($heap->remove, undef, 'remove on empty');

$heap->add(10);
is($heap->head, 10, 'is 10');

Heap::add($heap, 3);
is($heap->head, 3, 'is 3');

Heap::add($heap, 12);
is($heap->head, 3, 'is 3');

$heap->add(2);
is($heap->head, 2, 'is 2');

$heap->add(45, 30, 9, 1, 46);
is($heap->head, 1, 'is 1');

for my $expect ( 1,2,3,9,10,12,30,45,46 ) {
    my $got = $heap->remove();
    is($got, $expect, 'x is y');
}

is($heap->head, undef, 'empty');

$heap->add(10,9,7,3,2,1,5,5,2,100,80);
my $sorted = $heap->remove_all;

is($sorted, [1,2,2,3,5,5,7,9,10,80,100], 'heap sort');
is($heap->count, 0, 'empty');

$heap->add(5,10,50);
is($heap->remove, 5, 'remove 5');

$heap->add(100,3,20,10);
is($heap->remove, 3, 'remove 3');

$heap->add(40, 50, 60);
is($heap->remove, 10, 'remove 10');

my @rest = $heap->remove_all;
is(\@rest, [10,20,40,50,50,60,100], 'rest');

# ----
# Complex example checking comparison function
{
    # sorts items by last string, then first string
    my $heap = Heap->new(sub($x,$y) {
        my $a = $x->{last} cmp $y->{last};
        if ( $a == 0 ) {
            return $x->{first} cmp $y->{first};
        }
        else {
            return $a;
        }
    });

    Heap::add($heap,
        { first => 'Dieter',   last => 'Zentner'   },
        { first => 'Zoola',    last => 'Bertrecht' },
        { first => 'Micky',    last => 'Mouse'     },
        { first => 'Daisy',    last => 'Mouse'     },
        { first => 'Donald',   last => 'Duck'      },
        { first => 'Donatelo', last => 'Turtle'    },
        { first => 'Spider',   last => 'Man'       },
        { first => 'Clark',    last => 'Kent'      },
    );

    is(
        $heap->remove_all,
        [
            { first => 'Zoola',    last => 'Bertrecht' },
            { first => 'Donald',   last => 'Duck'      },
            { first => 'Clark',    last => 'Kent'      },
            { first => 'Spider',   last => 'Man'       },
            { first => 'Daisy',    last => 'Mouse'     },
            { first => 'Micky',    last => 'Mouse'     },
            { first => 'Donatelo', last => 'Turtle'    },
            { first => 'Dieter',   last => 'Zentner'   },
        ],
        'heap sort on hashes');
}

# check correct true/false in remove_all
{
    my $heap = Heap->new(sub($x,$y) { $x <=> $y });
    $heap->add(3,2,1);
    $heap->add(0);
    $heap->add(-5,-10);

    is(
        $heap->remove_all,
        [-10,-5,0,1,2,3],
        'correct behaviour with 0')
}

# some random gen tests
for my $i ( 1 .. 25 ) {
    my @data = map { rand() } 1 .. 20;
    my $heap = Heap->new(sub($x,$y) { $x <=> $y });
    $heap->add(@data);

    is(
        $heap->remove_all,
        [sort { $a <=> $b } @data],
        "random num test $i");
}

sub random_string($length) {
    state @chars = ('A' .. 'Z', 'a' .. 'z', 0 .. 9);
    state $count = scalar @chars;

    my $new = "";
    for my $i ( 1 .. $length ) {
        $new .= $chars[ rand() * $count ]
    }
    return $new;
}

for my $i ( 1 .. 10 ) {
    my @data = map { random_string(10) } 1 .. 20;
    my $heap = Heap->new(sub($x,$y) { $x cmp $y });
    $heap->add(@data);

    is(
        $heap->remove_all,
        [sort { $a cmp $b } @data],
        "random string test $i");
}

done_testing;