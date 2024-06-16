---
type: "page"
date: "2022-04-17T13:50:00-04:00"
title: "Access Patterns for MySQL"
subtitle: "Chapter 4"
tags: ["mysql", "access-patterns", "book", "efficient-mysql-performance"]
comments: true
aliases:
  - /post/book-4/
disqus_url: "https://hackmysql.com/post/book-4/"
---

Access patterns intrigue me because it seems that everyone knows what they are and talks about them, but there's also very little written about them&mdash;in MySQL literature, at least.
That's why I set out to enumerate a list of access patterns (specific to MySQL).
Since there's no apparent standard for access patterns, I cannot say how my list measures up, but after spending most my career with MySQL, I know this: it is necessary to consider these access patterns when evaluating and improving MySQL performance.
Simply put: you cannot ignore _how_ the application accesses MySQL.

<!--more-->

<p class="note">
This blog post is the fifth of eleven: one for the preface and ten for each chapter of my book <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a>.
The full list is <a href="/tags/efficient-mysql-performance/">tags/efficient-mysql-performance</a>.
</p>

Chapter 4 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) enumerates access patterns for MySQL (among other related topics).
In this blog post, I don't restate all the details I put in the book.
Instead, like other posts in this series, I'm adding "behind the scenes" information&mdash;things I did not put in the book.

## Access Patterns

### Throughput
Throughput (QPS) is a weird access pattern because is it an "access"?
Since we lack a precise definition of "access" in the term "access pattern", I'm going to claim that throughput is an access pattern because it most definitely affects many considerations.
Or, look at it this way: no sane DBA would say that you can simply ignore throughput.

Although throughput is _not_ performance, it is a significant consideration in nearly everything&mdash;especially other access patterns.
For example:

* Read-write access pattern:
  * Low throughput writes: easy.
  * High throughput writes: very difficult.
* Concurrency access pattern:
  * Low throughput concurrency: easy.
  * High throughput concurrency: very difficult.

In general, I'd say that throughput is a rough "scaling factor" for effort.
At very low QPS, pretty much everything is easy.
But the more QPS increases, the more difficult performance becomes.
However, it must be factored in with all other access patterns&mdash;QPS by itself is almost meaningless.

### Read/Write

Read vs. write might be the first and most apparent access pattern: does the app read data, write it, or both?
And how much of each: is it 90% reads and 10% writes, or vice versa?
This is a very simple yet very powerful access pattern because:

* Reads are relatively easy to scale, especially with more memory.
* Writes are difficult to scale, even with better storage I/O.

It's also a good tool for focusing technical debates.
Sometimes, I encounter debates about such-and-such performance (for example, storage I/O latency in the cloud), but no one has asked: for reads, writes, or both?
Performance for a read-heavy app has very different considerations than a write-heavy app.
Be sure everyone is clear on this access pattern when having such debates.

### Read Consistency

Speaking of reads: does the app _really_ need read-after-write?
If not, then we have a world of possibilities with respect to caching and other techniques to handle eventually consistent reads.
This becomes necessary when read QPS is extremely high.

### Concurrency

Currency is perhaps the most difficult access pattern:

* High concurrency reads: easy thanks to MVCC. (Just be certain to avoid long-running transactions.)
* High concurrency writes: very difficult; no magical solution; MySQL _must_ serialize at some point.

