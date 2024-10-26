---
date: "2024-10-20T22:35:00-04:00"
lastMod: "2024-10-26T15:30:00-04:00"
title: "Group Commit and Transaction Dependency Tracking"
subtitle: "Towards Multi-threaded Replication"
tags: ["mysql", "replication", "group-commit", "logical-clock", "writeset"]
comments: true
series: "Replication Lag"
---

MySQL 8.0 and newer change and improve how we measure and monitor replication lag.
Even though multi-threaded replication (MTR) has been on by default for the last three years (since [v8.0.27](https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-27.html) released October 2021), the industry has been steeped in single-threaded replication for nearly _30_ years.
As a result, replication lag with MTR is a complicated topic because it depends on version, configuration, and more.
This three-part series provides a detailed understanding, starting from what was originally an unrelated feature: binary log group commit.

<!-- more -->

This is a three-part series on replication lag with MTR and the Performance Schema:

|Part|Topic|
|----|------------|
|1|Group commit and trx dependency tracking|
|2|Replica preserve commit order (RPCO)|
|3|Monitoring MTR lag with the Performance Schema|

Links to each part (once they're published) are in the upper right &nearr; (or top on small screens).

These topics are closely related&mdash;they depend on each other.
If you're new to these topics, start here (part 1).
If you're familiar with them, jump to part 3 (once it's published).

## Group Commit

Before looking at MySQL binary log group commit (BGC), consider the simplest way to code durability on transaction commit: use a mutex to serialize writes and flushes to disk.
In pseudo-code, the thread for every client would do something like:

```c
/* pseudo code */

LOCK(log_mutex);

write_data();

fsync();

unlock(log_mutex);
```

