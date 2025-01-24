#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Type;
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

 ok(t_run($address, $users[0]{address}), '$users[0] is addr');
 ok(t_run($user, $users[0]),             '$users[0] is a user');
nok(t_run($user, $users[1]),             '$users[1] has a typo');

# Defining Type through data-structure
my $is_address = type [keys =>
    street => ['str'],
    city   => ['str'],
    state  => ['str'],
    zip    => [match => qr/\A\d+\z/],
];

my $is_user = type [keys =>
    id      => ['str'],
    first   => ['str'],
    last    => ['str'],
    address => $is_address,
];

 ok(t_run($is_address, $users[0]{address}), '$users[0] is addr');
 ok(t_run($is_user,    $users[0]),          '$users[0] is a user');
nok(t_run($is_user,    $users[1]),          '$users[1] has a typo');


done_testing;
