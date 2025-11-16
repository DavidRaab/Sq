#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

my $a1 = sq([1..10]);
check_isa($a1, 'Array', '$a1');

my $a2 = sq([
    [1,2,3],
    [4,5,6],
    [7,8,9],
]);
check_isa($a2, 'Array', '$a2');
$a2->iter(sub($x) { check_isa($x, 'Array', 'inner of $a2') });

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

check_isa($album, 'Hash', '$album');
check_isa($album->{tracks}, 'Array', 'album->tracks');
$album->{tracks}->iteri(sub($hash,$idx) {
    check_isa($hash, 'Hash', "album->tracks $idx is Hash");
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
    check_isa($album, 'Hash', '$album');
    check_isa($album->{tracks}, 'Array', 'album->tracks');
    $album->{tracks}->iteri(sub($hash,$idx) {
        check_isa($hash, 'Hash', "album->tracks $idx is Hash");
    });
    $album->{tags}->iter(sub($tags) {
        check_isa($tags,           'Array', 'tags is array');
        check_isa($tags->[2],      'Hash',  'index 2 is Hash');
        check_isa($tags->[2]{foo}, 'Array', '$tags->[2]{foo} is array');
    });
});

my $mixed = sq Array->new(
    { foo => 1 },
    Hash->new(
        bar => [1,2,3]
    ),
);

check_isa($mixed, 'Array', '$deep is array');
$mixed->iter(sub($x) { check_isa($x, 'Hash', 'mixed contains Hash') });
check_isa($mixed->[1]{bar}, 'Array', '$mixed->[1]{bar} is Array');

done_testing;
