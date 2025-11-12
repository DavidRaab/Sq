#!/usr/bin/env perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;

# CSV: timeinseconds, frametimems, fps
my $data =
    Sq->io->csv_read("csv/Borderlands3_Benchmark.csv")
    ->map(call 'rename_keys', timeinseconds => "time", frametimems => "ms")
    ->cache;

printf "Recorded Frames: %d\n", $data->length;

# Show Max Frame Time
$data->max_by(key 'ms')->match(
    None => sub {
        printf "No Max Frame Time. Empty File or File does not exists."
    },
    Some => sub($max_time) {
        printf "Max Frame Time: %2f.\n", $max_time->{ms};
    }
);

say "\n  Game runs capped at 60 fps, so optimal ms should be 16.66ms.";
say "  Here are frames that took longer than 20ms.";
Sq->fmt->table({
    header => [qw/time ms fps/],
    data   => $data->keep(sub($row) { $row->{ms} > 20 }),
});

say "\n  Cases where game droped below 50 fps";
Sq->fmt->table({
    header => [qw/time ms fps/],
    data   => $data->keep(sub($row) { $row->{fps} < 50 }),
});

say "\nfps and frametime drops don't must be the same. But i guess the\n",
    "fps are just calculated from the ms of one frame\n";

say "Showing ms visually. Every frame is one symbol. . = <18ms, o = 18-20ms, C = >20ms";
$data->iter(sub($row) {
    my $ms = $row->{ms};

    print("C"), return if $ms > 20;
    print("o"), return if $ms >= 18;
    print ".";
});
print "\n";

say "\nAverage FPS for every Benchmark Second.";
printf "%s\n",
    # this builds an hash where the key is the time rounded to integer, and
    # the values is an array of all the frames in that second
    $data->group_by(sub($row) { int $row->{time} })
    # then the value (array) is replaced by its length. So we get a Hash with
    # time => frame-amount
    ->map(sub($k,$v) { return $k, $v->length })
    # the hash is than converted to an array. By passing the array() function we
    # build an array of [key,$value]
    ->to_array(\&array)
    # we sort the array by the index 0. this is the integer time
    ->sort_by(by_num, idx 0)
    # then we only select the second elements of the inner array. so we basically
    # drop the integer time. now we just have an array of fps for every benchmark
    # second.
    ->snds
    # for presenting we only want 10 items to show on one line. With chunked always
    # upto 10 elements are put into a chunk. now we have an Array of Arrays.
    ->chunked(10)
    # the inner array is string joined: Now we have array of strings.
    ->map(call join => " ")
    # then the array is joined, getting a single string, that is printed.
    ->join("\n");

say "\nDoing the above inspection, it showed that there was always 60 fps. I wondered";
say "Because i had some stutters. Also one Frametime is >40ms, so how is this possible?";
say "Somehow there is a 5ms frame in there. I use VRR (FreeSync) capped 60fps with RTSS";
say "I guess RTSS is responsible for this smoothness. Otherwise i assume more stutter";
say "woue be noticeable. So here are some frames below <=14ms.\n";

Sq->fmt->table({
    header => [qw/time ms fps/],
    data   => $data->keep(sub($row) { $row->{ms} <= 14 }),
});
