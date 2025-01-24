#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Type;
use Sq::Test;

my $album = type
    [hash => [keys =>
        artist => [str => [min => 1]],
        title  => [str => [min => 1]],
        tracks =>
            [array => [of => [hash => [keys =>
                name     => ['str'],
                duration => ['int']]]]]]];

nok(t_run($album, {}), 'album 1');

ok(t_run($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [],
}), 'album 2');

nok(t_run($album, {
    artist => [],
    title  => 'Greatest Hit',
    tracks => [],
}), 'album 3');

nok(t_run($album, {
    artist => 'Yep',
    title  => [],
    tracks => [],
}), 'album 4');

ok(t_run($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300}
    ],
}), 'album 5');

nok(t_run($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => "foo"}
    ],
}), 'album 6');

ok(t_run($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => 200},
    ],
}), 'album 7');

nok(t_run($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => "foo"},
    ],
}), 'album 8');

nok(t_run($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => 100},
        {},
    ],
}), 'album 9');

nok(t_run($album, {
    artist => '',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => 100},
        {},
    ],
}), 'album 10');

nok(t_run($album, {
    artist => 'Yep',
    title  => '',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => 100},
        {},
    ],
}), 'album 11');


done_testing;
