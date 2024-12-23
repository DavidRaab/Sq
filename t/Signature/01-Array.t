#!perl
use 5.036;
use Sq;
use Sq::Sig;
use Sq::Test;

is(Array->empty, [], 'returns Array');
like(dies { Array->replicate("foo")     }, qr//, 'replicate 1');
like(dies { Array->replicate("foo",[])  }, qr//, 'replicate 2');
like(dies { Array->bless({})            }, qr//, 'bless');
like(dies { Array->from_array({})       }, qr//, 'from_array');
like(dies { Array->init(1)              }, qr//, 'init 1');
like(dies { Array->init("foo", sub{})   }, qr//, 'init 2');
like(dies { Array->init(1, "foo")       }, qr//, 'init 3');
like(
    dies { sq(["12-12", "10-10", []])->regex_match(qr/\A(\d\d)-(\d\d)\z/) },
    qr//, 'regex_match');
like(dies { sq([1,2,3])->as_hash                }, qr/\AType Error:/,     'as_hash');
like(dies { Array::to_array({})                 }, qr/\AType Error: or:/, 'to_array 1');
like(dies { Array::to_array([], "foo")          }, qr/\AType Error: or:/, 'to_array 2');
like(dies { Array::slice([1,2,3], 1,2,'foo')    }, qr/\AType Error:/,     'slice');
like(dies { Array->concat([], [], 1)            }, qr/\AType Error:/,     'concat');
like(dies { sq([1,2,3,"foo" ])->sort_num        }, qr/\AType Error:/,     'sort_num');
like(dies { sq([1,[],3,"foo"])->sort_str        }, qr/\AType Error:/,     'sort_str');
like(dies { Array->range(1.2, 3.3)              }, qr/\AType Error:/,     'range');
like(dies { Array->range_step(1, "f", 4)        }, qr/\AType Error:/,     'range_step');
like(dies { Array::append([], {})               }, qr/\AType Error:/,     'append 1');
like(dies { Array::append({}, [])               }, qr/\AType Error:/,     'append 2');
like(dies { sq([1,2,3])->skip("foo")            }, qr/\AType Error:/,     'skip');
like(dies { sq([1,2,3])->take("foo")            }, qr/\AType Error:/,     'take');
like(dies { sq([[], [], 1])->to_array_of_array  }, qr/\AType Error:/,     'to_array_of_array');
like(dies { Array->range(1,10)->windowed("foo") }, qr/\AType Error:/,     'windowed');
like(dies { sq([1,2,3])->repeat("foo")          }, qr/\AType Error:/,     'repeat');

done_testing;