Even a junior programmer can see that that code is going to be really slow on a busy database: heavy mutex contention plus slow, individual writes and syncs.
The only hope for performance is blazing fast storage (that's probably really expensive).

Since every commit must be made durable, that code quickly hits the physical performance limits of the storage, particularly IOPS and write latency.
Surprisingly, the real MySQL code prior to group commit was similar&mdash;writing and syncing each transaction, one by one.

<div class="note">
<b>Past Performance</b><br>
Before 2012 and group commit, how did MySQL achieve high transaction throughput with durability? 
A single spinning disk can do about 200 IOPS at best.
Big tech companies would use enterprise-grade SSD and RAID to achieve thousands of IOPS per server.
When that wasn't enough, the solution was (and still is) sharding: using hundreds or thousands of servers.
For example, being conservative, a big tech company circa 2012 could achieve 1 million IOPS total by having 200 MySQL shards each doing 5,000 IOPS.
</div>

The solution to improve transaction throughput with durability is to group writes and syncs.
Hence [_group commit_](https://dev.mysql.com/worklog/task/?id=5223) added in MySQL 5.6 (circa 2012):

> Indeed, the entire point of performing a group commit of the binary log is to not flush the binary log with each transaction and instead improve performance by reducing the number of flushes per transaction.

Grouping doesn't solve all performance problems because some things can't be grouped, or grouping causing more work.
But it works in this case because grouping is somewhat cost-free due to the fact that transactions must _already_ be serialized for logging in both the InnoDB redo logs and the MySQL binary logs.

Imagine that the transactions are A, B, C, and D&mdash;committed in that order.
A system can write and flush (sync) them in groups (denoted by `[ ]`) that preserve the original commit order:

* `[A] ... [B] ...  [C,D]`
* `[A,B] ... [C,D]`
* `[A,B,C] ... [D]`
* `[A,B,C,D]`

The last example is the best performance-wise: 1 write/flush for all 4 transactions.

<div class="note">
<b>Commit Order</b><br>
Commit order can be flexible.
There are cases (and MySQL configurations) in which the order of the example above can be different yet valid.
For simplicity, let's presume that the original commit order is preserved.
</div>

The idea of group commit is simple but the implementation is not because the difficult question is: how should MySQL get transactions to group together?
If it waits some amount of time to collect transactions, then how long should it wait?
If it waits to collect N number of transactions, then how large should N be?
Worst case, every group is less than N, so every transaction commit is delayed by the wait time&mdash;wasted time is created in an attempt to reduce wasted work.
<a name="bgc-sysvars"></a>Regardless, this is precisely what MySQL does because nobody has figured out a better method:

* wait time = [`binlog_group_commit_sync_delay`](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_group_commit_sync_delay)
* N = [`binlog_group_commit_sync_no_delay_count`](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_group_commit_sync_no_delay_count)

These sysvars are 0 (off) by default, but <mark>MySQL always groups commits when possible, even when these sysvars are zero.</mark>
I'll explain why <a href="#why-mysql-always-group-commits">later</a>.
For now, the point is that these sysvar do not enable group commit, they only tune group commit.

How should these two sysvars be tuned?
There's no definitive answer, no best practice, no industry standard.[^1]

[^1]: J-F talks about this: it's not easy tuning group commit and/or measuring the effects on parallel/multi-threaded replication. We need new, better metrics. As of this writing, it's still a process of trial and error.

MySQL expert Jean-François (J-F) Gagné has probably tested, written, and presented more on this than anyone else, like [A Metric for Tuning Parallel Replication in MySQL 5.7](https://jfg-mysql.blogspot.com/2017/02/metric-for-tuning-parallel-replication-mysql-5-7.html) and various conference presentations you can find online.
The TL;DR is: the longer MySQL waits, the more transactions it can group together.
However, to be clear...

<mark>As of MySQL v5.7.6, transaction dependency tracking and MTR do _not_ depend on binary log group commit.</mark>

I highlight the previous because there can be confusion and wrong information for two reasons.
First, logical clock [v1](#v1) coupled trx dependency tracking, BGC, and MTR for a few versions (v5.7.2&ndash;v5.7.5 inclusive), but this stopped being true more than 9 years ago.
Second, as [diagram 1](#diagram-1) shows (below), trx dependency tracking happens during BGC, which is still true as of MySQL 9.0, but <u>group commit does not determine transaction dependency</u>.
Transaction dependency is first identified by [locking intervals](#locking-interval) on commit, then enhanced by [writesets](#writeset).[^9]

[^9]: However, on MySQL 8.0 if you don't explicitly configure `binlog_transaction_dependency_tracking = WRITESET`, then BGC size affects max committed values, which become `last_committed` values, which affect when a replica can execute a trx in parallel.
But see [System Variables Removed](#sysvars-removed).

That said, to deeply understand group commit and how it ties into multi-threaded replication, it's necessary to first understand the transaction (trx) commit process because it's all woven together.

### Trx Commit Process

There's a complex diagram below, but we need to lay some groundwork first, starting with two points that are clear and understandable:

* MySQL uses a [two-phase commit (2PC)](https://martinfowler.com/articles/patterns-of-distributed-systems/two-phase-commit.html). (Another good, longer explanation of 2PC: [Distributed Transactions & Two-phase Commit](https://medium.com/geekculture/distributed-transactions-two-phase-commit-c82752d69324) by Animesh Gaitonde.)
So there are _prepare_ and _commit_ code paths called in that order: prepare &rarr; commit.
* The complete trx commit process occurs on explicit `COMMIT`, [`autocommit`](https://dev.mysql.com/doc/refman/en/server-system-variables.html#sysvar_autocommit), or implicit commit (due to a DDL statement, for example).

Here are two more points that usually are _not_ clear or immediately understandable:

* Binary log code (`class MYSQL_BIN_LOG : public TC_LOG` in `sql/binlog.cc`) acts as the 2PC transaction coordinator _and_ it implements the storage engine "handlerton" interface.[^2]
* Every statement "commits": 2PC code is called after every statement, not just `COMMIT`.

[^2]: "Handlerton" is MySQL lingo for "handler" plus "singleton": a single instance of code that handles (implements) a storage engine.

Even after [20 years hacking MySQL]({{< ref "lessons-from-20-years-hacking-mysql-part-1/" >}}), I don't know why the binlog acts as the transaction coordinator.
Regardless of why, this means the diagram below is mostly binlog code playing two roles; only the green parts (InnoDB) are not binlog code.

Every statement "commits" means that the 2PC code is called after every statement, but the code does different things depending on the statement.
Even a `SELECT` "commits", but most of the 2PC code returns early because it's not a transaction commit.
To disambiguate this conflation of the term "commit",[^3] let's use:

[^3]: Much worse than "statement commit" is the variable in MySQL source code to signal trx or statement commit: `all`. If true, it's a trx commit; else it's a statement commit.

|Term|Refers To|
|----|---------|
|(trx) commit|End of trx on explicit `COMMIT`, [`autocommit`](https://dev.mysql.com/doc/refman/en/server-system-variables.html#sysvar_autocommit), or implicit commit|
|statement commit|End of query, _not_ a trx commit|

Statement commits are important because they start (or restart) the [locking interval](#locking-interval) described later.
But for now, let's focus on the trx commit process that's executed by one or more threads concurrently:

<a name="diagram-1">

![MySQL Transaction Commit Process with Binary Log Group Commit](/img/binary_log_group_commit.jpg)

</a>

<p class="figure">Diagram 1: MySQL transaction commit process with binary log group commit</p>

Blue items at top are [logical clock](#logical-clock) values explained later.
The prepare and commit phases are show in the middle.
Black circle numbers are callouts used to describe the process below, step by step.
Light magenta (pinkish) items are binary log group commit [queues and processes](#flush-sync-commit).
Green items at bottom left are InnoDB components.
And MySQL binary logs are shown at bottom right.

The following glosses over the BGC stages&mdash;[Flush, Sync, Commit](#flush-sync-commit)&mdash;that are detailed in the next section.

1. **Prepare Phase**
 * Get commit parent to record later as `last_committed` in binary logs
 * Write InnoDB prepare records to in-memory [log buffer](https://dev.mysql.com/doc/refman/en/innodb-redo-log-buffer.html)
 * A `COMMIT` statement does nothing in the prepare phase
2. **Flush Stage: <i>Queue</i>**
  * Enter flush queue and check if it was empty (was thread first in queue?):
    * False: thread becomes a follower, **go to step 6** and wait using [`pthread_cond_wait`](https://pubs.opengroup.org/onlinepubs/7908799/xsh/pthread_cond_wait.html)
    * True: thread becomes the leader and continues...
3. **Flush Stage: <i>Process</i>**
  * Take all threads in flush queue
    * The time between step 2 and now is virtually zero&mdash;a few lines of code
  * Flush InnoDB prepare records
  * Step and assign logical clock values to each trx to record later as `sequence_number` in binary logs
  * Write (but don't flush) transactions to binary logs
    * Each trx is recorded with `<last_committed, sequence_number>` 
4. **Sync Stage**
  * Enter sync queue and check if it was empty (was thread first in queue?):
    * False: thread becomes a follower (even if it was leader for flush stage), **go to step 6** and wait using [`pthread_cond_wait`](https://pubs.opengroup.org/onlinepubs/7908799/xsh/pthread_cond_wait.html)
    * True: thread becomes the leader and continues...
  * Wait [`binlog_group_commit_sync_no_delay_count`](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_group_commit_sync_no_delay_count) or [`binlog_group_commit_sync_delay`](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_group_commit_sync_delay)
    * This wait is how those sysvars can increase group commit size: the longer the wait, the more threads will enter the sync queue before...
  * Take all threads in sync queue and _flush binary logs_ (sync process)
    * This is a binary log group commit: the group is all trx for all threads taken from the sync queue
5. **Commit Stage**
  * Enter commit queue and check if it was empty (was thread first in queue?):
    * False: thread becomes a follower (even if it was leader for flush stage), **go to step 6** and wait using [`pthread_cond_wait`](https://pubs.opengroup.org/onlinepubs/7908799/xsh/pthread_cond_wait.html)
    * True: thread becomes the leader and continues...
  * Update global max committed (if leader sequence number is greater)
  * Write and sync InnoDB commit records to finalize changes in the database and release locks
6. **Wake Up Followers**
  * Commit stage leader calls [`pthread_cond_broadcast`](https://pubs.opengroup.org/onlinepubs/7908799/xsh/pthread_cond_broadcast.html)
  * Follower threads wake up and update global max committed (if follower sequence number is greater)


The trx commit process is concurrent at some points and serialized at others.
Diagram 1 looks serialized, but generally speaking steps 1&ndash;3 are concurrent, step 4 is (mostly) serialized, and steps 5&ndash;6 are (mostly) concurrent.
And other details, like how InnoDB has its own type of group commit,[^4] are not shown.
[^4]: See [MySQL 8.0: New Lock free, scalable WAL design](https://dev.mysql.com/blog-archive/mysql-8-0-new-lock-free-scalable-wal-design/) and comment "The idea in InnoDB's group commit is..." in function `trx_commit_in_memory` of `storage/innobase/trx/trx0trx.cc`.

It might help to visualize the trx commit process as a pipe:

![Trx commit process in concurrently, out serially](/img/trx_commit_process_io.svg)

<p class="figure">Diagram 2: Transactions enter randomly but exit with an order</p>

Transactions enter randomly and concurrently but exit with an order: `sequence_number` (the second value in the `< >` pair).
The ordering happens in step 3, the flush stage process, because that's when each transaction is given the next sequence number (from the logical clock) and written to the binary logs.

A log on the source is required to record changes, but on a replica it creates a problem for MTR: without encoding some kind of trx dependency tracking, the concurrency entering the pipe is lost.
This is what [logical clock](#logical-clock) and [writeset](#writeset) provide: trx dependency tracking.
But first, the BGC stages: flush, sync, commit.

<div class="note">
<b>Terminology</b><br>
"Commit parent" and <code>last_committed</code> are synonymous.<br>
"Trx N" means transaction with <code>sequence_number = N</code>.
</div>

### Flush, Sync, Commit

Binary log group commit is implemented as three stages during the commit phase: flush &rarr; sync &rarr; commit.
For each stage, there's a queue and a process (function): flush queue and flush process; sync queue and sync process; commit queue and commit process.
In digram 1 above, this detail is called out by steps 2 and 3, and it's important because the tiny interval between queue and process is where, when, and how concurrent threads _might_ pile up in a queue (primarily the sync queue), causing a group commit.

* **Flush**<br>
The flush stage has no wait between queue and process.
It's one function call (enter queue) followed almost immediately by the other (process queue).
Since there's virtually no interval (a matter of clock cycles), threads are unlikely to pile up in the flush queue.[^5]
Regardless, I can confirm that the flush queue works as intended because I can pause threads with a debugger to force a pile up in the flush queue.
But on a real server, I would expect threads to pass through the flush stage one by one unless the server has extreme concurrency, is heavily loaded, or both.
<br><br>
During the flush stage, InnoDB flushes prepare records (from the prepare phase) to its redo logs.
For a truly durable two-phase commit, this is necessary because prepare records cannot be lost, so they must be synced to disk.
But given the previous (threads are unlikely to queue up during the flush stage), is this efficient?
I'm not an expert on InnoDB internals, so I could be wrong here, but I'm pretty sure the answer is yes.
The log buffer is holding prepare records in memory, so there should be one sequential write (buffer to redo log files) and flush by the flush stage leader.
(Each BGC stage is executed by a single leader thread.)
Since we're examining binary log group commit (part of MySQL, not InnoDB), I'll leave this as an open question.
<br><br>
Also during the flush stage, MySQL writes (but does not flush) events to the binary logs.
This is fast because it's a single thread (the stage leader) doing sequential writes, which the operating system or storage device is most likely going to cache.
<br><br>
Just before writing a transaction to the binary logs, MySQL steps the [logical clock](#logical-clock) to set the `sequence_number` of the transaction, then it fetches the `last_committed` (commit parent) value that was set in the prepare phase.
Both values are written into the binary logs.

[^5]: There used to be a wait (`binlog_max_flush_queue_time`) but it was removed in MySQL 5.7.

* **Sync**<br>
The sync stage has a wait between queue and process, shown at step 4 (the clock) in digram 1.
The wait is created by [`binlog_group_commit_sync_no_delay_count`](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_group_commit_sync_no_delay_count) and [`binlog_group_commit_sync_delay`](https://dev.mysql.com/doc/refman/en/replication-options-binary-log.html#sysvar_binlog_group_commit_sync_delay).
This is the crux of binary log group commit: by putting a wait _after_ the sync queue, threads will pile up in the sync queue.
When the wait expires, the leader takes all threads in the sync queue and flushes the binary logs.
(If a thread is in the sync queue, its trx must have been written to the binary logs in the flush stage.)
These threads and transactions are one group commit.
<br><br>
When BGC was introduced in 2012, spinning disks were still common, so a sync was quite slow: on the order of milliseconds.
Today, a sync can take only microseconds on flash storage, but it's still the slowest part of making committed transactions durable.
<br><br>
At this point in the trx commit process, the changes are truly durable.
Even if MySQL crashes after the sync, MySQL and InnoDB can (and do) recover from the binary logs and InnoDB prepare records.
But the 2PC isn't done yet, so all the threads in the group commit advance to the final stage: commit.

* **Commit**<br>
During the commit stage, the leader thread updates the global max committed value that (other) threads entering the prepare phase read as their commit parent.
Since the leader might not have the highest sequence number, follower threads also update the max committed once they're woken up at the end of the commit process.[^6]
<br><br>
Last but not least, InnoDB commits transactions, which is to say that it finalizes transactions in the database and releases all locks.
If you think the preceding is complex, it's nothing compared to what InnoDB does to make committing many concurrent transactions fast and efficient: [MySQL 8.0: New Lock free, scalable WAL design](https://dev.mysql.com/blog-archive/mysql-8-0-new-lock-free-scalable-wal-design/).
Long story short, InnoDB does a type of group commit, too.

[^6]: This might be an easily fixed inefficiency in the logical clock: set the max seq once.

Let's step through a simplified example with five transactions, `a`&ndash;`e`, flowing through the three group commit stages to see how they may or may not group and how they pick up a commit parent value (denoted by `< >`).
Time, `t`, runs top to bottom:

```none
t| FLUSH          | SYNC          | COMMIT
-|----------------|---------------|--------------
1| < >a1, b1, c1  |               |
2| < >d1          | < >a1, b1, c1 |
3|                | < >d1         | < >a1, b1, c1
4| <c1>e1,c2      |               | < >d1
5|                | <c1>e1,c2     |
6|                |               | <c1>e1,c2
```

At time `t`:

1. Three trx&mdash;`a1`, `b1`, `c1`&mdash;join the flush queue at virtually the same time.
In this example, there are no committed trx, so the commit parent, `< >`, is empty.
One of these threads is leader; it doesn't matter which.
The leader flushes all three trx and moves them to the sync stage.
2. A new trx&mdash;`d1`&mdash;enters the flush stage, but the first three trx didn't wait long enough so they're already syncing (`d1` can't join them in the group commit).
3. The first three trx move to the commit stage and finish in InnoDB, releasing locks.
Trx `d1` moves to the sync stage and syncs alone.
4. Two new trx&mdash;`e1`, `c2`&mdash;enter the flush stage.
Since `c1` just finished committing, the new trx have `c1` as their commit parent.
Trx `c2` is the second instance of the `c` trx.
Consequently, `c2` had to wait for `c1` to commit (and release its locks) because the two acquire the same locks.
In this case, `c1` is truly the commit parent of `c2`.
However, trx `e1` doesn't conflict with `c1` or `c2`; it just happens to commit at this time when `c1` is the max committed trx.
Trx `d1` finishes committing.
5. Trx `e1, c2` proceed through the sync stage.
6. Trx `e1, c2` proceed through the commit stage.

<a name="why-mysql-always-group-commits"></a>As mentioned earlier, MySQL always group commits when possible:
* When both [BGC sysvars](#bgc-sysvars) are zero, group commits are possible when threads pile up in the sync queue either by good luck (they arrive in the queue at virtually the same time) or bad luck (the leader thread has stalled for some reason)
* When either BGC sysvars is non-zero, it enables a sync queue wait that makes group commits more likely (and larger), but it incurs a penalty: the [trx commit process](#trx-commit-process) is slower

Here's the same example but with a sync queue wait:

```none
t| FLUSH          | SYNC (with delay)     | COMMIT
-----------------------------------------------------------------
1| < >a1, b1, c1  |                       |
2| < >d1          | < >a1, b1, c1         |
3| < >e1          | < >a1, b1, c1, d1     |
4|                | < >a1, b1, c1, d1, e1 |
5|                |                       | < >a1, b1, c1, d1, e1
6| <e1> c2        |                       |
```

The example above is the same as the one above it, but this time there's a sync queue wait that allows trx `d1` and `e1` to join the group commit in the sync stage.
However, since trx `c2` still conflicts with `c1`, `c2` cannot enter the prepare phase (before BGC) until `c1` is done committing and has released its locks.
But once `c1` has committed, then `c2` prepares and begins BGC at t=6 with `e1` as its commit parent.

### Locking Interval

In the example above, trx `a1, b1, c1, d1, e1` can execute in parallel on a replica because they don't have conflicting [locking intervals](https://dev.mysql.com/worklog/task/?id=7165):

> the locking interval for multi-statement transactions begins at the end of the last statement before commit.

Recall "statement commits" from the [trx commit process](#trx-commit-process): 2PC code is called after every statement.
And recall from diagram 1 that the commit parent is fetched in the prepare phase.
This means the locking interval spans from the last statement commit to the end of the trx commit.

If a query is not the last one in the transaction (MySQL doesn't know how many queries a trx will contain), it will prepare (begin locking interval) but not commit.
Eventually, the trx will commit and&mdash;just before storage engine commit&mdash;end the locking interval.

To understand why locking intervals are critically important for MTR, consider this informal deduction: 

1. When a transaction commits, it _must_ hold all the locks that it needed to execute because locks are held until `COMMIT` or `ROLLBACK`.
And this _must_ be true because, if the single-threaded client executing the transaction is able to execute `COMMIT`, then it cannot be waiting or blocked on anything else.
If it were, then it couldn't execute `COMMIT`, which would be a logical contradiction that proves the point&mdash;_reductio ad absurdum_.
2. Given 1, transactions that commit together hold locks that do not conflict.
Imagine that transaction A holds a lock on primary key (PK) value 1, and transaction B holds a lock on PK value 2.
Presuming no foreign keys, the rows corresponding to these PK value are independent from the database point of view at this "time".
Later, theses transactions might conflict (the same query can lock different rows), but right "now" they're independent.
(How "time" and "now" work are explained next: [Logical Clock](#logical-clock).)
Relative to one another, executing independent (non-conflicting) transactions will _not_ produce inconsistent data.
And as long as the database remains consistent (A<b style="color:hotpink">C</b>ID), it's permitted.
3. Given 1 and 2, transactions that commit together on a source can execute in parallel on a replica because doing so will not produce inconsistent data on the replica.

If MySQL tracks locking intervals and encodes the information in the binary logs, then a replica can determine if and when transactions can execute in parallel.
The general term for this is _transaction dependency tracking_, and MySQL uses two methods: `COMMIT_ORDER` and `WRITESET`.
Both are based on a logical clock&mdash;you'll learn why later.

<div class="note warn">
<a name="sysvars-removed"><b>System Variables Removed</b></a><br>
The following sysvars related to transaction dependency tracking were removed in MySQL 8.4:
<ul>
<li><code>binlog_transaction_dependency_tracking</code></li>
<li><code>transaction_write_set_extraction</code></li>
</ul>
Additionally, <code>replica_parallel_type</code> is deprecated and will be removed in a future version.
The future non-configurable values will be <code>WRITESET</code>, <code>XXHASH64</code>, and <code>LOGICAL_CLOCK</code> respectively.
If using MySQL 8.x, configure these values, then be prepared to remove the sysvars when you upgrade to 8.4 or 9.x.
</div>

MySQL writes two values from the [trx commit process](#trx-commit-process) into the binary logs for each trx:  `<last_committed, sequence_number>`.
These numbers, which result from locking intervals and commit order, are the logical clock that power MTR.

## Logical Clock

In oversimplified terms, a logical clock is a monotonically increasing counter.
Start at 1, step it, now it's 2.
Step it again, now it's 3.
And so on.
This is an oversimplification of an [important concept](https://en.wikipedia.org/wiki/Logical_clock), but I'll just focus on MySQL.

MySQL uses a logical clock and commit order for transaction dependency tracking.
(It also uses [writesets](#writeset), but more on that later.)
The logical clock counts transaction as they're written into the binary logs during the [trx commit process](#trx-commit-process).

Transaction dependency tracking determines _if_ transactions can execute in parallel.
Logical clock determines _when_ transactions can execute in parallel, _if_ they can.

<div class="note">
<b>Depends and Conflicts</b><br>
One trx can depend on another for different reasons.
The most common reason is conflicting <a href="#lock-intervals">locking intervals</a> or <a href="#writeset">writesets</a>.
But there are other reasons (like DDL statements) that cause transaction dependencies.
For simplicity, this page use "depends" and "conflicts" synonymously because the end result is the same: dependent or conflicting trx cannot execute in parallel.
</div>

If trx 5 depends on trx 4, then the two cannot execute in parallel; a replica must execute trx 4 before trx 5.
(Of course, logical clock time 4 is before 5.)
But if trx 5 does _not_ depend on trx 4, then a replica can execute trx 4 and 5 in any order: 4 then 5, 5 then 4, or 4 and 5 at the same (logical or wall-clock) time.

The sooner a trx can execute the better because "perfect parallelization" would mean all trx are non-conflicting (independent) and can execute _now_&mdash;at the same time.
But that's neither the norm nor the expectation; rather, it's expected that some trx can execute at the same time, but others have to wait.

If, for example, the trx in question is `sequence_number = 16`, can it execute in parallel with trx 1&ndash;15?
Or will it have to wait until the logical clock reaches 16?

The answer with logical clock v1 was pretty simple.
Logical clock v2, which is still current as of MySQL 9.0, provides a better answer.
And [writesets](#writeset) provide an even better answer.

### v1

MySQL logical clock [v1](https://dev.mysql.com/worklog/task/?id=6314) was very short-lived (v5.7.2&ndash;v5.7.5 inclusive) and too tightly coupled to binary log [group commit](#group-commit) because it recorded only the commit parent.
As such, only trx in the same group commit&mdash;with the same commit parent value&mdash;could execute in parallel.
This worked but it limited parallelization (v2 and writesets will show why).

Suppose that a binary log contained:

```
commit_parent=0 trx 3
commit_parent=0 trx 4
commit_parent=0 trx 5 // When can this one execute?
commit_parent=3 trx 6
commit_parent=3 trx 7
```

With v1, trx 5 could execute in parallel only with trx 3 and 4 because these three trx had the same `commit_parent` value: zero.
So a replica with four applier threads would execute trx 3, 4, 5, and wait&mdash;the fourth applier thread would idle.
When all trx with `commit_parent=0` were done, the replica would proceed to the next group commit parent.

Because MySQL logical clock v1 worked this way, larger group commits on the source were required for more parallelization on a replica.
As such, the [sysvars to tune BGC](#bgc-sysvars) also tuned parallelization for MTR.
<u>But this is no longer true with logical clock v2 and writesets</u>.

The BGC tuning sysvars still exist to improve the commit process (some servers still use spinning disks), but as of MySQL 8.4 they're obsolete with respect to MTR because logical clock v2 and writeset decouple BGC size from MTR parallelization.[^7]
(For MySQL 8.0, although deprecated as of v8.0.35, set `binlog_transaction_dependency_tracking = WRITESET`.)

[^7]: Transaction dependency tracking still happens during the BGC process; but with writeset, BGC _size_ no longer limits or determines MTR parallelization.


### v2

Introduced in v5.7.6 and still current in MySQL 9.0, logical clock [v2](https://dev.mysql.com/worklog/task/?id=7165) adds the transaction `sequence_number` to the binary logs and allows trx `T` to execute in parallel on a replica if the `sequence_number` of the _oldest_ trx that's executing is greater than the `last_committed` of `T`.

Consider the example from above again:

```
last_committed=0 sequence_number=3  // ...executing... (oldest)
last_committed=0 sequence_number=4  // ...executing...
last_committed=0 sequence_number=5  // <- T
last_committed=3 sequence_number=6  //
last_committed=3 sequence_number=7  //                 (newest)
```

Trx 3 and 4 are executing.
Trx 5 can execute in parallel because 3 (the oldest executing) is _greater than_ 0, the commit parent of 5:

|Oldest Trx Executing|&nbsp;|Can Execute Trx 5?|
|---------------|------|----------|
|`sequence_number=3`|&gt;|`last_committed=0`|

([v1](#v1) allowed trx 5 to execute in parallel but for a different reason: same commit parent.)

As long as trx 3 is executing, trx 6 and 7 cannot execute because the check is false.
But once trx 3 is done, then trx 6 and 7 pass the check:

|Oldest Trx Executing|&nbsp;|Can Execute Trx 6 or 7?|
|---------------|------|----------|
|`sequence_number=4`|&gt;|`last_committed=3`|

The crucial difference between logical clock v1 and v2 is that that v1 did not look back in logical time.
Conflicts weren't really identified, they were avoided by parallelizing trx only in the same group commit.
But v2 looks back in logical time&mdash;across group commits&mdash;to identify the soonest a trx can execute in parallel, which is after the last conflicting transaction.

"Looks back" is figurative; in technical terms, here what's happening on both sides of replication:

Source
: The last statement in a trx (before `COMMIT`) gets the max committed trx sequence number.
This becomes the `last_committed` value of the trx, paired with its `sequence_number`&mdash;both set during the flush stage and recorded in the binary logs.
(See [diagram 1](#diagram-1).)
In this sense, each trx looks back when it fetches the max committed value because that value was set by earlier transactions in the commit stage.
The purpose is _not_ to identify group commits but rather [locking intervals](#locking-interval): when a trx enters the prepare phase, its locks cannot conflict with the last committed trx (else it wouldn't have been able to enter the prepare phase).

Replica
: For each trx, a replica preforms the check previously stated: trx `T` can execute in parallel if the `sequence_number` of the _oldest_ trx that's executing is greater than the `last_committed` of `T`.
In this sense, a replica looks back to check the oldest trx that's still running.
Again, it's not a matter of group commit, it's a matter of [locking intervals](#locking-interval).

Logical clock v2 is pretty good but [writesets are better](https://dev.mysql.com/blog-archive/improving-the-parallel-applier-with-writeset-based-dependency-tracking/) because 
they allow MySQL to look even further back in logical time by determining conflicts more precisely.

<div class="note">
If you search for additional information on MTR, you'll probably come across
<a href="https://www.percona.com/blog/a-dive-into-mysql-multi-threaded-replication/">A Dive Into MySQL Multi-Threaded Replication</a> at Percona.
The authors are renowned MySQL experts, but I think the annotated binglog dump in that blog post is wrong.
For example:
<pre>
  last_committed=1 sequence_number=14 <= trx 1 committed alone
</pre>
I'm pretty sure that's wrong: trx 1&ndash;13 committed together because they have the same commit parent: <code>last_committed=0</code>.<br><br>
Also, the statement "if you want the replica to apply transactions in parallel, there must be group commits on the primary" is not accurate because, with MySQL logical clock v2 and writesets, it's possible for transactions with different commit parents to execute in parallel.
As such, there can be parallelization even if every transaction commits alone.
</div>

## Writeset

Writeset tracks which rows each transaction changes.
Transactions that change different rows are non-conflicting and can execute in parallel on a replica.

Writeset is not a logical clock but, in MySQL, it is built on top of logical clock (v2).
It tries to minimize the commit parent value; the writeset code is literally a `min` function:[^8]

```cpp
commit_parent = std::min(last_parent, commit_parent);
```

[^8]: `sql/rpl_trx_tracking.cc` `Writeset_trx_dependency_tracker::get_dependency`

Of course, the full writeset code is more complicated, but in essence it tries to find an older commit parent by comparing rows changed (writesets).

Consider five transactions with a more complicated series of commit parents:

```
last_committed=20 sequence_number=21 //      (oldest)
last_committed=20 sequence_number=22 //
last_committed=22 sequence_number=23 //
last_committed=23 sequence_number=24 //
last_committed=23 sequence_number=25 // <- T (newest)
```

When can trx 25, the newest, execute?

By logical clock alone, 25 needs to wait for 23 because `last_committed=23`.
And 23 needs to wait for 22.
And 22 needs to wait for 20 (not shown).
And so on.

But what if these five trx update completely different rows&mdash;no conflicts at all&mdash;and the commit parents are just arbitrary artifacts of the group commit process? 🤔

Writeset will detect this and minimize the commit parent of trx 25 to the oldest non-conflicting transaction (within certain limits).
With an older commit parent, trx 25 can execute in parallel a lot sooner.

If you're thinking "Writeset doesn't need group commit or commit parents", you're right.
I wonder if it even needs `sequence_number` because transactions can be identified by an existing value: GTID.
But as of MySQL 9.0, the code for binary log group commit, logical clock, and writeset are still intertwined.

Writeset is great for multi-threaded replication because it identifies much more parallelization than commit order.
But ironically another feature called "replica preserve commit order" reduces the net benefits by requiring transactions to commit in the same order as the source.
This is the subject of the forthcoming part 2 of this series...
