---
date: "2020-07-05T18:50:00-03:00"
title: "What the Flush?"
subtitle: "MySQL Dirty Pages"
tags: ["mysql", "flushing", "dirty-pages"]
comments: true
aliases:
  - /post/what-the-flush-mysql-dirty-pages/
disqus_url: "https://hackmysql.com/post/what-the-flush-mysql-dirty-pages/"
---

Yves Trudeau and Francisco Bordenave, MySQL experts at Percona, recently published a three-part post:
(1) [Give Love to Your SSDs – Reduce innodb_io_capacity_max!](https://www.percona.com/blog/2019/12/18/give-love-to-your-ssds-reduce-innodb_io_capacity_max/);
(2) [InnoDB Flushing in Action for Percona Server for MySQL](https://www.percona.com/blog/2020/01/22/innodb-flushing-in-action-for-percona-server-for-mysql/); 
(3) [Tuning MySQL/InnoDB Flushing for a Write-Intensive Workload](https://www.percona.com/blog/2020/05/14/tuning-mysql-innodb-flushing-for-a-write-intensive-workload/). It's a fantastic read from start to finish, and it made me realize: dirty pages sound bad, but they are good. I suspect the opposite ("dirty pages are _not_ good") is a misconception due to an incomplete picture. Let's complete the picture.

<!--more-->

## Dirty Pages Won't Be Lost

> A dirty page is a page that is modified in memory but not yet flushed to disk.

That's from Yves/Francisco part 2. If the casual reader stops there, it sounds bad: disk is durable storage, so if modifications aren't flushed to disk, they could be lost. But that's not the case: <mark>with `innodb_flush_log_at_trx_commit = 1`, changes are recorded in the InnoDB transaction (redo) logs on disk and flushed</mark>.

## No Significant Drawbacks

We trust InnoDB durability, so there is no risk of data loss with dirty pages and `innodb_flush_log_at_trx_commit = 1`. The only drawbacks of dirty pages are, as mentioned in Yves/Francisco part 1, slow MySQL shutdown and crash recovery. But in practice, those two cases don't matter for one reason: the MySQL server won't (or shouldn't be) active. To shutdown MySQL in production, we would failover to another instance. Then the previous instance has no hurry to shut down. Plus, even if the buffer pool size is 500G, modern storage can flush that quickly (especially when there's no other traffic to the server). If MySQL crashes, we'd also failover to another instance. MySQL crashes in production are rare, so don't optimizing for it.

## Dirty Pages Are Good

> Since you should aim to have as many dirty pages as possible without running into flush storms and stalls, the high_checkpoint algorithm will help you. 

If you read all three parts of their blog post, Yves and Bordenave explain why that quote is true. TL;DR: more dirty pages in memory means less disk IO. If "dirty pages" sounds worrisome, think of them as "recent pages", because that's what they are: the most recent change, in memory. Of course we want the most recent changes in memory! That's the fastest way to fetch them.

## Why Flush At All?

If dirty pages are good for performance, then why not 100% dirty pages? Why flush at all? There are two reasons. First, "buffer pool churn": flushing old, unused pages to load newly requested data (pages). This happens because almost always the InnoDB buffer pool is _much_ smaller than the total or working data set sizes. For example, having a 100G buffer pool for 500G of data. But even if this wasn't true&mdash;let's say we have 1G buffer pool for 50M of data&mdash;reason two is the InnoDB transaction log. As shown in Yves/Francisco part 2, the InnoDB transaction log is a ring buffer (two log files). If all data fit in the buffer pool and we updated the same in-memory, dirty pages over and over, the _records of those changes_ would eventually fill up the transaction log. Adaptive flushing won't let that happen.

## History of innodb_max_dirty_pages_pct

History repeats itself:

| MySQL Version | Default Value | Maximum Value |
| ------------- | ------------- | ------------- |
| 5.0           | 90 | 100 |
| 5.1           | 90 | 100 |
| 5.5           | 75 | 99 |
| 5.6           | 75 | 99 |
| 5.7           | 75 | 99.99 |
| 8.0           | 90 | 99.99 |

If you're running 5.6 or 5.7, you should set `innodb_max_dirty_pages_pct = 90` to let adaptive flushing handle flushing. And if you're running 8.0, set `innodb_max_dirty_pages_pct_lwm = 0` because early flushing doesn't make sense.
