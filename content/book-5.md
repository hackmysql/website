---
type: "page"
date: "2022-05-20T19:00:00-04:00"
title: "I Don't Want to Shard (MySQL)"
subtitle: "Chapter 5"
tags: ["mysql", "sharding", "newsql", "philosophy", "book", "efficient-mysql-performance"]
comments: true
lastMod: "2024-06-04T13:14:00-04:00"
aliases:
  - /post/book-5/
disqus_url: "https://hackmysql.com/post/book-5/"
series: "Behind the Book"
---

Chapter 5 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) addresses sharding, and it was difficult to write but not for technical reasons.
Let me say a little more on the matter.

<!--more-->

<p class="note">
This blog post is the sixth of eleven: one for the preface and ten for each chapter of my book <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a>.
The full list is <a href="/tags/efficient-mysql-performance/">tags/efficient-mysql-performance</a>.
</p>

## But First: Fipar Says...

Here's a paragraph and footnote that I removed from chapter 5:

> However, scaling out is not intrinsic relational data stores. The reason is historical: the relational data model was created in the 1970s when scaling out was not possible because hardware was physically huge and expensive. Simply put, relational databases were not designed to scale out.[1] Consequently, scaling out a relational data store requires an extrinsic process: sharding.
> <br>
> [1] Even though relational databases were not designed to scale out, that is neither a criticism nor a shortcoming because the relational model has not only been incredibly popular but unarguably indispensable to technology and the internet for more than 40 years.

I removed that paragraph (and footnote) because it's misleading or wrong, as Fernando Ipar (one of my technical reviewers) pointed out:

> It would be good to find a way (either here or on the existing footnote) to mention that, strictly speaking, the relational model is a logical model and has nothing to say about the physical layer. This may be a bit of a personal pet peeve, but IMHO, saying the relational model doesn't scale because one has reached the limits of a specific relational (or, more accurately, relationally-inspired) product seems akin to saying that arithmetic doesn't scale because you attempted an operation that caused an overflow on a specific model of calculator. This distinction is why it is possible for other databases to support sharding along with some relational features in a way that's a lot more transparent to users than how it's done in MySQL (e.g., CockroachDB, TiDB, and even MySQL Cluster). I think a good recommendation for clearing up that matter is the section "Model Versus Implementation", in Chapter One of C.J. Date's [_Database in Depth_](https://www.oreilly.com/library/view/database-in-depth/0596100124/), O'Reilly, 2005. 

Indeed, here's the pertinent statement by Date in chapter one of that book (emphasis mine):

> First, note that __performance is fundamentally an implementation issue__, not a model issue—despite extremely common misconceptions to the contrary. We're often told, for example, that "joins are slow." But such remarks make no sense! Join is part of the model, and the model as such can't be said to be either fast or slow; only implementations can be said to possess any such quality. Thus, we might reasonably say that some specific product X has a faster or slower implementation of some specific join than some other specific product Y&mdash;but that's all.

I often encounter the misconception that Date and Ipar remarked, and I nearly committed the same to print had Ipar not corrected me.
Worse, I actually stated two somewhat conflicting reasons:

1. The relational data model was created in the 1970s when scaling out was not possible because hardware was physically huge and expensive
2. Relational databases were not designed to scale out

On the surface, that's not a glaring fault of logic, but it is wrong: 1 is true, but 2 does not follow from 1.

It's true that, from the 1970s all the way until the early 2000s, hardware was rather big and expensive (compared to today).
As a result, companies couldn't simply provision 100 new databases on a whim.
(As a point of reference, Amazon EC2 launched in 2006.)
Procuring any server was like buying a car: a careful and expensive decision with the intention to own and operate for many years.
Need more capacity?
Scale up the existing servers: more RAM, bigger hard drives, and so forth.
Need even more capacity?
Buy a "bigger" server: one that supports a faster CPU, more RAM chips, more hard drive bays, and so on.

But it is _not_ true that "relational databases were not designed to scale out".
I shouldn't have added that phrasing because it's the very misconception that Date rails against in chapter one of his book&mdash;for good reason.
To requote Date: <mark>performance is fundamentally an implementation issue, not a model issue.</mark>
And scale is part of performance.

## Can We Avoid Sharding?

