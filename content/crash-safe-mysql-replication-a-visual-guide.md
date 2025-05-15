---
type: "page"
date: "2018-01-23T18:40:00-07:00"
title: "Crash-safe MySQL Replication"
subtitle: "A Visual Guide"
tags: ["mysql", "crash-safe", "replication", "gtid"]
comments: true
aliases:
  - /post/crash-safe-mysql-replication-a-visual-guide/
disqus_url: "https://hackmysql.com/post/crash-safe-mysql-replication-a-visual-guide/"
params:
  path: repl
---

MySQL crash-safe replication is an old feature (~4 years as of MySQL 5.6), but it's not consistently understood or applied. The MySQL manual on the topic, [16.3.2 Handling an Unexpected Halt of a Replication Slave](https://dev.mysql.com/doc/refman/5.7/en/replication-solutions-unexpected-slave-halt.html), is correct and authoritative, but unless you grok MySQL replication that page doesn't make it obvious _why_ crash-safe replication works. Other blog posts explain why, but sometimes add other considerations, making it unclear which settings are necessary and sufficient. The aim of this blog post is total enlightenment, a full crash-safe-spiritual awakening. Light the censers and let us begin at the beginning...

## TL;DR

Presuming,

* MySQL 5.6 or later
* Single-threaded replication
* InnoDB tables only
* _Not_ GTID (discussed below)
* MySQL crashes [1]

<small>[1] The manual distinguishes crash types: server (MySQL) vs. OS. _There are no crash-safe guarantees for an OS crash!_ MySQL can't guarantee anything for lower-level failures, like OS and hardware crashes. However, my experience is that crash-safe replication often saves the replica even for lower-level failures. But remember: the only guarantee is for MySQL crashes, nothing else.</small>

only two settings are necessary and sufficient:

* `relay_log_info_repository = TABLE`
* `relay_log_recovery = ON`

That seems too simple to believe, so let's dive into the how and why.

## How and Why Crash-safe Replication Works

![MySQL Crash-safe Replication](/img/mysql-crash-safe-replication.svg)

Only the green elements are involved in crash-safe replication. You can see the two required settings are green, but other related settings are white because they do _not_ effect crash-safe replication. They're related but not necessary. Let's walk through the process and focus on what the necessary and sufficient:

