---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Transactions and Data Locks"
weight: 7
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn about MySQL transactions and data locks, which are closely related:

<div class="intro">
MySQL has non-transactional storage engines, but InnoDB is the default and the presumptive norm.
Therefore, practically speaking, every MySQL query executes in a transaction by default, even a single <code>SELECT</code> statement.

From our point of view as programmers, transactions appear conceptual: `BEGIN`, execute queries, and `COMMIT`.
Then we trust MySQL (and InnoDB) to uphold the ACID properties: atomicity, consistency, isolation, and durability.
When the application workload—queries, indexes, data, and access patterns—is well optimized, transactions are a nonissue with respect to performance.
(Most database topics are a nonissue when the workload is well optimized.)
But behind the scenes, transactions invoke a whole new world of considerations because upholding ACID properties  while maintaining performance is not an easy feat.
Fortunately, MySQL shines at executing transactions.

As with replication lag, the inner workings of transactions are beyond the scope of this book, but understanding a few basic concepts is pivotal to avoiding common problems that hoist transactions from the lowest levels of MySQL to the tops of programmers' minds.
A little understanding avoids a lot of problems.

{{< book-excerpt-copyright c="Chapter 8">}}
</div>

## Key Points

* Transaction isolation levels affect row locking (data locks)
* The fundamental InnoDB data locks are: _record lock_, _next-key lock_, _gap lock_, and _insert intention lock_
* Record lock: lock a single index record
* Next-key lock: lock a single index record plus the record gap before it
* Gap lock: lock the range (gap) between two records
* Insert intention lock: allow `INSERT` into a gap; more like a wait condition than a lock
* The default transaction isolation level, `REPEATABLE READ`, uses gap locking to isolate the range of rows accessed
* The `READ COMMITTED` transaction isolation level disables gap locking
* InnoDB uses _consistent snapshots_ in `REPEATABLE READ` transactions to make reads (`SELECT`) return the same rows despite changes to those rows by other transactions
* Consistent snapshots require InnoDB to save row changes in undo logs to reconstruct old row versions
* History list length (HLL) gauges the amount of old row versions not purged or flushed
* History list length is a harbinger of doom: always monitor and alert on HLL greater than 100,000
* Data locks and undo logs are released when a transaction ends: `COMMIT` or `ROLLBACK`
* Four common problems beset transactions: large transactions (modify too many rows); long-running transactions (slow response time from `BEGIN` to `COMMIT`); 
stalled transactions (superfluous waits between queries); abandoned transactions (client connection vanished during active transaction)
* The MySQL Performance Schema makes detailed transaction reporting possible

## Pitfalls

* Not having a basic understanding of InnoDB row/data locks
* Using `FOR UPDATE` without knowing exactly why and what locks it takes
* Abandoned transactions
* Slow (to commit) transactions
* Doing application working during an open transactions
* InnoDB locking the supremum pseudo record

## Hack MySQL Articles

{{< path-articles path="trx" >}}

## Additional Resources

| Resource | Type | About |
|----------|------|-------|
|[InnoDB Locking and Transaction Model](https://dev.mysql.com/doc/refman/en/innodb-locking-transaction-model.html)|MySQL manual|Foundational knowledge. Must read.|
|[_MySQL Concurrency: Locking and Transactions for MySQL Developers and DBAs_](https://www.amazon.com/MySQL-Concurrency-Locking-Transactions-Developers/dp/148426651X) by Jesper Wisborg Krogh|Book|Locking and transaction are such deep topics they could fill a book, and they do.|
|&bull;&nbsp;[InnoDB Data Locking - Part 1 "Introduction"](https://dev.mysql.com/blog-archive/innodb-data-locking-part-1-introduction/)<br>&bull;&nbsp;[InnoDB Data Locking - Part 2 "Locks"](https://dev.mysql.com/blog-archive/innodb-data-locking-part-2-locks/)<br>&bull;&nbsp;[InnoDB Data Locking - Part 2.5 "Locks" (Deeper Dive)](https://dev.mysql.com/blog-archive/innodb-data-locking-part-2-5-locks-deeper-dive/)<br>&bull;&nbsp;[InnoDB Data Locking - Part 3 "Deadlocks"](https://dev.mysql.com/blog-archive/innodb-data-locking-part-3-deadlocks/)<br>&bull;&nbsp;[InnoDB Data Locking - Part 4 "Scheduling"](https://dev.mysql.com/blog-archive/innodb-data-locking-part-4-scheduling/)<br>&bull;&nbsp;[InnoDB Data Locking - Part 5 "Concurrent Queues"](https://dev.mysql.com/blog-archive/innodb-data-locking-part-5-concurrent-queues/)<br>by Jakub Łopuszański @ Oracle|Article series|One of the most comprehensive, technical explanation of InnoDB data locking. Written by a MySQL server developer.|
