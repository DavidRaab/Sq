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

# check if int(1,10) is inclusive. Take as long values from the iterator
# until every value at least appeared once. Try at max 1 million elements.
{
    my $ints = Sq->rand->int(1,10)->take(1_000_000);
    my $seen = Hash->init(10, sub($idx) { $idx+1 => 0 });

    my $hash = $ints->take_while(sub($x) {
        $seen->{$x} = 1;
        # take as long any value in hash is equal to 0
        $seen->values->any(sub($x) { $x == 0 });
    })->count;

    ok($hash->values->all(sub($v) { $v > 0 }),           'count');
    is($seen, Hash->init(10, sub($idx) { $idx+1 => 1 }), 'all seen');
}

done_testing;
