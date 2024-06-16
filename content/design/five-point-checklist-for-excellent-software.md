---
date: "2017-09-17"
lastMod: "2024-06-05T12:11:00-04:00"
title: "Five-Point Checklist for Excellent Software"
subtitle: "Five ways to make your code excellent"
tags: ["software design", "checklist"]
aliases:
  - /post/five-point-checklist-for-excellent-software/
---

I've never met a developer who hasn't read or reviewed _a lot_ of code written by other developers. If there's one truism in the field of software of engineering it's that the process is collaborative. Unless you write and never release software, other people will read the code, and they're most likely reading it not for a fun bedtime story but because they need to understand and probably fix or modify it.

That truism profoundly affects and shapes how I view and approach software development. As my colleagues will attest, I frequently say, "write software for future engineers". If you've ever read someone else's code and found it sensible, easy to follow, logical, simple, etc. then you have felt the implication of that statement, and it feels good.

But _how_ do we write code for other people? How do we write code that won't boggle the minds of future developers? Moreover, how do we do this under the pressure of time lines, deadlines, just make it compile, etc.? Who has time for bike shedding?

<p class="note">I think "bike shedding" has become used to dismiss legitimate design and code considerations. In my humble opinion, everything matters. Bike shedding applies to issues completely outside the code. Variable naming is not bike shedding, it's attention to detail.</p>

I think developers genuinely want to write excellent software because it's human nature to take pride in a job well done. So I created this prioritized checklist which serves two purposes. First, it makes explicit what "excellent" means, in my humble opinion. It's very difficult to hit a target you cannot see. Second, as a checklist it makes it quick and easy to run through, review, and either check "yes" or "no", and if "no" then stop, think, and improve (or ask for help).

One final note: there's a lot more to learn and do than these five points. Software design exists at several levels, and many other considerations affect design. And of course we should avoid pitfalls like over-engineering, premature optimization, etc. And sometimes we're forced to work with software so poorly constructed that it's not amenable to improvements short of extensive refactoring or a full rewrite. But for day-to-day work, and in the absence of other guides, this five-point checklist helps deliver excellent software.

## 1. Single Responsibility

<mark>( ) Every pkg/class/function/etc. has a single responsibility which is ...</mark>

The [single responsibility principle](https://en.wikipedia.org/wiki/Single_responsibility_principle) is perhaps the most important principle in software engineering. Unfortunately, it seems also to be the most frequently ignored. Monolithic code, a big "ball of mud", spaghetti code, entangled code, tightly coupled code, etc.--we have a lot of phrases to describe code that combines multiple responsibilities. Software makes these easy because nothing in any language requires or forces us to do otherwise. In theory, with global variables and jump statements like `goto` all programs could be on giant `main()` function. That strikes everyone as insane, which means we accept the virtue of "single responsibility", so embrace the virtue to its fullest extent: make packages, classes, functions, and _all_ code components have a single responsibility.

For every code component, ask yourself: "What is this component responsible for?" You should be able to give a succinct, coherent answer and (short) description, which is the "..." in the highlighted checklist item above.

The component's responsibility must be necessary, but it is most likely _not_ sufficient. This is ok and expected because a single responsibility is understood in a larger context. I think this is often where and how programmers fall into writing overloaded code (i.e. code with multiple responsibilities). My guess (only a guess because I haven't conducted a survey) is that the developer feels that code X won't be useful or complete unless it also does Y and Z because X is useless without Y and Z. It's perfectly fine for the code to do X and only X--to have that single responsibility. We can make separate code for Y and Z, then tie it all together in a fourth code component that utilizes X, Y, and Z to accomplish some necessary task.

Is that over-engineering? If X is logically related to Y and Z, why not just bolt them all together? Good question! And the next checklist item is the answer...

## 2. Highly Testable

<mark>( ) All code can be tested through its public/exported API/interface</mark>

The key word is "highly". Excellent software is extensively and meticulously tested which requires that it's possible to test as such. If design precludes or makes difficult extensive and meticulous testing, then it's rarely done. Testing is, honestly, not much fun in the first place, so if it's anything less than easy to do, most of us won't do it.

Excellent software is highly testable _by design_, and designing code components with a single responsibility is the first and best way to ensure high testability.

Why? Going back to the earlier X, Y, Z example. Presuming Y and Z are operations we care about (if we don't care about them, then they shouldn't exist), if they're performed inside X, then we can't test them directly--they're not highly testable. We can only test Y and Z by way of X, which means we have to think about and account for X before we even get to the point: testing Y or Z. It means tests for X, Y, and Z are all entangled: a change to one could affect all the others. And it's not uncommon for this to simply preclude testing Y or Z because in languages that can't monkey patch code under test, the test might not be able to coordinate or control execution in X around Y or Z, especially if any kind of timing, coordination, concurrency, parallelism, etc. is involved in X, Y, or Z. In short: because X, Y, and Z are not separate, distinct code components with single responsibilities, they are not highly testable.

