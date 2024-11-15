#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Time::HiRes qw(time);
use Data::Dumper qw(Dumper);

# https://www.youtube.com/watch?v=HYv-gxDfRGo

# This generates a "random" job
sub gen_job {
    my $title =
        rand() > 0.5
        ? 'Senior Software Engineer'
        : 'Webmaster';

    my $detected_at =
        rand() > 0.5
        ? Some '20220201'
        : Some '20220213';

    my $disabled_at =
        rand() > 0.5
        ? Some '20220213'
        : None;

    return Hash->new(
        title       => $title,
        detected_at => $detected_at,
        disabled_at => $disabled_at,
    );
}

# generates 1 mio random jobs
my $jobs = Array->init(1_000_000, sub($idx) { gen_job });

# Stopwatch - when it started
my $start = time();

my $result = assign {
    my $data = Hash->new;

    $jobs->iter(sub($job) {
        $job->get('detected_at')->match(
            Some => sub($date) { $data->{$date}{pos}++ },
            None => sub {},
        );

        $job->get('disabled_at')->match(
            Some => sub($date) { $data->{$date}{neg}++ },
            None => sub {},
        );
    });

    return $data;
};

# stopwatch - when it stopped
my $stop = time();
printf "Timing: %f\n", ($stop - $start);

# print results
$result->keys->sort_str->iter(sub($date) {
    printf "%s - {pos => %d, neg => %d}\n",
        $date,
        $result->{$date}{pos} // 0,
        $result->{$date}{neg} // 0,
});
