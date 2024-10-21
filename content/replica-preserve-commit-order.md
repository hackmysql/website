---
date: "2024-07-20T00:00:02-04:00"
title: "Replica Preserve Commit Order"
subtitle: ""
tags: ["mysql", "replication", "lag"]
comments: true
series: "Replication Lag"
draft: true
---

It's time to learn a new way of monitoring MySQL replication lag because what's been industry standard for almost 30 years has come to an end.
The future is Performance Schema and multi-threaded replication (MTR).
These are lot better than the past, but they require a near total rethink of how it all works.
Let's dive deep.

<!-- more -->

1. Group commit/logical clock
2. RPCO
3. Replication lag

## Single-threaded Replication

<p class="note">
If you're familiar with single-threaded MySQL replication, you can skip this section.
</p>

Let's say we have 10 transactions (trx), from the replica point of view:

![Single-threaded replication](/img/repl_lag_old.jpg)
<p class="figure">Diagram 1: Single-threaded replication</p>

* Trx 1 (blue) has been applied by the replica
* Trx 2 (red) is actively being applied
* Trxs 3&ndash;7 (grey) have been received (in replica relay logs) but not applied yet
* Trxs 8&ndash;10 (grey, dashed outline) have _not_ been received but they exist on the source (in binary logs)

Replica lag increases the further back (left in the digram) we go to find the last applied trx.

For simplicity, let's say each trx takes 1 second to apply.
Replication lag in this case is 9s: trx 10 (latest) - trx 1 (last applied) = replica is 9 seconds behind (lagging) the source.
If nothing else changes, the replica should catch up to the source (apply trx 10) in 9 seconds.

<p class="note">
<b>Apply vs. Execute</b><br>
Read <a href="{{< ref "why-mysql-replication-is-fast" >}}">Why MySQL Replication is Fast</a> to learn why replicas <em>apply</em> transactions, not  <em>execute</em> them.
</p>

