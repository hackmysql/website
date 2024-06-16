---
type: "page"
date: "2022-06-18T19:09:00-04:00"
title: "InnoDB Page Flushing Diagram"
subtitle: "Chapter 6"
tags: ["mysql", "innodb", "book", "efficient-mysql-performance"]
comments: true
aliases:
  - /post/book-6/
disqus_url: "https://hackmysql.com/post/book-6/"
---

Who dares diagram a system and process as complex as InnoDB page flushing?
I do.

<!--more-->

<p class="note">
This blog post is the seventh of eleven: one for the preface and ten for each chapter of my book <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a>.
The full list is <a href="/tags/efficient-mysql-performance/">tags/efficient-mysql-performance</a>.
</p>

![InnoDB Page Flushing](/img/innodb-page-flushing.svg)

That digram is from chapter 6 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance), which is a deep dive into the most useful MySQL server metrics.
There is a long section on InnoDB metrics that focuses mostly on the write path: from transaction commit to buffer pool and most (but not all) of the parts in between.
I encourage you to read the entire chapter because a short, informal blog post like this cannot begin to approach the depth and clarity of the book.
Instead, I want to quickly discuss some points about InnoDB that new DBAa need to know.

### Avoid, Optimize, and Delay

InnoDB _acts like_ an in-memory (yet durable) cache because all logical reads and writes occur in the buffer pool, which is in memory.
Broadly speaking, I think it's helpful to view InnoDB as an in-memory cache rather than a storage engine on top of slow disks.
This helps to avoid fixating on slow disk access.
MySQL and InnoDB (and probably every database ever created) already know that disk access is slow.
A big part of the _raison d'être_ of InnoDB is doing very clever things to avoid, optimize, and delay disk access.
InnoDB is so good at those three techniques that in normal operation it acts like an in-memory cache with behind-the-scenes magic to make data durable, support transactions, and a lot more.
As the saying goes: "The fastest way to do something is to not do it."

<p class="note">
"In memory" is synonymous with "in the buffer pool".
MySQL and InnoDB have other in-memory data structures, but "in memory" in MySQL parlance means "in the buffer pool".
</p>

### Reads

Read performance is rarely an issue _at the storage level_ because, again, InnoDB acts like an in-memory cache, and it's exceptionally good at keeping the working set in memory.
"But why are slow `SELECT` queries so common?", you ask.
There's no single answer (you have to do query analysis to determine why), but physical reads (from disk) are one of the last problems I would suspect.
For that problem, you'd need:

* A working set size much greater than physical RAM _and_
* Queries that almost exclusively access new data _and_
* Throughput so high that InnoDB must continually evict older data to load new data

I've never seen, nor can I imagine, a workload with all three of those conditions.
But if there were such a workload, the solution would be simple: don't use MySQL; use another data store better suited to that kind of workload.

The point is that it's safe to presume that InnoDB is nearly always doing logical reads: from memory, not disk.
Therefore, an individual `SELECT` is not likely to be slow due to physical or logical reads because, respectively, the data is probably already in memory (working set) and reading from memory is very fast.
The more common problems are excessive row access and server resource contention.

### Writes

Don't blame MySQL or InnoDB for write performance.
InnoDB is the only reason you get acceptable write performance in the first place because standard hardware and operating systems are not fine-tuned for databases.
On the contrary: those two have to work reasonably well for everything, which means they're not fine-tuned for anything&mdash;they're just generally fast and efficient.
And even if they were fine-tuned for databases, they'd have to be fine-tuned for specific versions of MySQL, and specific hardware, and specific application-driven workloads because those three vary and combine to create different performance requirements.

Alas, performance is difficult, which is why it's helpful to realize that InnoDB is why you get any write performance at all.
The diagram above is only a high-level view of InnoDB page flushing; InnoDB does a lot more.
For example, we could zoom in on the transactions log (or "redo log") at top to see how it balance speed (concurrent `COMMIT`) and durability (flushing committed data changes to disk).
Note that concurrent `COMMIT` is different than concurrent writes: the latter is easier (and more a matter of transaction isolation and row locking) because they're logical writes in memory.
Data changes are made durable in the redo log on commit.

