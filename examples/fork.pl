#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Time::HiRes qw(sleep);

sub spawn($f) {
    my $pid = fork();
    if ( !defined $pid ) {
        die "Could not fork: $!\n";
    }
    # Parent
    if ( $pid ) {
        return;
    }
    # Child
    else {
        $f->();
        exit;
    }
}

sub fork_wait {
    1 while waitpid(-1, 0) > 0;
}

say "Spawning ...";

spawn(sub {
    for ( 10 .. 19 ) {
        sleep 0.1;
        say;
    }
});

spawn(sub {
    for ( 20 .. 29 ) {
        sleep 0.1;
        say;
    }
});

fork_wait();
say "Ended";

exit;