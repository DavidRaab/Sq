#!/usr/bin/env perl
use v5.36;
use open ':std', ':encoding(UTF-8)';
use Sq;
use Time::HiRes qw(time);

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
#
# You can use Array->init or Seq->init here, and program runs without
# further changes. The total running time with 'Seq' is a little bit
# less compared to using an 'Array'. But computing $result is faster
# with 'Array'.
#
# Explanation:
#   Array: When using Array the whole Array has to be created first, this
#          takes time and memory. Then after creation the array has to
#          be iterated once again.
#   Seq:   When using Seq nothing is computed/creates before iterating.
#          Jobs are created while iterating, and while all jobs are iterated
#          the result is already computed. Even though iterating with Seq
#          is slower, not having the extra time of generating makes it faster
#          overall.
my $jobs = Seq->init(1_000_000, sub($idx) { gen_job });

# Stopwatch - when it started
my $start = time();

my $result = $jobs->fold_mut(Hash->new, sub($hash,$job) {
    $job->get('detected_at')->iter(sub($date) {
        $hash->{$date}{pos}++;
    });

    $job->get('disabled_at')->iter(sub($date) {
        $hash->{$date}{neg}++;
    });
});

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