It might seem like write performance is a very low-level and rather simple concern: how fast can InnoDB physically write to disk and `fsync`?
But that's usually the wrong question because [Avoid, Optimize, and Delay](#avoid-optimizeand-delay).
Database performance is first and foremost _efficiency_: doing the same (or more) with less.
For example, let's say the top speed of your car is 260 km/h.
Do you drive to work at 260 km/h?
You could, but you probably shouldn't.
Likewise, let's say your hard drives support 20k IOPS.
Do you blast writes at 20k IOPS?
You could, but [you probably shouldn't](https://www.percona.com/blog/2019/12/18/give-love-to-your-ssds-reduce-innodb_io_capacity_max/).

Page flushing is the user-serviceable part of InnoDB that makes writes efficient.
That's why I spent so much time in chapter 6 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) to explain it.
So rather than fixate on low-level disk access&mdash;which you can't change anyways unless you change the storage system or devices&mdash;learn how InnoDB page flushing works.
Spoiler: the adaptive flushing algorithm is dynamic, so you cannot simply increase related MySQL system variables to magically effect greater write performance&mdash;again: [Avoid, Optimize, and Delay](#avoid-optimizeand-delay).

### Dirty Pages

It's important to remember that the database on disk is probably _not_ current.
(Where "current" means "having all the most recent values".)
That's a little weird since we tend to think of the database as _the_ source of truth.
It is, but the question is really "At which point in time?"
Eventually the data can be (or become) current, but to repeat myself: [Avoid, Optimize, and Delay](#avoid-optimizeand-delay).

In reality, the buffer pool is full of dirty pages (which have current values) and that's ok because the data changes that made those pages dirty are durable in the transaction log.
So "the" source of truth is really the database plus the transaction log&mdash;when the latter is applied to the former.

The transaction log is fixed-size, so InnoDB flushes dirty pages to make space in the transaction log for new data changes, not because dirty pages are "bad" or represent non-durable data.
If the transaction log wasn't a fixed size, it could delay flushing for a very long time.
The adaptive flushing algorithm tries to do this: it flushes only when needed and only as much as needed&mdash;that's what makes it "adaptive".

The main downside to dirty pages is that they slow down MySQL startup or shutdown, depending on how MySQL is configured.
A [fast shutdown](https://dev.mysql.com/doc/refman/en/glossary.html#glos_fast_shutdown) results in a slow startup.
A slow shutdown results in a fast startup.

### IOPS

Configurable I/O limits affect flush list flushing, not [LRU flushing]({{< ref "mysql-lru-flushing-io-capacity" >}}) or reading data from disk.
That's an important point you don't often read about.
It means that InnoDB can and will use tons of IOPS on startup, for example, when data is first loaded.
Or when a bad query inadvertently selects nearly all rows, so InnoDB has to do physical reads to load rows into memory.

But don't worry: as mentioned earlier, InnoDB is really good at keeping the working set in memory.
As a result, a typical server uses IOPS mostly for page flushing&mdash;specifically, flush list flushing to free space in the transaction log.
Together, this is how and why MySQL can sustain high throughput (QPS) with very few IOPS: reads are from memory (working set) and writes are highly optimized (page flushing).

### Binary Logs

Not shown in the diagram above: durable write/flush to binary logs.
Commits are two-phase (2PC): begin, write/flush binlogs, commit.
This is necessary to help ensure that the redo and binary logs stay in sync; of course, failure during the 2PC is possible, and InnoDB crash recovery handles this.
As such, you must remember to enable binary logs during benchmarking, presuming all nodes typically have binary logging enabled in production.
Note that binary logs are handled by MySQL, not InnoDB.