Furthermore, testing should be done using only public APIs. This is a very high standard, but a good one because it helps guide (or force) even cleaner, better design. If private code (whether enforced by the language or convention) cannot be tested via a public API, then what is its purpose with respect to the code component and its public API? Is it truly necessary, or is it vestigial? That word "vestigial" is useful in the biological sense. Your appendix is vestigial. It exists, but you don't need it. It doesn't hurt anything, until it does and then you must remove it or die. Code that cannot be "reached" and tested via the public API is vestigial. It's not hurting anything, until one day... If you can simply remove it, then do so. Less code with no loss of functionality is always best. If you can't remove it, then this is a strong signal that the code needs to be refactored or redesigned.

## 3. Intention-revealing

<mark>( ) All names and comments help reveal and clarify code intention<mark>

There used to be a PDF by [Dr. Chien-Chung Chan](http://www.uakron.edu/computer-science/faculty-staff/bio-detail.dot?u=chanc) that talked about programming style.
Unfortunately, as of June 2024, it's nowhere to be found on the internet, but the important quote was:

> Smart is overrated. Clarity is king. The very smart must use their talent to write code that others are less likely to misunderstand.

One thing I'd add: code comments. Good names go a long way, and good code comments go the rest of the way. The comment can be a single sentence that states the purpose of the code block. This proves time and time again to be a great resource to future developers because although we can understand the syntax and semantics of code, the original developer's intention is not always captured even by "perfect" code. For nontrivial operations, we (i.e. future devs) can always ask, "Why is this done this way and not another way?", or "Why is this done at this point and not earlier or later?", etc. The paper says of names, "Shorter names are generally better than longer ones, if they are clear. Add no more context to a name than is necessary." The same is true for code comments: shorter is better, if the comment is clear. Don't add more context than necessary. When code comments are routinely wordy, we begin to gloss over them. But if they remain succinct and intention-revealing, other devs will read and benefit from them.

## 4. Consonant

<mark>( ) Every aspect of the code looks and feels similar to existing code</mark>

Normally I call this "consistency", but "consonant" in the musical sense better encompasses the total spirit of this checklist item. Excellent code is consonant, harmonious in _all_ aspects, from high-level design, to naming, to source code formatting. The code looks like it was developed by one person, even though it was most likely the work and/or input of several people. This make consonance a difficult requirement, but it's important precisely because software is the product of several people.

Think of the opposite: code with no regard to consonance, harmony. I'm free to write code in an object-oriented fashion, following designs and principles that makes sense for object-oriented code. Another developer has a background in C and prefers simpler procedural and structural code. Another person is a front-end JavaScript dev and prefers callbacks and fully asynchronous calls. And yet another dev is a Go lang programmer and thinks more in terms of composition. Oh and everyone has differing approaches to error handling, e.g. using exceptions or not. -- If all these people work on the same system however they please, do you think the code will be easy to follow, understand, and maintain? Or will the code be a Frankenstein patchwork of styles and approaches? How do we even make such differences mesh and jive?

The issue of consonance is usually not that extreme; it's usually much smaller, reflecting different personalities and preferences rather than radically different programming languages and paradigms. Even so, consonant code matters precisely because teams are usually fair and democratic, so one person's personality shouldn't dominate at the expense of everyone else's. (This is _not_ to say there shouldn't be a leader or technical lead. A good leader leads, they don't dominate.) Therefore, write code that looks and feels like existing code. Keep every aspect of the system consonant.

And what if the existing code "sounds" terrible and we want to change it? Great! Do it. The point is not to avoid refactoring or improvements, the point is to avoid a rat's nest and labyrinth of styles that impedes understanding the code. The point is to have everyone sing in the same key, until we decide to change the key.

Final note on consonant code: write idiomatic code. Idiomatic code is consonant with the language itself and its community. Of course, a team can decide to do otherwise, to take a different approach with the language. In general, however, writing code in a language as the language intends makes it _much_ easier for future developers to understand.

## 5. Details

<mark>( ) No code is perfect, but I am proud of this code</mark>

Developers are busy and pressured to deliver. On top of just shipping the requested features and whatnot, thinking about good design and clean code can be daunting. Hopefully this checklist, so far, helps by distilling critical aspects of excellent software to check. The final checklist item is simply "details", as in attention to details--_all_ details. 

This checklist item is intended to counter arguments like "bike shedding" or "yeah, but who cares, the code works", etc. While true that small details don't usually affect if or how the code runs, they're a psychological matter of pride in one's craftsmanship. 

Have you ever gotten a pint of beer that was overfilled so it ran down the side of the glass, and the bartender gave it to you just like that? Wonderful. Here's a wet, sticky pint glass. They could have wiped it off, but no.

Life, like code, is full of details that reveal if the other person or people genuinely care or not. I don't remember where I heard this adage but: "It's not the job you do, it's how you do it."

Why does this matter? Read [We Don't Sell Saddles Here](https://medium.com/@stewart/we-dont-sell-saddles-here-4c59524d650d). There's a lot of good points in that memo, but wrt details I want to call out:

> Life is too short to do mediocre work and it is definitely too short to build shitty things.

This checklist is about _excellent_ software, software to be proud of, software that other, future developers will read and understand and think, "Yeah, this makes sense. This is great." Every detail matters.
