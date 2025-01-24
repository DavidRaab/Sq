#!perl
use 5.036;
use Sq -sig => 1;
use Sq::Test;

ok(1, 'Write a test');

# Because Types are just predicate functions, they should be passed
# everywhere a predicate function is expected.
#
# I should be able todo:         $opt->is_type($type);
#                                $array->filter_type($type);
#                                $array->filter_by($type);
#                                $array->type_filter();
# but also the other way around: my $predicate = t_as_predicate($type);
#
# maybe add: $type->as_predicate;
#
# how about a shorter name?
#
# $type->pred;  # bad because abrevation?
# $type->bool;  # because a predicate is a boolean function?

done_testing;
