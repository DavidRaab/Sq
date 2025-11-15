#!perl
use 5.036;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Sq -sig => 1;
use Sq::Test;

{
    my $orig = [];
    my $copy = copy($orig);
    is(ref $orig,    'ARRAY', '$orig is unchanged');
    check_isa($copy, 'Array', 'copy of array adds blessing');

    push @$orig, 1;
    is($orig, [1], '$orig after push 1');
    is($copy, [],  '$copy after push 1');

    push @$copy, 2;
    is($orig, [1], '$orig after push 2');
    is($copy, [2], '$copy after push 2');
}

{
    my $orig = [1,2,3];
    my $copy = copy($orig);

    push @$orig, 1;
    is($orig, [1,2,3,1], '$orig after push 1');
    is($copy, [1,2,3],  '$copy after push 1');

    push @$copy, 2;
    is($orig, [1,2,3,1], '$orig after push 2');
    is($copy, [1,2,3,2], '$copy after push 2');
}

{
    my $orig = [1,[2,3],4];
    my $copy = copy($orig);

    push @$orig, 1;
    is($orig, [1,[2,3],4,1], '$orig after push 1');
    is($copy, [1,[2,3],4],  '$copy after push 1');

    push @$copy, 2;
    is($orig, [1,[2,3],4,1], '$orig after push 2');
    is($copy, [1,[2,3],4,2], '$copy after push 2');

    push $orig->[1]->@*, 10;
    is($orig, [1,[2,3,10],4,1], '$orig after push 3');
    is($copy, [1,[2,3],4,2], '$copy after push 2');

    push $copy->[1]->@*, 20;
    is($orig, [1,[2,3,10],4,1], '$orig after push 3');
    is($copy, [1,[2,3,20],4,2], '$copy after push 2');
}

{
    my $orig = array(1,[2,3],4);
    my $copy = copy($orig);

    push @$orig, 1;
    is($orig, [1,[2,3],4,1], '$orig after push 1');
    is($copy, [1,[2,3],4],   '$copy after push 1');

    push @$copy, 2;
    is($orig, [1,[2,3],4,1], '$orig after push 2');
    is($copy, [1,[2,3],4,2], '$copy after push 2');

    push $orig->[1]->@*, 10;
    is($orig, [1,[2,3,10],4,1], '$orig after push 3');
    is($copy, [1,[2,3],4,2],    '$copy after push 2');

    push $copy->[1]->@*, 20;
    is($orig, [1,[2,3,10],4,1], '$orig after push 3');
    is($copy, [1,[2,3,20],4,2], '$copy after push 2');
}

