#!perl
use 5.036;
use Sq;
use Sq::Type;
use Sq::Evaluator;
use Sq::Sig;
use Sq::Test;

my $album = Sq::Evaluator::type
    [hash =>
      [with_keys => qw/artist title tracks/],
      [keys =>
        artist => ['str'],
        title  => ['str'],
        tracks => [array => [of => [hash =>
          [with_keys => qw/name duration/],
          [keys =>
            name     => ['str'],
            duration => ['int']]]]]]];

nok(t_valid($album, {}), 'album 1');

ok(t_valid($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [],
}), 'album 2');

nok(t_valid($album, {
    artist => [],
    title  => 'Greatest Hit',
    tracks => [],
}), 'album 3');

nok(t_valid($album, {
    artist => 'Yep',
    title  => [],
    tracks => [],
}), 'album 4');

ok(t_valid($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300}
    ],
}), 'album 5');

nok(t_valid($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => "foo"}
    ],
}), 'album 6');

ok(t_valid($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => 200},
    ],
}), 'album 7');

nok(t_valid($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => "foo"},
    ],
}), 'album 8');

nok(t_valid($album, {
    artist => 'Yep',
    title  => 'Greatest Hit',
    tracks => [
        {name => 'Woot', duration => 300},
        {name => 'Huhu', duration => 100},
        {},
    ],
}), 'album 9');

done_testing;
