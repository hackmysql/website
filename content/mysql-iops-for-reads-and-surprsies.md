---
type: "page"
date: "2022-11-20T13:00:00-05:00"
title: "MySQL IOPS for Reads and Surprsies"
tags: ["mysql", "iops"]
comments: true
aliases:
  - /post/mysql-iops-for-reads-and-surprsies/
disqus_url: "https://hackmysql.com/post/mysql-iops-for-reads-and-surprsies/"
params:
  path: data
---

When you think about IOPS, you probably think about writes because MySQL write I/O has a long tradition of optimization, benchmarking, new algorithms, new storage engines, and so forth.
There's no shortage of material on MySQL write I/O; just two examples from Percona are [Scaling IO-Bound Workloads for MySQL in the Cloud](https://www.percona.com/blog/2018/08/29/scaling-io-bound-workloads-mysql-cloud/) and [Tuning MySQL/InnoDB Flushing for a Write-Intensive Workload](https://www.percona.com/blog/2020/05/14/tuning-mysql-innodb-flushing-for-a-write-intensive-workload/).
But in this short blog post I highlight two other, less common aspects of MySQL I/O: reads and surprises.

<!--more--->

## Reads

Read IOPS are not usually an issue because of the InnoDB buffer pool: frequently used data (the working set) is kept in memory, so both reads and writes are essentially in-memory operations.
"Not usually an issue" is a good thing because <mark>read IOPS are unlimited</mark>.

By contrast, write IOPS are both limited and stabilized by the [adaptive flushing algorithm](https://dev.mysql.com/doc/refman/8.0/en/innodb-buffer-pool-flushing.html#innodb-adaptive-flushing).
Apart from reducing SSD wear, this is necessary to ensure consistent and manageable performance, which is necessary to collocate many MySQL instances on a single physical server.
Imagine if write IOPS were erratic, spiky, and unpredictable: how would several MySQL instances share the same underlying storage system without battling each other for IOPS?
Like any fine-tuned machines, we need to know what we're working with in order to work with it effectively.

But read IOPS have no such algorithm.
When a client needs data that's not already in the buffer pool, MySQL loads it as fast as possible.
And if that's a lot of data or a lot of clients, the result can be a tsunami of IOPS.

But again: it's not usually an issue because InnoDB is really good a keeping the working set in memory, so normal production servers should not have noticeable read I/O spikes.
However, if a MySQL server does have this problem, it can really siphon the available IOPS.
For example, I recently ran across a MySQL server that I manage doing 30,000 IOPS for reads.
Why?
A rare combination of the server being drastically under-provisioned (huge working set vs. small amount of RAM) _plus_ running Amazon Aurora that has pay-per-use IOPS.

Speaking of the cloud: whereas MySQL does not limit read IOPS, your cloud provider might limit total IOPS.
This is a good reason to remember that read IOPS aren't limited by MySQL because, in a worst case, read IOPS can starve write IOPS in the cloud.

## Surprises

Talk about IOPS is usually in the context of normal operations: the application humming along with MySQL as usual.
But a few surprises can cause abnormal I/O usage:

* Online schema changes (`ALTER`)
* Data backfills
* Application bugs
* Collateral damage
* Free page waits

Surprises like these can cause spikes in read or write IOPS.
The first three are relatively self-explanatory, but I'll tell a quick story of the fourth (collateral damage) and briefly explain the fifth (free page waits).

One time I helped a team fix a database-related outage in application X that called application Y.
But we fixed X almost too well: its performance increased so greatly that it overwhelmed Y, causing a second outage in Y.
The fix to X caused collateral damage to Y.

I've also seen cases where teams increase queue consumers because something caused a backlog in the queue and they want to catch up.
Great... except they forgot that queue processing results in some database writes, and now MySQL is struggling, which slows down queue processing again.
Whatever issue affected the queue caused collateral damage to MySQL.

A free page wait occurs when MySQL needs to read data into memory, but there are no free pages in the InnoDB pool to store the data.
To make space (free pages), InnoDB it will evict old pages from the buffer pool.
If the pages to evict are dirty, MySQL will flush (write) them first.
This is a worst-case scenario because, instead of reading from memory (no IOPS), it incurs IOPS for the read and IOPS for the write.
But this should be so expectationally rare that it's a surprise when it occurs.
And surprises do occur:

![Free Page Waits Graph](/img/free-page-waits.png)

Free pages waits are the _right_ Y axis: the red spikes.
(The left Y axis is the percentage of reads from disk, which is also very high.)
This was during a benchmark (MySQL in the cloud), so I know that the workload was steady.
What's surprising is that nothing seems to have precipitated this spike in free page waits, and it didn't occur again.