It's May, 2022 and 1 TB of RAM exists but is far from the norm.
The largest AWS RDS instance type is `db.x1e.32xlarge` with 3,904 GB RAM&mdash;almost 4 TB of RAM.
That's impressive, but I wish it wasn't: I wish it was the norm in 2022.

If terabytes of RAM were the norm, then a single MySQL instance _might_ be able to handle tens of terabytes of data.
I emphasis "might" because, while RAM is a critical factor to avoid sharding, it's not the only factor.
Sometimes, sharding is required to scale writes, in which case storage I/O and latency are more critical factors.
Some PCIe-attached NVMe systems have incredible performance, but like terabytes of RAM they are far from the norm.
And even if RAM and storage I/O were solved problems, what about network transfer speeds?
Transferring 10 TB at 10 Gbps takes about 2 hours.
There are faster link speeds, but they're also not the norm yet.

And let's not forget schema migrations (OSC) and other data operations.
There are three OSC tools for MySQL: pt-online-schema-change, gh-ost, and [Spirit]({{< ref "future-of-mysql-schema-change-spirit/" >}}).
The first two can handle terabytes of data, but only Spirit is optimized for speed and parallelism to handle 10+ TB of data in a few days (not weeks).

I think that, currently, it's not possible to avoid sharding with MySQL (or other similar relational databases).
The reason: data growth has significantly outpaced hardware and tooling for MySQL.
For the last 20 years, MySQL did a great job of keeping up, but I think it's nearing a soft limit due to commonly available (and affordable) hardware and tools.
Right now, I'd put that soft limit at 20 TB of data with favorable (viz. lightweight) access patterns, a small working set size, and a relatively stable schema (or a really patient team/company).

## Data Growth and the Cloud

