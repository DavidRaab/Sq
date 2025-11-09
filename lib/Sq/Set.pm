package Sq::Set;
use 5.036;

# A set data-structure is an Array-like data-structure that keeps every
# value in it only a single-time. This has no priority at the moment.

# Implementing a Set can be done in two ways. Either a full equal() is used
# and when inserting the whole Array is scanned. This would be a bad implementation
# because it is slow. Adding would be a O(N) operation. But if wished, this
# can be so easily self implemented in Sq, as Sq already has a equal()
# that does a deep-datastructure comparison.

# A better approach would be when you provide a hashing function to create
# a unique key from every data-structure/object and so on, that defines
# uniqueness. That is anyway what is needed for a Set. But in that case
# you just can use a Hash. Because that is what it basically is.

# A Set would be somewhat a Hash that keeps the Order of the inserted
# elements. But again, not so much important. In nearly 30 years of programming
# i cannot remember once where i needed the ability of an OrderedHash. Not
# that no use cases exists, but i just solved everything without a specific Order.

1;