There's an important detail hiding in this simple diagram: although the replica has received up to trx 7, only _applied_ trx 1 is used to calculate replication lag because trx 2 can fail to apply and trx 3&ndash;10 can be lost.
For example, a replica might purge its relay logs (trx 3&ndash;7) on recovery before refetching them from a source.
(It could be a different source than before recovery because, with [GTIDs](https://dev.mysql.com/doc/refman/en/replication-gtids.html), it doesn't matter as long as the source has the missing GTIDs that the replica needs.)

## Multi-threaded Replication

There are two possible scenarios with multi-threaded replication (MTR): [`replica_preserve_commit_order` (RPCO)](https://dev.mysql.com/doc/refman/8.0/en/replication-options-replica.html#sysvar_replica_preserve_commit_order) ON or OFF. Having RPCO enabled (ON) is the safer option, so you'd think MySQL would have defaulted to it from the beginning, but if you've been [using MySQL for a long time]({{< ref "lessons-from-20-years-hacking-mysql-part-1" >}}) then you'll be zero surprised that:

|Version|RPCO Default|
|-------|------------|
|&le; 8.0.26|OFF|
|&ge; 8.0.27|ON (Enabled)|

Not coincidentally, in chapter 7 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance), which was written around the time of 8.0.25, I advised setting RPCO _on_ (contrary to the default at the time).
A rare case of a technical book being ahead of its time.

The following two diagrams use the same numbered and colored transactions as diagram 1 above.
The main difference below is two replica appliers (workers) instead of one.
Other technical differences are discussed in detail.

### RPCO Disabled

![Multi-threaded replication with 2 appliers/workers](/img/repl_lag_mtr.jpg)
<p class="figure">Diagram 2: Multi-threaded replication, 2 appliers/workers, without preserve commit order</p>

The old default, `replica_preserve_commit_order = OFF` for MySQL &le; 8.0.26, is shown above in digram 2.
Worker 1 was assigned trx 5, 6, 7.
Worker 2 was assigned trx 1 2, 3, 4.
Since RPCO is off, each worker applies _and commits_ transactions in parallel.
(The emphasis on "and commits" will be important later.)

Trx 1 and 5 are applied and committed&mdash;they're done.
Trx 2 and 6 are being applied but not yet committed; once applied, they'll be committed in parallel.
Trx 3, 4, 7 are waiting are queued and waiting to be processed by their assigned workers.
Trx 8&ndash;10 have not been received by the replica yet.

This is probably how most people presume MTR works because it's completely parallel execution.
It works but there's one problem: on a replica, `replica_preserve_commit_order = OFF` creates a different transaction history than the source.

A _transaction history_ is an ordered set of committed transactions identified by GTID.[^1]
In this example, the transaction history from the source (not shown) is GTIDs [1&ndash;10].
But on the replica, the transaction history is GTIDs [1, 5]&mdash;the two committed trx&mdash;as shown by diagram 3:

[^1]: Strictly speaking, transactions are not required to be identified by GTID. But practically speaking, GTID should always be used because it has no drawbacks or limitations that I'm aware; rather, GTID makes managing replication significantly easier.

![Multi-threaded replication with 2 appliers/workers trx committed](/img/repl_lag_mtr_committed.jpg)
<p class="figure">Diagram 3: Multi-threaded replication, 2 appliers/workers, without preserve commit order, trx committed</p>

While diagram 2 is not wrong, that visualization suggests that MySQL fills in the gap between trx 1 and 5, which is not what happens.
Diagram 3 is technically more accurate: the replica binary logs contain trx 1 then trx 5.

This is _not_ a problem for MySQL because it already determined that trx 1 and 5 were independent and, therefore, able to be applied and committed out of order.
But it could be a problem for everything else because:

* It creates transaction gaps (trx 2, 3, 4 seem to be missing), and
* It creates a view or state of the data that wasn't observed on the source

Transaction gaps are a problem for replication lag: is the lag 9s (measured from trx 1) or 5s (measured from trx 5)?
(Recall from above that, for this example, we presume each trx takes 1s to execute, and trx 10 represents the current time.)
Transaction gaps are also a problem for tools (like backup tools) that aren't programmed to handle them properly, which is probably most tools since MTR being the norm is still relatively new as of 2024 (versus 25+ years of single-threaded replication being the norm).

Creating a view or state of the data that wasn't observed on the source is a subtle and tricky problem because whether or not it actually matters depends on the application (or whatever is reading from MySQL).
Here's a completely made-up example to show how this could matter; imagine that:

* Each trx updates a row to be either a "tick" or a "tock" (like a clock)
* Odd-numbered trx are ticks, and even-numbered trx are tocks&mdash;trx 1 tick, trx 2 tock, trx 3 tick, and so on
* The application requires an alternating series: tick, tock, tick, tock, and so forth
* Two or more sequential ticks or tocks cause an application error

Under these conditions, the replica transaction history causes an application error because it records two ticks in a row: trx 1 tick and trx 5 tick.
And if trx 2 and 6 commit next as shown in diagram 3, that's another application error: two tocks in a row.

A less made-up example is [pt-heartbeat](https://docs.percona.com/percona-toolkit/pt-heartbeat.html): if heartbeat updates are committed out of order on the replica, then observed/reported replication lag will jump forward and backward in time, which would be a poor user experience.

Without very careful consideration of all application logic over time and in the context of concurrency (at the application level),  `replica_preserve_commit_order = OFF` is _not_ a safe assumption.
Consequently, as of MySQL 8.0.27 `replica_preserve_commit_order` (RPCO) is enabled by default.

### RPCO Enabled

![Multi-threaded replication with 2 appliers/workers](/img/repl_lag_mtr_pco.jpg)
<p class="figure">Diagram 4: Multi-threaded replication, 2 appliers/workers, with preserve commit order</p>

With `replica_preserve_commit_order = ON`, which is the default as of MySQL 8.0.27, a replica will _apply_ transactions in parallel but _commit_ in order.
As a result, transaction history on the replica will be the same as the source (lag notwithstanding).

The only drawback is illustrated above in diagram 4: to preserve commit order (on the replica), an applier might have to wait for another to commit preceding transactions.
In this example, worker 1 has applied _but not committed_ trx 5 because it's waiting on worker 2 to commit trx 4.

Worker 1 _applied_ trx 5 in parallel with other workers, but it has to wait to _commit_ trx 5 until all previous trx are committed.
(The state of "applied but not committed" is indicated in diagram 4 by the blue outline around trx 5.)
As such, `replica_preserve_commit_order = ON` limits parallelism on commit in order to preserve the original commit order from the source.

Although parallelism is limited, enabling RPCO is still advantageous because the slow part is not (usually) the commit, it's the apply.
Imagine that trx 5 needs to update 1M rows.
While worker 2 is busy with trx 1&ndash;4, worker 1 can get started by applying those 1M row images, which is going to be slow.

## Replica 
