#!perl
use 5.036;
use Sq;
use Sq::Language;
use Test2::V0 qw(is done_testing);

my $street = key street => is_str;
my $city   = key city   => is_str;
my $state  = key state  => is_str;
my $zip    = key zip    => is_str;
my $addr   = a_hash($street, $city, $state, $zip);

my $id    = key id    => is_str;
my $first = key first => is_str;
my $last  = key last  => is_str;
my $user  = a_hash($id, $first, $last, (key addr => $addr));

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

is(check($users[0]{addr}, $addr), Ok(1),
    '$users[0] is addr');
is(check($users[0], $user), Ok(1),
    '$users[0] is a user');
is(check($users[1], $user), Err("first does not exists on hash"),
    '$users[1] has a typo');

done_testing;
