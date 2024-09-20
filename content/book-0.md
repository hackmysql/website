---
type: "page"
date: "2021-12-27T09:30:00-05:00"
title: "Efficient MySQL Performance"
subtitle: "Preface"
tags: ["mysql", "book", "efficient-mysql-performance"]
comments: true
aliases:
  - /post/book-0/
disqus_url: "https://hackmysql.com/post/book-0/"
series: "Behind the Book"
params:
  zeroIndex: true
---

After 17 years with MySQL, I wrote a book: [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance).

I'll make a bold claim: a MySQL book like this has never been written&mdash;not even close.
The preface explains why this book is unique:

<!--more-->

<img id="book-cover" src="/img/book/efficient-mysql-performance-cover.png" class="withshadow c33">

> A gap in MySQL literature exists between basic MySQL knowledge and advanced MySQL performance.
> There are several books about the former, and one book about the latter: _High Performance MySQL_, 4th Edition, by Silvia Botros and Jeremy Tinley (O'Reilly).
> This is the first book to bridge the gap.
> <br><br>
> The gap exists because MySQL is complex, and it’s difficult to teach performance without addressing that complexity—the proverbial elephant in the room.
> But engineers using (not managing) MySQL should not need to become MySQL experts to achieve remarkable MySQL performance.
> To bridge the gap, this book is unapologetically efficient—pay no attention to the elephant; it’s friendly.
> <br><br>
> _Efficient_ MySQL performance means _focus_: learning and applying only the best practices and techniques that directly affect remarkable MySQL performance.
> Focus dramatically narrows the scope of MySQL complexity and allows me to show you a much simpler and faster path through the vast and complex field of MySQL performance.
> The journey begins with the first sentence of chapter 1, "Performance is query response time."
> From there, we move fast through indexes, data, access patterns, and a lot more.
> <br><br>
> On a scale of one to five—where one is an introduction for anyone, and five is a deep dive for aspiring experts—this book ranges from three to four: deep, but far from the bottom.
> I presume that you’re an experienced engineer who has basic knowledge of and experience with a relational database (MySQL or otherwise), so I do not explain SQL or database fundamentals.
> I presume that you’re an accomplished programmer who is responsible for one or more applications that use MySQL, so I continually reference _the application_ and trust that you know the details of _your application_.
> I also presume that you’re familiar with computers in general, so I talk freely about hardware, software, networks, and so forth.

This blog post is the first of eleven: one for the preface and ten for each chapter of the book.
These blog posts are my thoughts and musings "behind the book"&mdash;what wasn't printed.

## Accomplished Engineers

I wish more books like _Efficient MySQL Performance_ were written.
When I'm feeling overly proud, I think to myself: "This is an entirely new _genre_ of tech book!"
But that's too bold a claim, so I don't say it aloud.
I think it, however, because I've spent my entire young-adult and adult life reading tech books, and I cannot think of any tech book like this one.

In my opinion, the field of MySQL books is dominated by three genres: basic, advanced, and howto.
Basic MySQL books are obvious: everyone needs an introduction, a starting point.
Advanced MySQL books are useful for high-level engineers (e.g. engineering leads), DBAs (new or aspiring), and MySQL experts who want a capstone for their career.
Howto MySQL books are often either how to operate MySQL (for DBAs) or how to use MySQL as a product (e.g. how to query MySQL).

Ironically, perhaps, those three genres do not address the largest and&mdash;I would argue&mdash;most important audience: accomplished engineers using MySQL for their application.
The keyword is "accomplished": these engineers know all the basics&mdash;they've probably been programming and using various data stores for years&mdash;so they know what they're doing in general.
Their area of expertise and responsibility is their app, not MySQL.
But since the app uses MySQL, they need to ensure that MySQL "Just Works"&mdash;is fast and trouble-free.
To that end, they want (or need) to know more about MySQL but only insofar as necessary for their app.

That makes senses.
We all use technologies in which we don't have the time or inclination to become experts.
We just want the tech to work.
MySQL is this tech for countless software engineers.

For MySQL, engineers need a book that starts at their level (accomplished) and leads straight to their goal ("Just Works" for their app).
No background info; no review of the basics; no material that's not directly applicable or actionable.
Straight to the point: _what do I **need** to know and do to make my application as fast as possible with MySQL?_

[_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) is that book.

## Welcome to the Jungle

After writing this book, I have a pretty good idea why none like it exist: it's very difficult.
Not the writing&mdash;that was relatively easy&mdash;but clearing a path through the proverbial jungle that is MySQL performance.

MySQL experts know that performance can be a very complex and subtle matter.
Sure, sometimes MySQL performance is dead-simple: missing index &rarr; table scan &rarr; app outage.
You don't need to know much about MySQL to solve that problem.
But busy apps don't tend to have simple problems, which is how they were able to scale up and become busy in the first place: by avoiding simple mistakes.

Solving a realistic performance problem means searching the jungle.
The cause and solution could be anywhere in there&mdash;watch out for pitfalls and don't follow red herrings.

But even at the outset, engineers know that that search is not feasible&mdash;it's not efficient&mdash;because MySQL is a vast and complex system, not all of which is documented.
Even searching the internet for answers isn't much help because accomplished engineers know that their database problems are related to their app, data, and queries.

You need a destination to make progress.
The destination doesn't make the jungle any less wild, but it provides focus: advance toward the destination; ignore the rest (for now).

Focus yields efficient effort (less wasted time), hence the title of the book.

I think it's safe to say that for every OLTP database, _query response time_ is the destination.
You want MySQL to execute queries as fast as possible.
It's that simple.
(In chapter 1, I explain why.)

If we're focused on improving response time (i.e. _reducing_ it, which means queries execute faster), then what's the first and most important subject to address?
I think most experts will agree: indexes.
Not surprisingly then, chapter 1 covers response time, and chapter 2 covers index.
But since this isn't a basic MySQL book, these chapters go deep quickly&mdash;but not too deep&mdash;because it's a big jungle; waste no time.

## Paths to Goals

But it's not enough to merely write technical stuff.
If you want _a lot_ of deep technical writing, then read the [MySQL Manual](https://dev.mysql.com/doc/refman/8.0/en/).
(If I recall correctly, Bill Karwin once told me that it would be over 1,000 pages if printed.)

I've read countless technical books, and most convey knowledge; very few _teach_.

Conveying knowledge, while important, is like a brain dump, like the author is saying, "Know this, this, and this. And this is how that works."
And the reader is expected to "connect the dots" or "put it together" in their mind to make the knowledge applicable.
In short, the book focuses on and stops at mere knowledge.

Teaching shows a path to a goal and helps you learn how to walk it.
This is what I strived to do in _Efficient MySQL Performance_.
(Even the jokes and puns serve a purpose: little mental breaks so that, hopefully, the reading is fun and refreshing.)
Although the book is full of deep technical content, that's not how (or where) I see its primary value.
Its primary value is how methodically it teaches: the whole book, from chapter 1 to 10, is a meticulously crafted lesson that deepens and expands your understanding of MySQL as you progress toward a single goal: improving query response time.

In the vastness of MySQL, improving query response time seems like a goal that's too small or simplistic.
Can MySQL performance really be that simple?
For most engineers who use MySQL: yes, it's really that simple.
But that doesn't mean the path is simple: MySQL performance _is_ complex.
_Efficient MySQL Performance_ is a little over 300 pages because there's a lot to learn about response time.

## Bold Claims

I am certain that [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) leads to success with MySQL.
That's another bold claim, but I see and repeat its lessons almost every week to a new engineer, a new team, or a new app.
And I see my DBA colleagues do the same.

Last bold claim: everything in this book is _required knowledge_ for software engineers using MySQL.
Seriously: if you're responsible for an application that uses MySQL, read this book.
It takes a few hours, but it teaches you _years_ of knowledge and skills that you can immediately apply.

## Thank You

Thank you to the MySQL experts who reviewed this book: Vadim Tkachenko, Frédéric Descamps, and Fernando Ipar.
Thank you to the MySQL experts who reviewed parts of this book: Marcos Albe, Jean-François Gagné, and Kenny Gryp.
Thank you to many other MySQL experts who have helped me, taught me, and provided opportunities over the years: Peter Zaitsev, Baron Schwartz, Ryan Lowe, Bill Karwin, Emily Slocombe, Morgan Tocker, Shlomi Noach, Jeremy Cole, Laurynas Biveinis, Mark Callaghan, Domas Mituzas, Ronald Bradford, Yves Trudeau, Sveta Smirnova, Alexey Kopytov, Jay Pipes, Stewart Smith, Aleksandr Kuzminsky, Alexander Rubin, Roman Vynar, and—again—Vadim Tkachenko.

And thank you, Monty.

MySQL has been a fantastic career and livelihood for me.
For many of us (myself included), it's also been a notable part of our personal lives, too.
I am grateful for your help, support, encouragement, and all the experiences we have shared.
