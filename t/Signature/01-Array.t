#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

is(Array->empty, [], 'returns Array');
like(dies { Array->replicate("foo")     }, qr/Array::/, 'replicate 1');
like(dies { Array->replicate("foo",[])  }, qr/Array::/, 'replicate 2');
like(dies { Array->bless({})            }, qr/Array::/, 'bless');
like(dies { Array->from_array({})       }, qr/Array::/, 'from_array');
like(dies { Array->init(1)              }, qr/Array::/, 'init 1');
like(dies { Array->init("foo", sub{})   }, qr/Array::/, 'init 2');
like(dies { Array->init(1, "foo")       }, qr/Array::/, 'init 3');
like(
    dies { sq(["12-12", "10-10", []])->regex_match(qr/\A(\d\d)-(\d\d)\z/) },
    qr//, 'regex_match');
like(dies { sq([1,2,3])->as_hash                }, qr/\AArray::/,     'as_hash');
like(dies { Array::to_array({})                 }, qr/\AArray::/, 'to_array 1');
like(dies { Array::to_array([], "foo")          }, qr/\AArray::/, 'to_array 2');
like(dies { Array::slice([1,2,3], 1,2,'foo')    }, qr/\AArray::/,     'slice');
like(dies { Array->concat([], [], 1)            }, qr/\AArray::/,     'concat');
like(dies { Array->range(1.2, 3.3)              }, qr/\AArray::/,     'range');
like(dies { Array->range_step(1, "f", 4)        }, qr/\AArray::/,     'range_step');
like(dies { Array::append([], {})               }, qr/\AArray::/,     'append 1');
like(dies { Array::append({}, [])               }, qr/\AArray::/,     'append 2');
like(dies { sq([1,2,3])->skip("foo")            }, qr/\AArray::/,     'skip');
like(dies { sq([1,2,3])->take("foo")            }, qr/\AArray::/,     'take');
like(dies { sq([[], [], 1])->to_array_of_array  }, qr/\AArray::/,     'to_array_of_array');
like(dies { Array->range(1,10)->windowed("foo") }, qr/\AArray::/,     'windowed');
like(dies { sq([1,2,3])->repeat("foo")          }, qr/\AArray::/,     'repeat');

done_testing;
