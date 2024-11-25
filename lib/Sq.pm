package Sq;
use 5.036;
our $VERSION = '0.006';
use Scalar::Util ();
use Sub::Exporter -setup => {
    exports => [
        qw(id fst snd key assign is_str is_num sq),
        Some => sub { \&Option::Some },
        None => sub { \&Option::None },
        Ok   => sub { \&Result::Ok   },
        Err  => sub { \&Result::Err  },
    ],
    groups => {
        default => [qw(id fst snd key assign is_str is_num Some None sq Ok Err)],
    },
};

# Load Basic Data Types
use Sq::Core::Option;
use Sq::Core::Result;

# Load Collections Modules
use Sq::Collections::Hash;
use Sq::Collections::Array;
use Sq::Collections::Queue;
use Sq::Collections::List;
use Sq::Collections::Seq;
use Sq::Collections::Heap;

# IO
use Sq::Io;

# Important functions used in FP code. So adding them.
sub id  :prototype($) { return $_[0]    }
sub fst :prototype($) { return $_[0][0] }
sub snd :prototype($) { return $_[0][1] }

# a helper to create a function for selecting a hash-key
sub key :prototype($) {
    my $name = $_[0];
    return sub($hash) { return $hash->{$name} };
}

# allows writing a code block to create a value
sub assign :prototype(&) {
    return $_[0]->();
}

sub is_str :prototype($) {
    return ref $_[0] eq '' ? 1 : 0;
}

sub is_num :prototype($) {
    return Scalar::Util::looks_like_number($_[0]);
}

# recursively traverse a data-structure and add Array/Hash blessings
sub sq($any) {
    my $type = ref $any;

    # Add Array/Hash blessing to current ref
    CORE::bless($any, 'Array') if $type eq 'ARRAY';
    CORE::bless($any, 'Hash')  if $type eq 'HASH';

    $type = ref $any;
    # recursively go through each data-structure
    if ( $type eq 'Option' ) {
        sq($any->[0]) if @$any;
    }
    elsif ( $type eq 'Array' ) {
        for my $x ( @$any ) {
            sq($x);
        }
    }
    elsif ( $type eq 'Hash' ) {
        for my $key ( keys %$any ) {
            sq($any->{$key});
        }
    }
    else {
        # Do nothing for unknown type
    }
    return $any;
}

# Access to Sq::Io
sub io($class) { return 'Sq::Io' }

1;

=head1 NAME

Sq - The Sq language

=head1 SYNOPSIS

What is a programming language? The foundation of every programming language
are the data-structures the language provides you by default. The default
data-structures and their possibilites shape how you will build a solution.

Sq is a module that provides certain data-structures. Those data-structures
are meant as a replacement for the built-in Perl data-structures. But replacing
those data-structures will change the way how you code.

Sq provides an immutable lazy sequence as its core data-structure (Seq),
an immutable list (List), mutable Array (Array) and a mutable Queue (Queue).

Those data-structures will share the same API as much as possible.

Besides the above it will also provide a (Record) as an immutable Hash and
Discriminated Unions.

Instead of classes, typing is done with an Structural Typing approach. This
can be used as an argument validator or even as a testing tool.

Sq don't invent new syntax, it just uses Perl as much as possible. It
is also implemented in pure Perl so far.

Besides just data-structures the idea of Sq is to have a certain high-level
API for basic programming tasks. An easier API for doing all kinds of
File System operations or reading and writing from files like CSV or JSON that
uses the data-structures of this module.

=head1 IMPORTED FUNCTIONS

=head2 sq($any) : $any

Recursively traverses through a data-structure and adds Array/Hash blessings to
the data-structure. Also traverses into Option values.

    my $album = sq {
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

    # 3
    my $length = $album->length;

    # 2559
    my $album_runtime = $album->get('tracks')->map(sub ($tracks) {
        $tracks->sum_by(key 'duration');
    })->or(0);

    # same as
    my $album_runtime = 0;
    my $tracks = $album->{tracks};
    if ( defined $tracks ) {
        for my $track ( @$tracks ) {
            $sum += $track->{duration};
        }
    }

=head2 is_num($str) : $bool

returns a truish value if C<$str> is a number.

=head2 is_str($str) : $bool

returns a truish value if C<$str> is a string.

=head2 Some($x) : $opt_x

Creates an optional value containing $x. See L<Sq::Core::Option>.
The value C<undef> returns C<None>.

    my $opt = Some(10);         # Some(10)
    my $opt = Some(Array->new); # Some([])
    my $opt = Some(undef);      # None

=head2 None : $opt

Creates an optional value that indicates the absence of any value.

    my $opt = None();
    my $opt = None;

=head2 Ok($x) : $result_x

Creates a value that additionally contains the information of beeing
sucessful/valid/ok. See L<Sq::Core::Result>. This is very similar to C<Some>.
The difference is that the B<Err> case also can contain a value.

    my $result = Ok(10);
    my $result = Ok([]);
    my $result = Ok("data found");

=head2 Err($x) : $result_x

Creates a value that additionally contains the information of beeing
an error.

    my $result = Err(10);
    my $result = Err([]);
    my $result = Err("data not found");

=head2 id($x) : $x

return its input as-is

    sub id($x) { return $x }

=head2 fst($array) : $x0

return the first element of an array

    sub fst($array) { return $array->[0] }

=head2 snd($array) : $x1

return the second element of an array

    sub snd($array) { return $array->[1] }

=head2 key($name) : $f_key_of_hash

returns a function that selects the specified key from a hash.

    sub key($name) { sub($hash) { return $hash->{$name} } }

=head2 assign

This allows you to easily create a new scope where you can defined
temporarily variables. The last expression of C<assign { ... }> is
returned.

    my $value = assign {
        my $x = ...  # code to compute $x
        my $y = ...  # code to compute $y
        $x + $y;
    };

Same as

    my $value;
    {
        my $x  = ...  # code to compute $x
        my $y  = ...  # code to compute $y
        $value = $x + $y;
    }

=head1 AUTOMATICALLY LOADED MODULES

=over 4

=item L<Sq::Core::Option>

=item L<Sq::Core::Result>

=item L<Sq::Io>

=item L<Sq::Collections::Seq>

=item L<Sq::Collections::Array>

=item L<Sq::Collections::Hash>

=item L<Sq::Collections::Queue>

=item L<Sq::Collections::List>

=item L<Sq::Collections::Heap>

=back