{
    my $orig = {
        artist => 'Michael Jackson',
        title  => 'Thriller',
        tracks => [
            {title => "Wanna Be Startin’ Somethin", duration => 363},
            {title => "Baby Be Mine",               duration => 260},
            {title => "The Girl Is Mine",           duration => 242},
            {title => "Thriller",                   duration => 357},
            {title => "Beat It",                    duration => 258},
            {title => "Billie Jean",                duration => 294},
            {title => "Human Nature",               duration => 246},
            {title => "P.Y.T.",                     duration => 239},
            {title => "The Lady in My Life",        duration => 300},
        ],
    };

    my $copy = copy($orig);
    $copy->{runtime} = $copy->{tracks}->sum_by(key 'duration');

    is(
        $orig,
        {
            artist => 'Michael Jackson',
            title  => 'Thriller',
            tracks => [
                {title => "Wanna Be Startin’ Somethin", duration => 363},
                {title => "Baby Be Mine",               duration => 260},
                {title => "The Girl Is Mine",           duration => 242},
                {title => "Thriller",                   duration => 357},
                {title => "Beat It",                    duration => 258},
                {title => "Billie Jean",                duration => 294},
                {title => "Human Nature",               duration => 246},
                {title => "P.Y.T.",                     duration => 239},
                {title => "The Lady in My Life",        duration => 300},
            ],
        },
        '$orig stays the same');

    is(
        $copy,
        {
            artist => 'Michael Jackson',
            title  => 'Thriller',
            tracks => [
                {title => "Wanna Be Startin’ Somethin", duration => 363},
                {title => "Baby Be Mine",               duration => 260},
                {title => "The Girl Is Mine",           duration => 242},
                {title => "Thriller",                   duration => 357},
                {title => "Beat It",                    duration => 258},
                {title => "Billie Jean",                duration => 294},
                {title => "Human Nature",               duration => 246},
                {title => "P.Y.T.",                     duration => 239},
                {title => "The Lady in My Life",        duration => 300},
            ],
            runtime => 2559,
        },
        '$copy has runtime added');

    # Add another Track
    $copy->push(tracks => hash(title => "Bonus", duration => 100));
    $copy->{runtime} = $copy->{tracks}->sum_by(key 'duration');

    is(
        $orig,
        {
            artist => 'Michael Jackson',
            title  => 'Thriller',
            tracks => [
                {title => "Wanna Be Startin’ Somethin", duration => 363},
                {title => "Baby Be Mine",               duration => 260},
                {title => "The Girl Is Mine",           duration => 242},
                {title => "Thriller",                   duration => 357},
                {title => "Beat It",                    duration => 258},
                {title => "Billie Jean",                duration => 294},
                {title => "Human Nature",               duration => 246},
                {title => "P.Y.T.",                     duration => 239},
                {title => "The Lady in My Life",        duration => 300},
            ],
        },
        '$orig stays the same');

    is(
        $copy,
        {
            artist => 'Michael Jackson',
            title  => 'Thriller',
            tracks => [
                {title => "Wanna Be Startin’ Somethin", duration => 363},
                {title => "Baby Be Mine",               duration => 260},
                {title => "The Girl Is Mine",           duration => 242},
                {title => "Thriller",                   duration => 357},
                {title => "Beat It",                    duration => 258},
                {title => "Billie Jean",                duration => 294},
                {title => "Human Nature",               duration => 246},
                {title => "P.Y.T.",                     duration => 239},
                {title => "The Lady in My Life",        duration => 300},
                {title => "Bonus",                      duration => 100},
            ],
            runtime => 2659,
        },
        '$copy has runtime added');
}

{
    my $orig = {
        data1 => [1,2,3],
        data2 => [4,5,6],
    };

    my $copy = copy($orig);

    is(
        $orig,
        { data1 => [1,2,3], data2 => [4,5,6] },
        '$orig stays the same');

    is(
        $copy,
        { data1 => [1,2,3], data2 => [4,5,6] },
        '$copy is a copy of $orig');

    $copy->push(data1 => 10);
    $copy->push(data2 => 20);

    is(
        $orig,
        { data1 => [1,2,3], data2 => [4,5,6] },
        '$orig stays the same');

    is(
        $copy,
        { data1 => [1,2,3,10], data2 => [4,5,6,20] },
        '$copy is modified');
}

{
    my $orig = { foo => 1, match => qr/\Aabc/ };
    my $copy = copy($orig);
    ok(equal($orig, $copy), 'Regexes can be copied');
}

# test add_copy()
my $whatever1 = bless([1,2,3], 'Whatever');
my $whatever2 = bless([1,2,3], 'Whatever');

nok(equal($whatever1, $whatever2),             'Whatever is unknown to equal');
dies { my $c = copy($whatever1) } qr/\Acopy:/, 'copy() on Whatever must fail';

# Whatever are just arrays - so we can just use array equality
Sq::Equality::add_equality('Whatever' => sub($x,$y) {
    Sq::Equality::array($x,$y);
});

is($whatever1, $whatever2, 'Whatever can now be compared');

# Implement copy of Whatever
Sq::Copy::add_copy('Whatever' => sub($what) {
    my @new;
    for my $x ( @$what ) {
        push @new, copy($x);
    }
    return bless(\@new, 'Whatever');
});

# copy is now possible
is($whatever1, copy($whatever2), 'Whatever can now be copied');

# is deep-copy and equality possible?
my $whatever3 = bless([1,2,3, bless([4], 'Whatever')], 'Whatever');
my $whatever4 = copy($whatever3);

is(
    $whatever4,
    bless([1,2,3, bless([4], 'Whatever')], 'Whatever'),
    'check recursion');

done_testing;
