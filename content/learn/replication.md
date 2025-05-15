---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Replication"
weight: 6
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn the basics of MySQL replication, especially the cause of replication lag:

<div class="intro">
<i>Replication lag</i> is the delay between the time when a write occurs on a source MySQL instance and the time when that write is applied on a replica MySQL instance.
Replication lag is inherent to all database servers because replication across a network incurs network latency.

Replication lag is data loss.
Seriously.
Do not dismiss replication lag.

I’m glad that, as a programmer using MySQL, you don’t have to set up, configure, and maintain a MySQL replication topology because MySQL replication has become complex.
Instead, this chapter investigates replication lag with respect to performance: what is it, why does it happen, what risk does it pose, and what you can do about it.

Technically, yes, replication decreases performance, but you don't want to run MySQL without it.
It's not hyperbole to say that replication prevents businesses from failing—from data loss so catastrophic that, if replication did not prevent it, the company would go out of business.
MySQL runs everywhere from hospitals to banks, and replication keeps invaluable data safe despite inevitable failures.
Although replication decreases performance and lag is a risk, those costs are cancelled by the overwhelming benefits of replication.

{{< book-excerpt-copyright c="Chapter 7" >}}
</div>

## Key Points

* Replication lag is data loss, especially with asynchronous replication
* MySQL has three types of replication: asynchronous, semi-synchronous, and Group Replication
* Asynchronous (async) replication is the default
* Asynchronous replication can lose numerous transactions on failure
* Semi-synchronous (semi-sync) replication does not lose any committed transactions, only one uncommitted transaction per client connection
* Group Replication is the future of MySQL replication and high availability; it turns MySQL instances into a cluster
* The foundation of MySQL async and semi-sync replication is sending transactions, encoded as binary log events, from a source to a replica
* Semi-sync replication makes transaction commit on the source wait for at least one replica to acknowledge receiving and saving (not applying) the transaction
* A replica has an I/O thread that fetches binary log events from the source and stores in local relay logs
* A replica has, by default, one SQL thread that executes binary log events from the local relay logs
* Multi-threaded replication can be enabled to run multiple SQL threads (applier threads)
* Replication lag has three main causes: (high) transaction throughput on the source; a MySQL instance catching up after failure and rebuild; or network issues
* SQL (applier) threads are the limiting factor in replication lag: more SQL threads reduce lag by apply transaction in parallel
* Semi-sync replication can incur replication lag
* Enabling multi-threaded replication (MTR) is the best way to reduce replication lag
* The MySQL metric for replication lag, `Seconds_Behind_Source`, can be misleading
* Use a purpose-built tool to measure and report MySQL replication lag at sub-second intervals
* Recovery time from replication lag is difficult to calculate and imprecise
* MySQL will eventually recover from replication lag; it always does once the cause is fixed

## Pitfalls

* Replication lag (is data loss)
* Not monitoring replication lag
* Not alerting on replication lag
* Not using GTID
* Not waiting for a replica to catch up on planned failover
* Using `Seconds_Behind_Source` (formerly `Seconds_Behind_Master`)
* Obsessing about when MySQL will catch up after an incident that caused high lag

## Hack MySQL Articles

{{< path-articles path="repl" >}}

## Additional Resources

| Resource | Type | About |
|----------|------|-------|
|[Replication](https://dev.mysql.com/doc/refman/en/replication.html)|MySQL manual|The authoritative source for DBAs, perhaps too in-depth for programmers.|
|[An Introduction to MySQL Replication: Exploring Different Types of MySQL Replication Solutions](https://www.percona.com/blog/overview-of-different-mysql-replication-solutions/) by Dimitri Vanoverbeke @ Percona|Article|A good overview of the MySQL replication landscape for developer.|
