---
date: "2023-02-03T16:30:00-05:00"
title: "The First Design"
tags: ["software design", "Formula 1"]
aliases:
  - /post/the-first-design/
---

When I review the code for a new program, I often provide the original authors _a lot_ of feedback.
And just as often, those authors are a little annoyed by me, the feedback, or both.
But I keep doing it for two reasons.

<!--more-->

## Professionalism

Regardless of experience or engineering level, I presume all engineers are professionals who strive to create the best possible code in _every_ aspect.
My manager uses Formula 1 racing as an analogy: F1 vehicles, drivers, teams, and engineers are the best in the world, and essentially no detail is too small to address.
The video [$5000 Normal Engine vs $10 Million Formula 1 Engine](https://www.youtube.com/watch?v=aKwSM5NTeaw) is a great explanation&mdash;watch it.
(I learned that the tolerances of an F1 engine are so precise, that its parts are seized when cold.)

That said, I fully realize that different engineers are at different points in their careers.
To put it bluntly, some engineers are (for example) preoccupied with family matters, and their job is second or third priority.
That's normal; that's fine.
But it doesn't change _my_ job.

My job is what John Ousterhout saw fit to title chapter 3 of his book [_A Philosophy of Software Design_](https://web.stanford.edu/~ouster/cgi-bin/aposd.php):

><b>Working Code Isn't Enough</b>

Seriously.

This isn't the 1990s when working code was enough and treated like magic that shall not be questioned.

Today, as I've said and written many times before, it's no longer special (or sufficient) that a person can code and make a program work&mdash;millions of software engineers can do that, just as millions of people can drive a car (to extend the Formula 1 analogy).

As software engineering _professionals_, we're hired and expected to do a lot more.
And it's my job to help teach and reach that Formula 1 level of programming.
If Formula 1 can record every single bolt in an engine&mdash;and when and how and by whom it was turned&mdash;then we're going to examine every package, every function, every block, every line, every word, every character of code until we cannot yet imagine how to engineer the program any better.

## The First Design

The first design is usually the last design of a program.

If we're making a program that we want to last for many years&mdash;and especially if we want the program to be used by a wide, general audience&mdash;then getting the design right the first time is critical for two reasons.

<p class="note">
Yes, I know all about "perfect is the enemy of good", "agile" engineering, iterating, over-engineering, premature optimization, YAGNI, and so forth.
That's why professional software engineering requires learning about and improving on delivering high-quality software really fast and from the start.
</p>

First, once a program is released, it's very difficult to claw back any features or functionality.
You can release a new major version, but then you're fighting an uphill battle: getting people to do additional work (upgrade) _and_ change how they work (new or changed functionality).
The same is true for the code itself: future engineers will be under pressure to ship something, so they'll be reluctant to redesign code that works even knowing the above: _working code isn't enough_.
Moreover, their reluctance will be supported by the second reason...

Second, future engineers will undoubtedly follow the lead of the first design.
Related to the first reason, this allows future engineers to ignore the design by claiming "I didn't design it, so I'm not going to spend time fixing or redesigning it. I'm just going to work with the existing design and ship the features I've committed to this sprint."

Deference to the first design is the origin of software rot and all the common issues with legacy code.

For example, if a program does not exhibit consistency (a primary element of design) in its arguments, then why should any future engineer care about new arguments?
They can add anything and claim that it fits with the current design, and they'd be correct.
Let's use an example:

|A  | B |
|---|---|
|`--disable-foo`|`--bar` (default: true)
|`--prefetch`|`--compress`
|`--replica-dsn`|`--foo` (default: true)
|`--skip-bar`|`--prefetch` (default: true)
|`--source`|`--replica-dsn`
|`--use-compression`|`--source-dsn`

Suppose a future engineer wants to add an argument to disable the program's API.
In column **A** they could call the new argument `--turn-off-api` and while that's a clunky name, there are no grounds to say it's wrong with respect to the design because **A** has no apparent design or consistency.
But in column **B** it's clearly wrong; it should be `--api` (default: true), meaning that the user can turn off the API by specifying `--api=false` because in this design all things that are on by default have a boolean option like `--bar` (bar is on by default), and all things _off_ by default have an option like `--compress` to turn them on.

The same reasoning holds true for _every_ part of code&mdash;right down to the code comments&mdash;because of professionalism.

Even with a spectacular first design, code quality will decrease over time and different engineers.
("Nothing lasts forever; even the stars die.")
But the greater the quality and consistency of the first design, the easier it will be to maintain and restore.
That brings us full circle: if we're making a program that we want to last for many years&mdash;and especially if we want the program to be used by a wide, general audience&mdash;then getting the design right the first time is critical.

<br>

---

<br>

When debating such topics with software engineers, some will dismiss the debate with either "it doesn't matter" or "I don't agree".

The first dismissal is patently wrong: [professionalism](#professionalism) is why it matters.
You don't have to believe me, but as a professional you should believe a professor of computer science at Stanford: John Ousterhout.
If not, then it's incumbent upon _you_ to prove why you know better than Ousterhout and others. 

The second dismissal is meaningless unless you have (and put forth) better ideas.
Show me your other code or projects where you did things differently and it worked well.
Teach me your philosophy of software design.
Recommend me a book that shows a different approach.
That's only fair since that's what I have done (in public projects and this blog) and what I continue to do.

The one dismissal that's valid is that "it's good enough for now because it's not user-facing _and_ we can change or improve it later with ease."
A well-designed abstraction is one design element that makes that possible: the abstraction provides a clean interface (or API) behind which we can hide ugly code (and fix it later).

Since we're making programs not Formula 1 engines, we have a lot more leeway to claim that the effort matters more than the outcome because a terribly designed program can run well and make the company money.
(That's not true for a terribly designed engine.)
If you're overwhelmed and out of time, it's okay to knowingly forego better design if your fellow engineers agree.
