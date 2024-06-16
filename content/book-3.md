---
type: "page"
date: "2022-03-19T16:04:00-04:00"
title: "Performance Is Less"
subtitle: "Chapter 3"
tags: ["mysql", "book", "efficient-mysql-performance", "philosophy"]
comments: true
aliases:
  - /post/book-3/
disqus_url: "https://hackmysql.com/post/book-3/"
---

Is MySQL performance about "more" or "less"? From the title, you can tell that I'm going to argue that it's about "less". Here's the punchline: zero is maximum performance. Let's see where this philosophical blog post leads us.

<!--more-->

<p class="note">
This blog post is the fourth of eleven: one for the preface and ten for each chapter of my book <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a>.
The full list is <a href="/tags/efficient-mysql-performance/">tags/efficient-mysql-performance</a>.
</p>

## Backdrop

Chapter 3 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) covers data.
In the book I write that "data is dead weight to MySQL"; here's the proof: `TRUNCATE TABLE` makes every query on the table take nearly zero seconds&mdash;super fast! amazing performance!
Of course, that's a joke (do not truncate your tables).
Nevertheless, it proves the point: without data, MySQL is blazing fast.
The more data you saddle MySQL with, the longer it takes to churn through that data to execute queries.
Yes, indexes help _a lot_, but that's covered in chapter 3 (with lead-in from chapter 2 and carry over to chapter 4).
Data is dead weight to MySQL; it's only meaningful to _you_.

## More

Clearly, we want _more_ performance from MySQL&mdash;from hardware and software in general.
This tends to focus the mind on achieving _more performance_ in order to yield more output&mdash;a simple relationship like:

![More Performance, More Output](/img/perf_output.svg)

We need the database to _do more work_ (output), so we try to increase performance in terms like:

* More QPS (throughput)
* More transactions per second (TPS)
* More IOPS
* More RAM (efficiently; not wastefully)
* Support +300% more users

And while it's true that more performance leads to a system doing more work, this simple focus is the brute force approach.
It's like leaving a window open in winter, the house gets cold, and to warm up you turn up the heater.

It is better to see performance as a function of efficiency and work:

![Performance as a Function of Efficiency and Work](/img/perf-efficiency-work.svg)

Do not focus on performance _qua_ performance; focus on the application workload and efficiency.
_Workload_ is the combination of queries, data, and access patterns.

In simple terms: efficiency increases performance; but work decreases performance.
You can offset increasing work by increasing the efficiency of that work.
If you don't&mdash;if you increase work without increasing efficiency&mdash;the extra work will figuratively drag down (decrease) performance.
The best way to achieve _remarkable_ performance gains is to increase efficiency _and_ reduce work.

Unsurprisingly, this is the approach taught in [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance): increase efficiency and reduce work.
And although I've said that "efficient" in the title refers to "focus", it also refers to this approach, which is the most efficient way to increase MySQL performance.

## Less

Like many engineers, I often want _more_ from computers in general, not just MySQL.
But I have to remind myself that the real challenge and ultimate goal is less of everything: less CPU and energy, less RAM, less IOPS, store less data, access and return less data.
Zero is the ultimate challenge and goal: no data, no work, no application, no energy, no worries.

> Any intelligent fool can make things bigger, more complex, and more violent. It takes a touch of genius&mdash;and a lot of courage to move in the opposite direction.<br>&mdash;E. F. Schumacher

In an era of big data, data analytics, and cheap, nearly limitless storage, I realize how counterintuitive and perhaps wrong this seems.
I see many articles about how such-and-such problem was solved or new insight gained by crunching a ton of data.
In certain fields, maybe more data is better.
But more often I see "big wins" when teams dramatically reduce data and work while still doing the same business function.
Just this week, a team announced a huge migration _off_ MySQL to a data store that is faster and more efficient with less data.
By contrast, there is another team that's struggling under the weight of its data and work, and they dream of a day where everything is less&mdash;especially _far less_ stress and pressure on them to keep the lights on.

Instead of always thinking about performance as "more", I advise engineers to start with and focus on "less": what can you reduce or eliminate? how can you increase efficiency (which means leas waste)? does some work truly need to be done?

In accordance with the E. F. Schumacher quote above, any engineer can make databases bigger and more complex, but it takes a touch of genius&mdash;and a lot effort&mdash;to move in the opposite direction.
Performance is making and doing less of everything until all is eliminated.
I am happy when engineers achieve "big numbers" with MySQL, but I'm truly impressed when they optimize to zero.
