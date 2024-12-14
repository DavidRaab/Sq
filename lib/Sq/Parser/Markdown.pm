package Sq::Parser::Markdown;
use 5.036;

# I prefer writing all my documents in Markdown. Markdown started in
# Perl as a program that directly transforms Markdown to HTML. Markdown
# has nearly become the defacto standard for Programmers.
#
# It's used everywhere. From GitHub, usually projects/Wikis that
# i have worked with. It's very similar to POD. But it's syntax
# is more leightweight.
#
# I searched sometimes for a Markdown Parser in Perl, but didn't really
# found one. Consider that a Parser just "Parses" and returns a
# data-structure representing the input. It doesn't directly produce
# an output like HTML or other stuff.
#
# Having a parsed data-structure means you can create multiple target
# outputs easily, but also extend it with many other features. That's
# also what i needed. As i wanted to have for example a Markdown
# Parser that can be extended with it's own commands for embetting/extending
# other stuff from tables, youtube, gists, code formating, output embedding
# of runned code .....

1;