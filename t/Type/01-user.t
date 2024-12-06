#!perl
use 5.036;
use Sq;
use Sq::Type;
use Test2::V0 qw(is done_testing);

my $street = t_key street => t_str;
my $city   = t_key city   => t_str;
my $state  = t_key state  => t_str;
my $zip    = t_key zip    => t_str;
my $addr   = t_hash($street, $city, $state, $zip);

my $id    = t_key id    => t_str;
my $first = t_key first => t_str;
my $last  = t_key last  => t_str;
my $user  = t_hash($id, $first, $last, (t_key addr => $addr));

my @users = (
    # 0
    {
        id    => 1,
        first => "David",
        last  => "Raab",
        addr  => {
            street => 'Wonder Street',
            city   => 'Wonder City',
            state  => 'Wonder State',
            zip    => '12345',
        },
    },
    # 1
    {
        id    => 1,
        frist => "David",   # Typo
        last  => "Raab",
        addr  => {
            street => 'Wonder Street',
            city   => 'Wonder City',
            state  => 'Wonder State',
            zip    => '12345',
        },
    },
);

is(t_run($addr, $users[0]{addr}), Ok(1),
    '$users[0] is addr');
is(t_run($user, $users[0]), Ok(1),
    '$users[0] is a user');
is(t_run($user, $users[1]), Err("first does not exists on hash"),
    '$users[1] has a typo');

done_testing;
