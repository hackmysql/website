---
date: "2024-04-20T01:00:00-04:00"
title: "Lessons From 20 Years Hacking MySQL (Part 2)"
subtitle: "Philosophy"
tags: ["mysql", "philosophy", "history", "business"]
comments: true
draft: true
---

A relational database is more than a data bank, it's a profound philosophical expression.
This is the second and final part of "Lessons From 20 Years Hacking MySQL".

<!--more-->

## Success anchors to value

In [Part 1: Randomness]({{< ref "lessons-from-20-years-hacking-mysql-part-1" >}}), I mention success and value but I don't explicitly state the lesson: _success anchors to value_.

That's important because randomness can be a turbulent sea of changes and challenges.
Amid the chaos, what do you focus on&mdash;what do you anchor to?
Answer: creating or providing _value_.

MySQL exemplifies this lesson: despite all the changes, it has always provided tremendous value as a relational database that’s fast, free, open source, easy to use, very well documented, and continually improved. 
Its value has been so steady that I often forget that MySQL AB (the original company) existed for less than half of its history: 13 of 29 years.
The value it provides is so indelible that none of the changes over the last 29 years have erased it.

Early on in my career I didn't know the staying power of value.
I just got lucky that I happened to create some value.
Fun fact: `mysqlreport` still gets a lot of hits even though it was retired and remove over 10 years ago.

Today, when I find myself in the churn, I ask myself "How can I add _value_?"

The answer changes with time, experience, opportunities, and so forth.
Generally speaking, the further along in your career, the more _impact_ your can have, and greater impact leads to greater value.
During my entire tech career, I've observed and learned three sure-fire ways to increase your impact and value:

1. Deliver quality
1. Keep learning
1. Teach others

The last two points are mostly self-explanatory, so I won't belabour them.
The first needs a bit of clarification.

Putting aside the fact that quality is often subjective for software, what matters most is the _intentional effort_ to deliver quality.
I rarely find that intentional effort in other software engineers.
When I ask or bring up the issue, the reply is almost always dismissive, like "It's good enough" or "Yeah but is anything _technically_ wrong?"

I think the tech industry is at a turning point.
For the past 30 years (back to the 1990s), merely being able to program&mdash;to deliver working code&mdash;was a path to success.
But the party ended with a final hurrah from 2020&ndash;2022: the pandemic-era tech hiring frenzy and stock bubble.

Now the opposite is sweeping the industry: massive layoffs, limited jobs, tough competition, and&mdash;to top it all off&mdash;_reduced_ total compensation.

I predict that the next 30 years of tech will favor those who put in intentional effort to deliver quality code and programs in every aspect.
Not only is coding a commonplace skill that even children are taught, but AI is learning to code, too.
If coding is no longer the differentiator, then what is?
Quality.
Quality has been in demand for centuries.
Quality will always be in demand.

<div style="text-align:center">&mdash;&sect;&mdash;</div>

There's another way to increase your impact and value, but it's a special case:

4. Lead people to success

