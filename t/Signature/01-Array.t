#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

# Testing if signature works by passing wrong types as arguments

dies { Array->replicate("foo")             } qr/\AArray::/, 'replicate 1';
dies { Array->replicate("foo",[])          } qr/\AArray::/, 'replicate 2';
dies { Array->bless({})                    } qr/\AArray::/, 'bless';
dies { Array->from_array({})               } qr/\AArray::/, 'from_array';
dies { Array->init(1)                      } qr/\AArray::/, 'init 1';
dies { Array->init("foo", sub{})           } qr/\AArray::/, 'init 2';
dies { Array->init(1, "foo")               } qr/\AArray::/, 'init 3';
dies { sq([1,2,3])->as_hash                } qr/\AArray::/, 'as_hash';
dies { Array::to_array({})                 } qr/\AArray::/, 'to_array 1';
dies { Array::to_array([], "foo")          } qr/\AArray::/, 'to_array 2';
dies { Array::slice([1,2,3], 1,2,'foo')    } qr/\AArray::/, 'slice';
dies { Array->concat([], [], 1)            } qr/\AArray::/, 'concat';
dies { Array->range(1.2, 3.3)              } qr/\AArray::/, 'range';
dies { Array->range_step(1, "f", 4)        } qr/\AArray::/, 'range_step';
dies { Array::append([], {})               } qr/\AArray::/, 'append 1';
dies { Array::append({}, [])               } qr/\AArray::/, 'append 2';
dies { sq([1,2,3])->skip("foo")            } qr/\AArray::/, 'skip';
dies { sq([1,2,3])->take("foo")            } qr/\AArray::/, 'take';
dies { sq([[], [], 1])->to_array_of_array  } qr/\AArray::/, 'to_array_of_array';
dies { Array->range(1,10)->windowed("foo") } qr/\AArray::/, 'windowed';
dies { sq([1,2,3])->repeat("foo")          } qr/\AArray::/, 'repeat';
dies { Array::fill2d([{}], sub {})         } qr/\AArray::/, 'fill2d';
dies { Array::split(["foo+bar"], '+')      } qr/\AArray::split:/, 'split';
dies { Array::head([])                     } qr/\AArray::head/,   'head';
dies { Array::tail([])                     } qr/\AArray::tail/,   'tail';
dies { sq(["12-12", "10-10", []])->rxm(qr/\A(\d\d)-(\d\d)\z/) } qr/\AArray::/, 'rxm';

# Some Option Tests

dies {
    Some(10)->match(
        some => sub($x) { $x + 1 },
        none => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 1';

dies {
    Some(10)->match(
        Some => sub($x) { $x + 1 },
        none => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 2';

dies {
    Some(10)->match(
        some => sub($x) { $x + 1 },
        None => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 3';

dies {
    Some(10)->match(
        Some => "",
        None => sub()   { 0      },
    );
}
qr/\AOption::match/,
'Option::match 4';

dies {
    Some(10)->match(
        Some => sub($x) { $x + 1 },
        None => "",
    );
}
qr/\AOption::match/,
'Option::match 5';

done_testing;
