#!/usr/bin/env perl
use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use open ':std', ':encoding(UTF-8)';
use Data::Printer;
use List::Util qw(reduce);
use Path::Tiny;
use File::Spec;

# Read file into one string
my $content = join "", <>;

# Parse into array of commands and output
my @commands;
while ( $content =~ m/(\$ [^\$]+)/gxms ) {
    my $command = $1;
    if ( $command =~ m/\$ \s* (\N+) \R (.*) /xms ) {
        push @commands, [$1, $2];
    }
}

# p @commands;

# State: current working dir and fs to be build
my $cwd = path("/");
my $fs  = {};

# Apply every command to state
for my $command ( @commands ) {
    my ($cmd, $output) = @$command;

    if ( $cmd eq "cd /" ) {
        $cwd = path("/");
    }
    elsif ( $cmd eq "ls" ) {
        for my $line ( split /\n/, $output ) {
            if ( $line =~ m{\A dir \s+ (\N+) \Z}xms ) {
                add_dir($cwd->child($1), $fs);
            }
            elsif ( $line =~ m{\A (\d+) \s+ (\N+) \Z}xms ) {
                add_file($cwd->child($2), $1, $fs);
            }
            else {
                die (sprintf "Error: unknown line: [%s]", $line);
            }
        }
    }
    elsif ( $cmd eq "cd .." ) {
        $cwd = $cwd->parent;
    }
    elsif ( $cmd =~ m{\A cd \s+ (\S+) \s* \Z}xms ) {
        $cwd = $cwd->child($1);
    }
    else {
        die (sprintf "Error: unkown command [%s]\n", $cmd);
    }
}

# Part 1 - add size of all folders smaller equal 100_000

# p $fs;
my $out = dir_sizes($fs);
# p $out;
my $summed_size = 0;
for my $key ( keys %$out ) {
    my $value = $out->{$key};
    if ( $value <= 100_000 ) {
        $summed_size += $value;
    }
}
printf "Summed Size: %d\n", $summed_size;


# Part 2 - find smallest folder to delete
my $free   = 70_000_000 - $out->{"/"};
my $needed = 30_000_000 - $free;

my @pick;
while (my ($key, $value) = each %$out ) {
    if ( $value >= $needed ) {
        push @pick, [$key, $value];
    }
}

my $smallest = reduce { $a->[1] < $b->[1] ? $a : $b } @pick;
printf "Smallest to delete: %s Size: %d\n", $smallest->[0], $smallest->[1];

# Creates a flattened hash with (Path => Size)
sub dir_sizes ($fs) {
    my $out = {};
    dir_sizes_intern(path("/"), $out, $fs);
    return $out;
}

sub dir_sizes_intern ($cwd, $state, $fs) {
    my $size = 0;
    for my $key ( keys %$fs ) {
        my $value = $fs->{$key};
        if ( ref $value eq 'HASH' ) {
            $size += dir_sizes_intern($cwd->child($key), $state, $value);
        }
        else {
            $size += $value;
        }
    }
    $state->{$cwd} = $size;
    return $size;
}

# Inserts a file into hash data-structure
sub add_file ($path, $size, $fs) {
    my ($vol,$directory,$file) = File::Spec->splitpath($path);
    my $dir = add_dir(path($directory), $fs);
    $dir->{$file} = $size;
}

# Adds a file to a hash data-structure
sub add_file_array ($path, $size, $fs) {
    my @dirs = @$path;
    my $file = pop @dirs;

    my $dir = add_dir(@dirs);
    $dir->{$file} = $size;
}

# Adds a directory to a hash data-structure
sub add_dir ($dir, $fs) {
    if ( ref $dir eq 'ARRAY' ) {
        return add_dir_array($dir, $fs);
    }
    else {
        # discard empty string components
        my @dirs = grep { $_ ne "" } File::Spec->splitdir($dir);
        return add_dir_array(\@dirs, $fs);
    }
}

sub add_dir_array ($dirs, $fs) {
    my @dirs = @$dirs;
    # Abort if array is empty
    return $fs if @dirs == 0;

    # Otherwise continue adding directory
    my $dir  = shift @dirs;
    if ( not exists $fs->{$dir} ) {
        $fs->{$dir} = {};
    }
    return add_dir_array(\@dirs, $fs->{$dir});
}
