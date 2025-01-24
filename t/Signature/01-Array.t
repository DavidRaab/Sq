#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

is(Array->empty, [], 'returns Array');
like(dies { Array->replicate("foo")             }, qr/\AArray::/, 'replicate 1');
like(dies { Array->replicate("foo",[])          }, qr/\AArray::/, 'replicate 2');
like(dies { Array->bless({})                    }, qr/\AArray::/, 'bless');
like(dies { Array->from_array({})               }, qr/\AArray::/, 'from_array');
like(dies { Array->init(1)                      }, qr/\AArray::/, 'init 1');
like(dies { Array->init("foo", sub{})           }, qr/\AArray::/, 'init 2');
like(dies { Array->init(1, "foo")               }, qr/\AArray::/, 'init 3');
like(dies { sq([1,2,3])->as_hash                }, qr/\AArray::/, 'as_hash');
like(dies { Array::to_array({})                 }, qr/\AArray::/, 'to_array 1');
like(dies { Array::to_array([], "foo")          }, qr/\AArray::/, 'to_array 2');
like(dies { Array::slice([1,2,3], 1,2,'foo')    }, qr/\AArray::/, 'slice');
like(dies { Array->concat([], [], 1)            }, qr/\AArray::/, 'concat');
like(dies { Array->range(1.2, 3.3)              }, qr/\AArray::/, 'range');
like(dies { Array->range_step(1, "f", 4)        }, qr/\AArray::/, 'range_step');
like(dies { Array::append([], {})               }, qr/\AArray::/, 'append 1');
like(dies { Array::append({}, [])               }, qr/\AArray::/, 'append 2');
like(dies { sq([1,2,3])->skip("foo")            }, qr/\AArray::/, 'skip');
like(dies { sq([1,2,3])->take("foo")            }, qr/\AArray::/, 'take');
like(dies { sq([[], [], 1])->to_array_of_array  }, qr/\AArray::/, 'to_array_of_array');
like(dies { Array->range(1,10)->windowed("foo") }, qr/\AArray::/, 'windowed');
like(dies { sq([1,2,3])->repeat("foo")          }, qr/\AArray::/, 'repeat');
like(dies { Array::fill2d([{}], sub {})         }, qr/\AArray::/, 'fill2d');
like(dies { Array::split(["foo+bar"], '+')      }, qr/\AArray::split:/, 'split');
like(dies { Array::head([])                     }, qr/\AArray::head/,   'head');
like(dies { Array::tail([])                     }, qr/\AArray::tail/,   'tail');

like(dies { sq(["12-12", "10-10", []])->rxm(qr/\A(\d\d)-(\d\d)\z/) }, qr/\AArray::/, 'rxm');
done_testing;
