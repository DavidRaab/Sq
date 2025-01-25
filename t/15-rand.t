#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

ok(Sq->rand->int(0,0)->take(100)->all(sub($x) { $x == 0 }), 'int 0');
ok(Sq->rand->int(0,1)->take(100)->all(sub($x) { $x <= 1 }), 'int 1');
ok(Sq->rand->int(0,2)->take(100)->all(sub($x) { $x <= 2 }), 'int 2');

ok(Sq->rand->int(10,20)->take(100)->all(sub($x) { $x >= 10 && $x <= 20 }), 'int 3');

{
    my $ints = Sq->rand->int(1,10)->take(1_000_000);
    my $seen = Hash->init(10, sub($idx) { $idx+1 => 0 });

    # TODO: Can i create an abstraction from this?
    # Manually iterate through sequence
    my $it = $ints->();
    while ( defined(my $x = $it->()) ) {
        $seen->{$x} = 1;
        last if $seen->values->sum == 10;
    }
    is($seen, Hash->init(10, sub($idx) { $idx+1 => 1 }), 'all seen');
}

done_testing;