Data sizes keep increasing.
That's common knowledge even outside tech: people know that years ago devices could storage 5 GB, for example, and now they can store 256 GB.
A timely example is the iPod: an icon evolution in people realizing "I can storage _a lot_ more data!"
(The example is timely because Apple just now discontinued the iPod after 20 years.)
Let's presume for the moment that this long-standing trend is legitimate, not due to data bloat or waste.
(Personally, I think we're extremely wasteful with data, which is why I harp on the issue at length in chapters 3 and 4 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance).)

Since the advent of compute, hardware has rapidly increased in capacity (and decreased in cost)&mdash;that's also well known in tech.
As a result, it kept pace with data growth such that a paradigm change was not required: just keep buying bigger hardware (as it became cheaper) and problem solved.
That was the old paradigm: scale up the hardware you already have.
I'm speaking generally; there are always outliers.

But four things changed in recent years:

1. Growth of hardware capacity lagged a little
2. Growth of data increased significantly
3. Cloud became common
4. Orchestration was invented

Point 1 is stated cautiously because hardware capacity has certainly kept increasing; it's point 2 that's the major change that overshadows and complicates point 1.
It's easy for data growth to explode because it's easy to generate data.
It's far more difficult (and slow) to develop and proliferate hardware in the market because big changes require other new hardware (e.g. SATA to PCIe), new kernels and drivers, and new applications that can fully utilizes the preceding.

While data growth was plowing ahead full speed and hardware was doing its best to keep up, the cloud (point 3) crept into existence around 2006 when Amazon EC2 launched.
But the cloud is really just another server that you rent rather than own.
That means, behind the scenes, AWS (and other cloud providers) are using the same hardware you might purchase.
(This is no longer true: some cloud providers custom build their own hardware.)
But the cloud still helped because it provided a layer of abstraction that hid the complexities of procuring and managing hardware.
The world "elastic" is often used: compute resources in the cloud are elastic.
That means you could keep storing more and more _and more_ data in the cloud without (too much) care for how it works.
In that way, the cloud was a significant evolution because, outside the cloud, the real challenge was not so much "Can I buy a big enough hard drive?" (you could) but rather "How fast can I procure and provision hardware, and how long will it last?"
Companies could not (and would not) heedlessly buy new hardware each year.
Instead, they'd plan and budget and purchase and wait and receive and "rack it" and finally&mdash;sometimes months later&mdash;have that new hardware online.
Given that effort, companies required the hardware to work for years (to thoroughly recoup the investment).
That's why it could be difficult for companies to keep up with explosive data growth.
But the cloud changed that by abstracting away the complexities of procuring and managing hardware: just rent whatever you need on-demand.

The cloud was necessary to change the paradigm, but it wasn't sufficient.
You can provision all the resources you want, but by doing so you create another problem: how to herd the proverbial cats?
Meaning: you can provision a fleet of resources, but how then do you control and manage it?
Enter Docker and Kubernetes in 2013 and 2014, respectively.
These are technologies for containerization (and, by extension, microservices) but they're the last necessary bits that make orchestrating massive fleets of cloud resources tractable. 
So now we can programmatically (and somewhat easily) provision and orchestrate nearly limitless cloud resources and do so "elastically" (create and destroy and recreating resources frequently).
Now the paradigm has changed because, in the cloud, there are practically no limits; it's just a matter of what you can afford.
Loosely stated, the new paradigm is: "just scale out in the cloud."
(Where "just" implies that it's supposed to be easy given orchestration tools, but "easy" is, of course, highly relative.)

## MySQL in the New Paradigm

Back to MySQL: the paradigm around it has changed.

On the one hand, we have relational databases like MySQL that were created _long_ before the paradigm changed&mdash;back when the paradigm was still "scale up": buy bigger, faster hardware.
I think it's important for engineers born after 2000 to know this bit of history: MySQL, Postgres, and the alike were created at a time long before the cloud or Kubernetes.
Back then, the idea of "spinning up" however many resources you wanted was simply not possible.
The norm was scaling up the resources you already had because companies were loathe and slow to buy new hardware.
That's partly why MySQL is so very good at scaling up but cannot natively scale out (why sharding is necessary).

One the other hand, modern software development is moving to the new paradigm where there are virtually no resource limits&mdash;just configure Kubernetes (or whatever orchestration tool) for the size/scale you want and it will (usually) provision whatever is needed.
("Usually" because, in case you didn't know, the cloud does sometimes temporarily run out of resources.)
Unsurprisingly, then, developers look to their databases to do the same but find they cannot with MySQL, Postgres, and the alike.
What now?

## NewSQL and the Innovator's Dilemma

More and more, we're seeing NewSQL data stores that separate the compute and storage layers of the database so that each can scale out in the cloud with orchestration.
This makes sense given the paradigm change, but it also makes sense given that hardware and tools have not stayed _ahead_ of the curve of data growth.
If, for example, there were hardware and tools to easily handle a single 100 TB instance of MySQL, there might not be a market for NewSQL.
But that's not currently the case, so for MySQL at scale developers must implement and maintain application-level sharding&mdash;or make the leap to NewSQL.

While sharding is tried and true (there's a lot of knowledge and success around sharding MySQL), it's still an non-development task that developers routinely tell me that they do not want to do.
I can't blame them: they were hired to develop app features&mdash;and I was hired to make databases scale for them.
(Granted, I wish they'd stop being so wasteful with data, but I digress.)

I think we're witnessing [The Innovator's Dilemma](https://www.christenseninstitute.org/books/the-innovators-dilemma/) in action: SQL on single instances is the incumbent: a massive value network rooted in _four decades_ of success.
NewSQL is the disruptive little startup that's addressing a niche today, and it doesn't seem to have gained major market share (small value network).
NewSQL has the potential to replace the incumbent, including MySQL, especially when products like [TiDB](https://www.pingcap.com/tidb/) are explicitly being MySQL-compatible in order to tap into the incumbent value network.
And not surprisingly, one barrier for NewSQL is cost: NewSQL databases are more complex, which requires more cloud resources, which costs more.
But we've seen that play out too: costs go down as the disruptor's market share goes up.

<p class="note">
<a href="https://vitess.io/">Vitess</a> and similar products are not disruptors: they are bridges from the incumbent value network to the new value network.
If the real disruptors win, the bridges will slowly disappear.
</p>

## So What's the Point?

Sharding MySQL is still necessary because we're in uncertain times about what might allow engineers to avoid sharding: either an explosion in affordable hardware capacity (which really just provides more runway, moves the issue further into the future), or NewSQL successfully disrupting traditional SQL and becoming mainstream.

It seems logical that, in the future, software engineers will not have to deal with application-level sharding because that's not really their job, and NewSQL has proven that it doesn't need to exist.
That's why, personally, I think NewSQL will win, but it will take minimum 5 years&mdash;or 10 years more realistically.
But don't worry: MySQL and other single instance relational databases will continue to be _vital_ for even longer&mdash;so long that learning MySQL today is practically required given its ubiquity.
