#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

# Some values, functions, ... for testing
my $add     = sub($x,$y) { $x + $y     };
my $add1    = sub($x)    { $x + 1      };
my $double  = sub($x)    { $x * 2      };
my $square  = sub($x)    { $x * $x     };
my $is_even = sub($x)    { $x % 2 == 0 };

#----------

my $is_array = check_isa('Array');
my $is_hash  = check_isa('Hash');

my $a1 = sq([1..10]);
is($a1, $is_array, '$a1');

my $a2 = sq([
    [1,2,3],
    [4,5,6],
    [7,8,9],
]);
is($a2, $is_array, '$a2');
$a2->iter(sub($x) { is($x, $is_array, 'inner of $a2') });

my $album = sq {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tracks => [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
};

is($album, $is_hash, '$album');
is($album->{tracks}, $is_array, 'album->tracks');
$album->{tracks}->iteri(sub($hash,$idx) {
    is($hash, $is_hash, "album->tracks $idx is Hash");
});
is(
    $album->get('tracks')->map(call 'sum_by', key 'duration')->or(0),
    2559,
    'album runtime 1');
is(
    $album->get('tracks')->map(sub ($tracks) {
        $tracks->sum_by(key 'duration');
    })->or(0),
    2559,
    'album runtime 2');

is(
    $album->get('tracks')->map(sub ($tracks) {
        $tracks->sum_by(sub($hash) { $hash->{duration} });
    })->or(0),
    2559,
    'album runtime 3');

{
    my $sum = 0;
    my $tracks = $album->{tracks};
    if ( defined $tracks ) {
        for my $track ( @$tracks ) {
            $sum += $track->{duration};
        }
    }
    is($sum, 2559, 'pure perl version');
}

my $opt = Some(sq {
    artist => 'Michael Jackson',
    title  => 'Thriller',
    tags   => Some([qw/80 horror/, {foo => [1,2,3]}]),
    tracks => [
        {title => "Wanna Be Startin’ Somethin", duration => 363},
        {title => "Baby Be Mine",               duration => 260},
        {title => "The Girl Is Mine",           duration => 242},
        {title => "Thriller",                   duration => 357},
        {title => "Beat It",                    duration => 258},
        {title => "Billie Jean",                duration => 294},
        {title => "Human Nature",               duration => 246},
        {title => "P.Y.T.",                     duration => 239},
        {title => "The Lady in My Life",        duration => 300},
    ],
});

$opt->iter(sub($album) {
    is($album, $is_hash, '$album');
    is($album->{tracks}, $is_array, 'album->tracks');
    $album->{tracks}->iteri(sub($hash,$idx) {
        is($hash, $is_hash, "album->tracks $idx is Hash");
    });
    $album->{tags}->iter(sub($tags) {
        is($tags, $is_array, 'tags is array');
        is($tags->[2], $is_hash, 'index 2 is Hash');
        is($tags->[2]{foo}, $is_array, '$tags->[2]{foo} is array');
    });
});

my $mixed = sq Array->new(
    { foo => 1 },
    Hash->new(
        bar => [1,2,3]
    ),
);

is($mixed, $is_array, '$deep is array');
$mixed->iter(sub($x) { is($x, $is_hash, 'mixed contains Hash') });
is($mixed->[1]{bar}, $is_array, '$mixed->[1]{bar} is Array');



done_testing;
