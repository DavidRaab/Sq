# Release to CPAN?

Will this module be realesed to CPAN? I wanted to Release to CPAN,
but at the moment i have lost interest in it. First I wanted to realease
`Seq` to CPAN. But somebody used and deleted that module.

Even that nobody uses it made the name acquired by somone, so nobody else
can use it anymore. Obviously whoever used that doesn't respond to
E-Mails anymore. He could give me the right, but no respone. So I renamed 
everything to `Sq` as the whole administration for maybe changing that 
seems not worth it.

But again, at that time I also started to add more stuff to it, instead of just
being a sequence.

Now it has become more like it's own language with a lot of stuff added
and enhanced to the Standard Perl.

One thing i am doing is for example directly use `Array`, `Hash`, `Heap`
and so on. Why? Because writing `Sq::Collections::Array->init` would be
horrible. Nobody wanna use that.

But again. It seems prohibited to use a distribution that has `package Array`
in it. Now there are several workarounds for this.

At this moment for example I put my collections into `Sq::Collections::Array`
and when loaded it just export it to `Array`. I guess this would be conform
because you always can load, add or change functions in other packages and
export to any module. This is also sometimes named monkey-patching.

Another way how to solve it is to export a function named `Array`.

```perl
sub Array :prototype() {
    return 'Sq::Collections::Array';
}
```

With such a function you could write.

```perl
Array->init()
```

and it would dispatch to `Sq::Collections::Array` and everything is fine.

There is only one problem with this. I need to go through all my source code
and change any blessing I have so far and replace them with `Sq::Collections::Array`.
This is annoying at the moment, but still possible.

But the biggest problem is that someone again already has `SQ` for a module.
I thought that upper/lowercase would be different, but it isn't. So I
again need another name for my module before I can realease anything to CPAN.

So yeah, lost interest in releasing to CPAN at the moment. Maybe it's okay,
because I anyway make stuff like using Array/Hash/Heap/Option all names
registered and not used at CPAN, so people want to prohibit that.

So when I want to Release I anyway need a new name as `Sq` isn't usuable.
So at the moment I don't care about that. I develope this module further
and add it with features I want until I think it is complete enough. Maybe
when I reached that stage I will release it to CPAN under a new name, until
then, it won't happen so soon.

As anyway nobody is using this module except me it isn't so much of a trouble.
