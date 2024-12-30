# Preface

A well-known saying in the programming racket is that a good Fortran pro-
grammer can write Fortran programs in any language. The sad truth, though,
is that Fortran programmers write Fortran programs in any language whether
they mean to or not. Similarly, we, as Perl programmers, have been writing C
programs in Perl whether we meant to or not. This is a shame, because Perl is
a much more expressive language than C. We could be doing a lot better, using
Perl in ways undreamt of by C programmers, but we’re not.

How did this happen? Perl was originally designed as a replacement for C
on the one hand and Unix scripting languages like Bourne Shell and awk on
the other. Perl’s ﬁrst major proponents were Unix system administrators, people
familiar with C and with Unix scripting languages; they naturally tended to write
Perl programs that resembled C and awk programs. Perl’s inventor, Larry Wall,
came from this sysadmin community, as did Randal Schwartz, his coauthor on
Programming Perl, the ﬁrst and still the most important Perl reference work.
Other important early contributors include Tom Christiansen, also a C-and-
Unix expert from way back. Even when Perl programmers didn’t come from the
Unix sysadmin community, they were trained by people who did, or by people
who were trained by people who did.

Around 1993 I started reading books about Lisp, and I discovered something
important: Perl is much more like Lisp than it is like C. If you pick up a good
book about Lisp, there will be a section that describes Lisp’s good features.
For example, the book Paradigms of Artiﬁcial Intelligence Programming, by Peter
Norvig, includes a section titled What Makes Lisp Different? that describes seven
features of Lisp. Perl shares six of these features; C shares none of them. These
are big, important features, features like ﬁrst-class functions, dynamic access to
the symbol table, and automatic storage management. Lisp programmers have
been using these features since 1957. They know a lot about how to use these
language features in powerful ways. If Perl programmers can ﬁnd out the things
that Lisp programmers already know, they will learn a lot of things that will make
their Perl programming jobs easier.

This is easier said than done. Hardly anyone wants to listen to Lisp pro-
grammers. Perl folks have a deep suspicion of Lisp, as demonstrated by Larry
Wall’s famous remark that Lisp has all the visual appeal of oatmeal with ﬁngernail
clippings mixed in. Lisp programmers go around making funny noises like ‘cons’
and ‘cooder,’ and they talk about things like the PC loser-ing problem, whatever
that is. They believe that Lisp is better than other programming languages, and
they say so, which is irritating. But now it is all okay, because now you do not
have to listen to the Lisp folks. You can listen to me instead. I will make sooth-
ing noises about hashes and stashes and globs, and talk about the familiar and
comforting soft reference and variable suicide problems. Instead of telling you
how wonderful Lisp is, I will tell you how wonderful Perl is, and at the end you
will not have to know any Lisp, but you will know a lot more about Perl.

Then you can stop writing C programs in Perl. I think that you will ﬁnd it
to be a nice change. Perl is much better at being Perl than it is at being a slow
version of C. You will be surprised at what you can get done when you write Perl
programs instead of C.
