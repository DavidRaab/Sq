#!perl
use 5.036;
use Sq;
use Sq::Type;
use Sq::Sig;
use Sq::Test;

my $address = t_hash(t_keys(
    street => t_str,
    city   => t_str,
    state  => t_str,
    zip    => t_match(qr/\A\d+\z/),
));

my $user  = t_hash(t_keys(
    id      => t_str,
    first   => t_str,
    last    => t_str,
    address => $address,
));

my @users = (
    # 0
    {
        id      => 1,
        first   => "David",
        last    => "Raab",
        address => {
            street => 'Wonder Street',
            city   => 'Wonder City',
            state  => 'Wonder State',
            zip    => '12345',
        },
    },
    # 1
    {
        id      => 1,
        frist   => "David",   # Typo
        last    => "Raab",
        address => {
            street => 'Wonder Street',
            city   => 'Wonder City',
            state  => 'Wonder State',
            zip    => '12345',
        },
    },
);

is(t_run($address, $users[0]{address}), Ok(1),
    '$users[0] is addr');
is(t_run($user, $users[0]), Ok(1),
    '$users[0] is a user');
is(t_run($user, $users[1]), Err("hash: keys: 'first' not defined"),
    '$users[1] has a typo');

done_testing;