High concurrency writes leads to sharding, which is not an easy feat for some developers.
If there's any magic, it's that: sharding.
Otherwise, this combination of access patterns (high throughput + high concurrency) has lead to new technology like [RocksDB](http://rocksdb.org/): a write-optimized key-value store.

Also, don't sabotage read concurrency with unnecessary `SELECT..FOR UPDATE` or `SELECT...FOR SHARE` that basically turn non-locking reads into locking reads.

### Transaction Isolation

In MySQL, every query is a transaction (generally speaking), which incurs a fair bit of overhead.
If the app doesn't need transactions or strict transaction isolation, then that overhead is waste.

Granted, MySQL is super fast and efficient with its transactions, but still: I almost never encounter developers that know with certainty that the application needs a certain transaction isolation level.
Usually, they just write one-off queries and that's it; or, they do use transactions for _atomicy_ but not necessarily isolation.
Find out: if queries don't actually need isolation, then at least use `READ COMMITTED` to avoid holding an MVCC snapshot for the entire duration of a transaction.
At the extreme: don't use a transactional data store.

### Data Age

The presumptive norm is that total data size is much greater than total RAM.
However, add to that the _working set_: the much smaller portion of data that the application access frequently.
MySQL has many tricks to keep the working set in memory and swap data in and out of memory as needed.
Keeping the working set in memory is critical for performance because it avoids hitting disk.
But how does one do this or even know if it's being done?

Unfortunately, this is one of the most difficult things to measure precisely in MySQL.
There are some low-level server metrics for page eviction, but the general measurement is "buffer pool efficiency" that I detail in chapter 6.
For now, the point is: it's difficult to truly measure the working set and whether or not it's staying in memory.
Basically no one does it; they guesstimate.

This access pattern is part of the guesstimating: does the app access the same data over and over?
For example, once a row has been used in some way, is it "forgotten to time" and almost never accessed again?
Or does the app continually look up (access) rows from long ago and recently and everything in between?

Developers usually know this.
For example, where I work (fintech), the last few days or weeks of financial transaction are all that people typically access.
It's not usual for people to look up transactions after they've settled.
Sure, it happens sometimes, but the point is: it's rare enough not to "churn" the working set too quickly.
As a result, MySQL does a great job of keeping the most recent data in memory, and slowly evicting old data as needed.

But some apps are very different: they access tons of data from any time, all the time.
That's fine if RAM is still enough to contain all that data, but it's easily not the case because RAM is relatively limited.
For example, frequently accessing all the rows in a 500G table is going to be tough on 128G of RAM.
(And that's just the data: what about the secondary indexes? There's probably a few of them, so data + indexes could be 700G, for example.)
Then the question becomes: can you afford 256G or 384G or 512G of RAM?
Or can you change this access pattern somehow to avoid the churn&mdash;to reduce the working set size?

### Row Access

Broadly speaking, there are three types of row access:

* Point access: A single row
* Range access: Ordered rows between two values
* Random access: Several rows in any order

That's more than a pithy categorization; it has legitimate import with respect to performance, especially when combined with other access patterns.
For example, a high throughput read point access is basically MySQL acting like a cache: MySQL is going to keep that single row in memory (so it's also related to data age).
Easy performance.
But change it to random access and now it's not so easy for two reason.
First, if it's truly random, that might affect the working set (data age, again).
Second, if might affect which index MySQL choose, if any, based on cardinality (and how many rows MySQL estimates the query will match).

Writes are a different story: a point read is easy, but a point write can be one of the most difficult challenges (at high concurrency and throughput) because there's simply no way around somewhat serialized access to that single row.
Range or random writes might be better, but then they begin to interfere with data locks from other writes if and when row access overlaps.

Therefore, like other access patterns, the type of row access is an important dimension in the overall consideration of performance.

### Result Set

Grouping, sorting, or limiting the result set is an minor but still important access pattern.
The best is to eliminate the first two and use the last (limiting) because that helps MySQL do less work.
However, it's not really as simple as that: in chapter 3, I talk about cases when it's _better_ to have MySQL do the grouping or sorting.
Either way, it's important to know when this access pattern is the case because, for example, some data stores handle limiting differently, which is important if/when you migrate&mdash;it happens!

### Data Model

MySQL is a relational, transactional, OLTP-optimized data store.
Used for anything else, performance becomes "weird" because such cases are like using a small personal aircraft to commute to work when your office is only 20 minutes down the road.

Personally, I think the JSON column type should not be used; MySQL is not a document store.
Likewise, I often see developers use `BLOB` columns to dump data into MySQL, which becomes real "fun" given that `binlog_row_image = full` by default, so all those blobs squeeze through replication.
And using MySQL as a simple key-value store is also not ideal even though it can do point reads on primary key with incredible speed and efficiency.

I advise engineers to use MySQL for what it is and intended for.
But I'm well aware that MySQL is used for almost everything because it's so good at storing data and making it truly durable.
But seriously: considering using other data stores when your data model is not relational and transactional.

## Identifying

Identifying access patterns is something I've seen done only once with MySQL (because the team was considering moving to a different data store).
By contrast, Amazon publishes a list of access patterns for DynamoDB because it's critical to identify them before moving to DynamoDB: [Step 3. Identify your data access patterns](https://docs.aws.amazon.com/prescriptive-guidance/latest/dynamodb-data-modeling/step3.html).

Access patterns must be identified by developers (and probably written down).
Generally speaking, each single query is an access pattern.
So we look at individual access patterns (queries), but we also consider the totality of access patterns and the affects that has on MySQL.
For example, a single high throughput write is probably not going to cause any trouble.
But many such access patterns are difficult to scale.

Although performance is query response time, and you can get a lot of performance out of MySQL by simply ensuring that all response times are acceptable (and optimizing with response time as your North Star), professional software engineers developing and maintaining an application that relies heavily on MySQL should be fully versed in all its access patterns.
In short: you need to know _how_ the application accesses MySQL.
