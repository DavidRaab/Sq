#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Time::HiRes qw(time);
use Data::Dumper qw(Dumper);

# https://www.youtube.com/watch?v=HYv-gxDfRGo

# This generates a "random" job
sub gen_job {
    my $title =
        rand() > 0.5
        ? 'Senior Software Engineer'
        : 'Webmaster';

    my $detected_at = rand() > 0.5 ? '20220201' : '20220213';
    my $disabled_at = rand() > 0.5 ? '20220213' : undef;

    return {
        title       => $title,
        detected_at => $detected_at,
        disabled_at => $disabled_at,
    };
}

# generates 1 mio random jobs
my @jobs = map { gen_job } 1 .. 1_000_000;

# Stopwatch - when it started
my $start = time();

my $result = {};
{
    for my $job ( @jobs ) {
        if ( defined $job->{detected_at} ) {
            my $date = $job->{detected_at};
            $result->{$date}{pos}++;
        }

        if ( defined $job->{disabled_at} ) {
            my $date = $job->{disabled_at};
            $result->{$date}{neg}++;
        }
    }
};

# stopwatch - when it stopped
my $stop = time();
printf "Timing: %f\n", ($stop - $start);

# print results
for my $date ( sort { $a cmp $b } keys %$result ) {
    printf "%s - {pos => %d, neg => %d}\n",
        $date,
        $result->{$date}{pos} // 0,
        $result->{$date}{neg} // 0,
}
