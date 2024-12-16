#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Test2::V0 qw/is ok done_testing dies like check_isa/;

is(Array->empty, [], 'returns Array');
like(dies { Array->replicate("foo")     }, qr//, 'replicate 1');
like(dies { Array->replicate("foo",[])  }, qr//, 'replicate 2');
like(dies { Array->bless({})            }, qr//, 'bless');
like(dies { Array->from_array({})       }, qr//, 'from_array');
like(dies { Array->init(1)              }, qr//, 'init 1');
like(dies { Array->init("foo", sub{})   }, qr//, 'init 2');
like(dies { Array->init(1, "foo")       }, qr//, 'init 3');
like(dies { sq([5,"foo",2,1])->sort_num }, qr//, 'sort_num');

done_testing;
