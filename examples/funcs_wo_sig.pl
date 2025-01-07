#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Sq::Reflection;
use Sq::Gen;
use Sq::Parser -sig => 1;
use Sq::Sig;

# This script prints all functions in Sq, that have no type-check with
# signature added.

sub fqdn($package) {
    my %skip;
    for my $name ( @Sq::EXPORT ) {
        $skip{$name} = 1 if is_str($name);
    }
    $skip{import} = 1;

    all_funcs($package)
    ->remove(sub($name) { $skip{$name}    })
    ->rxs(qr/\A/, sub   { $package . '::' });
}

my $funcs = Array->concat(
    fqdn('Array'),  fqdn('Seq'),        fqdn('Option'),
    fqdn('Result'), fqdn('Sq::Parser'), fqdn('Sq::Gen'),
);

# dumpw($funcs);

my $sigs = Sq::Signature::sigs_added();

# dumpw($sigs);

say "Following functions is missing a signature:";
Array::diff($funcs, $sigs, \&id)->iter_sort(by_str, sub($func) {
    say $func;
});