Have you ever wondered why managers can be paid more than software engineers who write the code that creates the product?
First of all, watch [Why Experience Doesn't Get You to the Top](https://www.youtube.com/watch?v=OPiXobBnCKI) by Dr. Grace Lee.
Answer: leading people to success is really difficult.

I wish it wasn't true but, now with the benefit of 20+ years of hindsight, I attest that most of the impedance in business is due to people, not technology.

Nothing is faster than a lone hacker working unimpeded.

But a lone hacker doesn't scale.
Monty is generally considered "the" creator or MySQL, but he didn't write all the code&mdash;not even close.
(The InnoDB storage engine was originally created by Heikki Tuuri, for example.)
I'm generally considered "the" creator of pt-online-schema-change (and other tools), but I built on code and ideas from others.
Even the legendary game _Doom_ needed three programmers.

It's a paradox: people slow things down, but people are needed to get things done.
Being able to solve that paradox&mdash;to lead people to success&mdash;is a difficult yet lucrative skill that creates immense value.

## Dig until you find the answer

I remember the first MySQL performance problem that I solved for a customer.
I wrote it up and published it on this website as "Case 1: Indexing Basic MySQL Queries".
It started like this:

> "Why is the server so slow?" That's what a customer was asking in regards to her server with dual 2.8 GHz Xeon CPUs and 3G of RAM. Her primary website was a bulletin board with over 25,000 registered users and 151,000 posts. Not a huge site, but extremely high bandwidth due to 62,000 files totaling 110 Gigs which were all uploaded and accessed with the attachment mod for php.
> <br><br>
> When I started working on this server a load of 200 was not uncommon, and MySQL was always the culprit. The basics all checked out: plenty of server capacity, normal MySQL and Apache configs, no hardware or network problems. However, one thing kept showing up: a slow query.

Long story short: missing index on a critical query.
Add the proper index and voilà: performance problem solved.

Simple.

But twenty years ago, when I started working on that problem, I was:

```
[*         ] Knowledge
[**********] Effort
```

Very little knowledge but maximum effort.
I remember thinking to myself "I have no idea how to solve this problem but there _must_ be an answer&mdash;it's just a computer. I'll dig until I find it."
Being open source (both MySQL and the customer's application) I knew, worst case, I could delve into the source code.
(And I did, in fact.)

That kind of effort is rare.
But I get it: work often has lots of demands, and there's probably not much incentive for such effort.

But I also know that I'm not alone.
I'll tell you a funny story that I don't think Peter Zaitsev will mind me sharing.

Peter and Vadim, like most early Percona employees, defaulted to maximum effort.
We were passionate about MySQL and MySQL performance, so we always dug&mdash;all the way to bedrock.
At some meeting, Peter was extolling the importance of this effort, and he meant to say "Dig in layer by layer".
But it sounded like he said "Dig in lawyer by lawyer."
T-shirts were made up with his face saying this.

Again, I get it: probably not much incentive to put in this kind of effort today.
...
But if you choose to, it's worth it because you will be rewarded for the effort: money, freedom, opportunities, fame.
Maybe not a lot of these, but more than most.

But the most meaningful reward for hackers&mdash;people who dig until they find the answer&mdash;is the knowledge gained.
I've yet to figure out why some people are compelled to dig and why _knowing_ is so important and rewarding for them.
I wonder if it's a personality trait, a sort of psychological disposition, or if it's something that can be taught or acquired?
I do know, however, that hackers exist in all fields of study.
My late mentor spent his life digging and finding answers about André Malraux et autres sujets français.

The world is always in desperate need of hackers.
Deep answers&mdash;bedrock answers&mdash;move industries forward and sometimes change the world.
I highly encourage you to become a hacker and dig deep into fields of study that interest you.

## Make difficult things easy

If you learn or take away nothing else from this or [Part 1: Randomness]({{< ref "lessons-from-20-years-hacking-mysql-part-1" >}}), let it be this lesson: _make difficult things easy_.

Step back 54 years to 1970 when Codd published the remarkably short paper that started it all: [A Relational Model of Data for Large Shared Data Banks](https://dl.acm.org/doi/10.1145/362384.362685).
And four years later Chamberlin and Boyce published [SEQUEL: A Structured English Query Language](https://dl.acm.org/doi/10.1145/800296.811515).

I expected those papers to be long and dense.
But they're surprisingly short and light.
Half a century later, what they created is not only relevant but a foundation of the world.
Proof that difficult things made easy is powerful and enduring.

And it wasn't by accident.
Codd starts by talking about how future engineers will need an easier system, and how the network data model create difficulties.
Likewise, Chamberlin and Boyce also call out how the SQUARE language is not easy to use.
(SQUARE is ridiculously cryptic, in my humble opinion.)
The relational data model and SEQUEL were easy 50+ years ago and still easy today.

MySQL did the same for web developers and programmers in general.
It's become more complicated (as tech products often do), but 20 years ago it was so easy that anyone with basic programming or sysadmin skills could use it.
Simplicity is how and why MySQL became the world's most popular open source database.

But since all ACID-compliant RDMS are inherently complex (true durability at scale is not easy), even the simplest database server needs tools to help the user manage it.
That's the story of my career: MySQL tools.
Tools don't just make difficult things easy, they make difficult things _possible_ for humans.
Nobody can parse a 10 GB slow query log by hand and eye.

From the relational model and SEQUEL to MySQL to my tools, the underlying lesson is the same: make difficult things easy.

Philosophically, I'd argue that this is all anyone is ever doing with computers, why humans invented computers in the first place: to make difficult calculations easier (and faster).
Apple made it easy to use a personal computer.
Netscape made it easy to browse the internet.
Google made it easy to find what you want.
Facebook made it easy to connect with friends and family.
Netflix made it easy to watch movies.
Square made it easy to take credit card payments.

Time and time again this formula wins: _make difficult things easy_.

Look around you and ask "What's difficult?"
Then imagine a world and way in which people are doing that easily.
Build that vision and change the world.

MySQL did.
You can too.

<br>

---

## Epilogue

Words belie the gratitude I have for Monty, Peter, Vadim, and Baron.
Many people helped me on this journey, but you four were the foundation on which I built my career with MySQL and, by extension, my life.
When you met me, I was a poor kid living in a small town in the middle of nowhere.
Today, I'm doing great, and I try to remain a kid at heart so I don't lose the curiosity and cleverness of young a hacker who, 20 years ago, worked 10-hour shifts at a data center then went home to learn more and write tools until his next shift.
Thank you.

I still love hacking MySQL.
Ironically, it took me almost 20 years to realize why: the relational model is an application of first-order predicate logic.
(I have a bachelors degree in philosophy.)
[_Database In Depth_](https://www.oreilly.com/library/view/database-in-depth/0596100124/) by C. J. Date taught me this.
Now it all makes sense: it's not just data, it's ontology and epistemology.
<mark>Relational data models what _exists_ and what is _true_ about it.</mark>

MySQL is applied philosophy.