1. IO thread writes binlog data from master to a relay log on replica.
2. IO thread updates [master info](https://dev.mysql.com/doc/refman/5.7/en/slave-logs-status.html) table, depending on `sync_master_info`. This is called "master info" because replica relay logs correspond to master binlogs.
3. SQL thread reads a transaction from a relay log.
4. SQL thread executes the transaction which writes to the database _and_, in the same transaction, writes to (updates) [relay log info](https://dev.mysql.com/doc/refman/5.7/en/slave-logs-status.html) table. This is called "relay log info" because it corresponds to replica relay logs.

Step 4 is where the magic happens. Let's zoom in:

![MySQL Crash-safe Transaction](/img/mysql-crash-safe-trx.svg)

The SQL thread has _two_ transactions: the green is the user's transaction from the relay log, and the blue is the relay log coordinates corresponding to the user's transaction. The SQL thread combines these into a single transaction and executes it as usual. MySQL and InnoDB form a reliable, ACID-compliant database, so we're guaranteed that relay log info accurately reflects applied user transactions; the two cannot come apart because they are committed in the same transaction.

In this example, if the relay log info table has the values in blue, we're guaranteed that the database is consistent up to and including the user transaction in green, no more and no less.

## Crash

When MySQL crashes and starts again, it detects the crash and begins to recover because `relay_log_recovery = ON`. This is a simplification but it serves the purpose here. Recovery relies on two simple but important facts:

1. The SQL thread position is always <= the IO thread position
2. The SQL thread position is authoritative wrt committed transactions

Number 1 is necessarily true because the SQL thread cannot read data that doesn't exist. In other words: the SQL thread is always behind and chasing the IO thread. Sometimes the SQL thread catches up (the two are equal), but the SQL thread cannot surpass the IO thread. Number 2 follows because we don't really care where the IO thread is, we care where the SQL thread is because it's executing transactions, writing data. Let's visualize it:

![MySQL Crash-safe Relay Log](/img/mysql-crash-safe-relay-log.svg)

Blue means committed, green means executing. `pos` is an offset, so the second transaction starts at file offset 100. On the left, the IO thread has fetched three transactions, and the SQL thread is in the middle of executing the second. Since the SQL thread has _not_ committed the second transaction, the relay log info contains `pos: 100` (end of first transaction, start of second) because only the first transaction has been committed. When MySQL crashes and restarts, it recovers by setting both IO and SQL threads back to `pos: 100` and discarding relay log data after this pos (the second and third transactions). The IO thread will re-fetch the data and, once it does, the SQL thread will resume executing from `pos: 100`. Yes, the SQL thread will re-execute the second transaction, but that's ok because it was not committed before the crash. MySQL and InnoDB are awesome!

## Unnecessary Settings

From the previous two sections, it's more clear why other settings are unnecessary. Let's address them specifically:

* `%master_info%`: These settings play _no role_ in crash-safe replication or recovery. Master info (in table or file) seems to have no functional purpose. This is especially true with `relay_log_recovery = ON` which makes relay logs disposable, so IO thread status (which updates master info) no longer matters. Master info is also out of date unless `sync_master_info` is a very low value (like 1), but a very low value should _not_ be used because it can cause too much overhead (on storage, replication, or both). Moreover, master info is available and always up-to-date in `SHOW SLAVE STATUS`. So master info (in table or file) seems to have no purpose, but since the variables exist nonetheless I suggest `master_info_repository = TABLE` for uniformity with `relay_log_info_repository = TABLE`, and `syn_master_info = 0` (the default value).

* `sync_relay_log_info`: With `relay_log_info_repository = TABLE` (one of two necessary and sufficient settings), [the manual for this variable](https://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html#sysvar_sync_relay_log_info) says it's "effectively ignored". This makes sense because, as described and illustrated above, the SQL thread updates the relay log info table automatically with every user transaction, so there's no need for additional syncs. Note, however: "effectively ignored" is unclear. From my experience, MySQL seems to always respect this variable, so setting it to 1 can cause heavy lag if the master is doing high levels of transactions per second. In short: leave `sync_relay_log_info` set to default (usually 10000), or at least 1000; do _not_ set to 1 for crash-safe replication.

* `sync_relay_log` (not shown): This setting is _not_ required for crash-safe replication because with `relay_log_recovery = ON` relay logs are disposable, therefore we don't need to explicitly sync them to disk. I suggest leaving this settings on its default, 0 or 10,000 (depending on MySQL version); do _not_ set to 1 even though the manual says, "A value of 1 is the safest choice because in the event of a crash you lose at most one event from the relay log." because, again, with `relay_log_recovery = ON` relay logs are disposable.

## Disposable Relay Logs

Making relay logs disposable with `relay_log_recovery = ON` has two implications DBAs need to consider:

1. The master must keep binlogs long enough for crashed replicas to recover. If the master is purging binlogs too soon, or a DBA purges binlogs for some reason, a crashed replica might not be able to recover automatically. If that happens, the replica to be rebuilt completely (restore backup, etc.).
2. Fetching binlogs from master could cause load on the master or the network if the binlogs are huge.

## GTID

In addition to normal replication mechanisms (binary/relay logs, IO/SQL threads, master/relay log info), GTID-based replication relies on the _replica's_ binary logs. [2] Therefore, two additional settings are required:

* `sync_binlog = 1`
* `innodb_flush_log_at_trx_commit = 1`

<small>[2] MySQL 5.7 allows GTID-based replication without replica binary logs (`log_slave_updates = FALSE`), but for simplicity let's presume the common case: replicas having their own binary logs.</small>

These settings should _always_ be used, and they are necessary for crash-safe GTID-based replication because they almost guarantee that replica binary logs are kept in sync with applied transactions. I say "almost" because, although binary logs are considered authoritative, they are separate data from the data they reflect, so there's a chance the two can come apart. However, with these settings that chance is so small that it's usually treated as a guarantee.

With GTID-based replication, MySQL must know which [GTID sets](https://dev.mysql.com/doc/refman/5.7/en/replication-gtids-concepts.html) have been executed so it doesn't execute them again. Executed GTID sets are written to binary logs, so when MySQL starts it scans its binary logs to determine which GTID sets have been executed; this initializes [gtid_executed](https://dev.mysql.com/doc/refman/5.7/en/replication-options-gtids.html#sysvar_gtid_executed) and [gtid_purged](https://dev.mysql.com/doc/refman/5.7/en/replication-options-gtids.html#sysvar_gtid_purged).

After scanning binary logs to reinitialize `gtid_executed` and `gtid_purged`, MySQL is ready to deal with binary and relay logs again. Let's limit the discussion to the settings listed here because the manual says:

> When using GTIDs and MASTER_AUTO_POSITION, set `relay_log_recovery=1`. With this configuration the setting of `relay_log_info_repository` and other variables does not impact on [sic] recovery.

Let's visualize it:

![MySQL Crash-safe GTD](/img/mysql-crash-safe-gtid.svg)

Like the previous crash example, blue is committed and green is executing, but unlike the previous crash example, transactions are identified by GTID values like `ABC:5` (real GTID are much longer) and there are no relay log pos. The first transaction (`ABC:3`) has been committed and logged in the replica's binary log, and the second transaction (`ABC:4`) is being executed when the replica crashes. The simplified recovery sequence is:

1. Start scanning master binary logs for last GTID set in replica binary logs: `ABC:3`
2. Keep scanning master binary logs until `ABC:3` is found
3. IO thread re-fetches binlog data starting at next transaction

With `MASTER_AUTO_POSITION = 1` (shown as `Auto_Position: 1` in `SHOW SLAVE STATUS`) and `relay_log_recovery = ON`, MySQL ignores relay logs _and_ relay log info (SQL thread file and pos); instead, it searches the master's binary logs for the first GTID set _not_ executed. The IO thread re-fetches binlogs from that location (in the master's binary log), and replication resumes as normal. With GTID-based replication, binary and relay log files still exist and function the same, but the focus for the DBA (and tooling) is executed/purged GTID sets.

`MASTER_AUTO_POSITION = 0` is possible but not advisable. The manual says next to nothing about this situation. I've seen it once in a cluster that enabled GTID temporarily. It's best to avoid. Upgrade all nodes in the cluster to GTID (and use the settings listed here), or none of them (and use traditional replication with crash-safe settings).

## Quick Reference

For crash-safe single-threaded MySQL replication, the necessary and sufficient settings are:

* MySQL 5.6 or later
* InnoDB tables only
* `relay_log_info_repository = TABLE`
* `relay_log_recovery = ON`
* `sync_binlog = 1`
* `innodb_flush_log_at_trx_commit = 1`
* `MASTER_AUTO_POSITION = 1` if GTID

And the authoritative source for applied transactions is:

| Classic Replication | GTID |
| ------- | ---- |
| SQL thread coordinates in `mysql.slave_relay_log_info` | GTID set in replica binary logs |

---

## Credits

Thank you to, 

* Ryan Lowe
* Emily Slocombe
* Mark Filipi
* Ivan Groenewold
* [Kenny Gryp](https://www.percona.com/blog/author/gryp/)
* [Shlomi Noach](http://code.openark.org/blog/)
* Jean-François Gagné
  * [Better Crash-safe replication for MySQL](https://blog.booking.com/better_crash_safe_replication_for_mysql.html)
  * [A discussion about sync-master-info and other replication parameters](http://jfg-mysql.blogspot.nl/2016/08/discussion-about-sync-master-info-and-replication-parameters.html)
* Evan Elias
  * [Lessons from Deploying MySQL GTID at Scale](https://code.facebook.com/posts/1542273532669494/lessons-from-deploying-mysql-gtid-at-scale/)
* Mats Kindahl
  * [Crash-safe Replication](http://mysqlmusings.blogspot.com/2011/04/crash-safe-replication.html)
* MySQL Server Blog
  * [Relay Log Recovery when SQL Thread’s Position is Unavailable](https://mysqlserverteam.com/relay-log-recovery-when-sql-threads-position-is-unavailable/)
* Percona
  * [Enabling crash-safe slaves with MySQL 5.6](https://www.percona.com/blog/2013/09/13/enabling-crash-safe-slaves-with-mysql-5-6/)

who provided direct and indirect help via discussions, blog posts, etc.
