---
date: "2024-05-31T11:31:00-04:00"
title: "Why MySQL Replication Is Fast"
tags: ["mysql", "replication", "lag"]
comments: true
aliases:
  - /post/why-mysql-replication-is-fast/
disqus_url: "https://hackmysql.com/post/why-mysql-replication-is-fast/"
---

Replication being slow&mdash;replication lag&mdash;is a common complaint, but MySQL replication is actually really fast.
Let's run a controlled experiment and peek inside the Performance Schema and binary logs to see why.

<!--more-->

Simple setup:

* MySQL 8.0.30 Community Edition
* Source to replica, async, [RBR](https://dev.mysql.com/doc/refman/8.0/en/replication-formats.html)[^1]
* Table with 1M rows

[^1]: Like most MySQL geeks, I call it "row-based replication" (RBR), but the manual calls it "row-based logging" (RBL) in some places but also RBR in other places, like https://dev.mysql.com/doc/refman/8.0/en/replication-sbr-rbr.html.

The query is intentionally slow:

```
# User@Host: finch[finch] @  [127.0.0.1]  Id:   667
# Query_time: 0.935310  Lock_time: 0.000011 Rows_sent: 0  Rows_examined: 1000000 Thread_id: 667 Errno: 0 Killed: 0 Bytes_received: 66 Bytes_sent: 62 Read_first: 1 Read_last: 0 Read_key: 1
Read_next: 0 Read_prev: 0 Read_rnd: 0 Read_rnd_next: 1000001 Sort_merge_passes: 0 Sort_range_count: 0 Sort_rows: 0 Sort_scan_count: 0 Created_tmp_disk_tables: 0 Created_tmp_tables: 0

UPDATE lag_test SET y = y + 1 WHERE x between 76091 and 81090;
```

That query is slow because `x` is not indexed.
From the slow log snippet above, the query took 935 ms (`Query_time: 0.935310`) due to scanning all 1M rows (`Rows_examined: 1000000`).
What we don't see is that it matched and updated 50,194 row:

```
mysql> SELECT COUNT(*) FROM lag_test WHERE x BETWEEN 76091 and 81090;
+----------+
| count(*) |
+----------+
|    50194 |
+----------+
```

On the replica, this "query" is a lot faster:

|Source|Replica|Speed Up|
|------|-------|--------|
|935 ms|457 ms|2x|

I quoted "query" because on a replica it's not a query, it's a binary log event and row images&mdash;more on this later.

First, the important and interesting learning is how to obtain this execution time (457 ms) on a replica with RBR.
With RBR there are no queries and, therefore, nothing in the slow query log.
But the MySQL 8.x Performance Schema has tables for replication status, primarily these three:

```
replication_connection_status
└── replication_applier_status_by_coordinator
    └── replication_applier_status_by_worker
```

Like most Performance Schema tables, it's a jungle that's not easy to traverse or navigate (by necessity, not bad design, because there's _a lot_ of information in a complex RDBMS like MySQL).
Read more about the [replication tables](https://dev.mysql.com/doc/refman/8.0/en/performance-schema-replication-tables.html) if you're curious; for now, here's the simple query I used:

```sql
SELECT
  WORKER_ID,
  LAST_APPLIED_TRANSACTION,
  LAST_APPLIED_TRANSACTION_START_APPLY_TIMESTAMP,
  LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP
FROM
  replication_applier_status_by_worker;
```

Before the slow query:

```
+-----------+-------------------------------------------+------------------------------------------------+----------------------------------------------+
| WORKER_ID | LAST_APPLIED_TRANSACTION                  | LAST_APPLIED_TRANSACTION_START_APPLY_TIMESTAMP | LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP |
+-----------+-------------------------------------------+------------------------------------------------+----------------------------------------------+
|         1 | 3930bd5c-1521-11ef-a9a6-0242ac110004:6823 | 2024-05-20 16:31:50.875572                     | 2024-05-20 16:31:54.505100                   |
|         2 | 3930bd5c-1521-11ef-a9a6-0242ac110004:6821 | 2024-05-20 16:31:50.167595                     | 2024-05-20 16:31:54.083988                   |
|         3 | 3930bd5c-1521-11ef-a9a6-0242ac110004:6825 | 2024-05-20 20:30:10.122210                     | 2024-05-20 20:30:10.166972                   |
|         4 | 3930bd5c-1521-11ef-a9a6-0242ac110004:7120 | 2024-05-28 14:35:57.680130                     | 2024-05-28 14:35:58.123873                   |
+-----------+-------------------------------------------+------------------------------------------------+----------------------------------------------+
```

After the slow query:

```
+-----------+-------------------------------------------+------------------------------------------------+----------------------------------------------+
| WORKER_ID | LAST_APPLIED_TRANSACTION                  | LAST_APPLIED_TRANSACTION_START_APPLY_TIMESTAMP | LAST_APPLIED_TRANSACTION_END_APPLY_TIMESTAMP |
+-----------+-------------------------------------------+------------------------------------------------+----------------------------------------------+
|         1 | 3930bd5c-1521-11ef-a9a6-0242ac110004:6823 | 2024-05-20 16:31:50.875572                     | 2024-05-20 16:31:54.505100                   |
|         2 | 3930bd5c-1521-11ef-a9a6-0242ac110004:6821 | 2024-05-20 16:31:50.167595                     | 2024-05-20 16:31:54.083988                   |
|         3 | 3930bd5c-1521-11ef-a9a6-0242ac110004:6825 | 2024-05-20 20:30:10.122210                     | 2024-05-20 20:30:10.166972                   |
|         4 | 3930bd5c-1521-11ef-a9a6-0242ac110004:7121 | 2024-05-28 14:39:26.420498                     | 2024-05-28 14:39:26.877415                   |
+-----------+-------------------------------------------+------------------------------------------------+----------------------------------------------+
```

As of MySQL 8.0.27, [`replica_parallel_workers`](https://dev.mysql.com/doc/refman/8.0/en/replication-options-replica.html#sysvar_replica_parallel_workers) defaults to 4.
In this case, worker 4 applied the slow query: its `LAST_APPLIED_TRANSACTION` (GTID) changed from `:7120` to `:7121`.
I show this to make sure and prove that the replica executed _only_ the slow query, so the timestamps (3rd and 4th columns, scroll &rarr;) are valid.

The seconds from the timestamps after are 26.877415 - 26.420498 = 0.456917 (457 ms).


In production these numbers will change rapidly, so maybe they're less useful in practice.
But in a controlled lab like I'm using, they're helpful to make these kinds of demonstrations.

Back to what I mentioned earlier: this isn't a "query", it's a binary log event with row images.
Let's see those:

```sh
mysqlbinlog ./replica-bin.000004 --include-gtids '3930bd5c-1521-11ef-a9a6-0242ac110004:7121' --base64-output=decode-rows -v
```

Your values will differ, but in this example notice that I'm dumping the GTID of the slow query observed earlier.
The output will probably be voluminous, but here's a snippet:

```
SET @@SESSION.GTID_NEXT= '3930bd5c-1521-11ef-a9a6-0242ac110004:7121'/*!*/;
# at 892492994
#240528 10:39:25 server id 1  end_log_pos 892493063 CRC32 0xa2d13394    Query   thread_id=667   exec_time=1     error_code=0
SET TIMESTAMP=1716907165/*!*/;
SET @@session.pseudo_thread_id=667/*!*/;
SET @@session.foreign_key_checks=1, @@session.sql_auto_is_null=0, @@session.unique_checks=1, @@session.autocommit=1/*!*/;
BEGIN
/*!*/;
# at 892493063
#240528 10:39:25 server id 1  end_log_pos 892493118 CRC32 0xb974c346    Table_map: `db1`.`lag_test` mapped to number 205
# at 892493118
#240528 10:39:25 server id 1  end_log_pos 892501318 CRC32 0x4d350fab    Update_rows: table id 205
# at 892501318
#240528 10:39:25 server id 1  end_log_pos 892509518 CRC32 0xd7c9c049    Update_rows: table id 205
# at 892509518
#240528 10:39:25 server id 1  end_log_pos 892517718 CRC32 0x15119adf    Update_rows: table id 205

...

# at 893796918
#240528 10:39:25 server id 1  end_log_pos 893803922 CRC32 0x5f652cf1    Update_rows: table id 205 flags: STMT_END_F
### UPDATE `db1`.`lag_test`
### WHERE
###   @1=60
###   @2=79247
###   @3=30845
### SET
###   @1=60
###   @2=79247
###   @3=30846
### UPDATE `db1`.`lag_test`
### WHERE
###   @1=62
###   @2=76668
###   @3=63476
### SET
###   @1=62
###   @2=76668
###   @3=63477
### UPDATE `db1`.`lag_test`
### WHERE
###   @1=63
###   @2=77162
###   @3=56725
### SET
###   @1=63
###   @2=77162
###   @3=56726

...

# at 893803922
#240528 10:39:25 server id 1  end_log_pos 893803953 CRC32 0x5c57b127    Xid = 14615
COMMIT/*!*/;
```

There's no query, there's just that transaction and rows images that decode to pseudo UPDATE statements.
How many row images/pseudo UPDATES?

```bash
$ grep -c UPDATE out
50194
```

The same number of rows the original query matched and updated: 50,194.

<mark>With row-based replication, replicas are much faster than the source because they don't execute queries, they apply the data changes (as row images) to the table.</mark>
Moreover, they should apply data changes by primary key lookup (because sane InnoDB tables have an explicitly defined primary key).
In this example, `@1` is the first column and primary key.
So the _pseudo_ UPDATE for the first row image is `UPDATE lag_test SET y=30846 WHERE id=60`.
Whereas the source had to read and filter 1M rows (full table scan) and make 50,194 updates, the replica only does the latter: 50,194 point updates by primary key.

Of course, this example was concocted to make a point.
Not all queries exhibit this great a difference&mdash;performance always depends on the workload.
But the general idea holds true: a source does all the work to execute a write, then it logs the specific data changes, and a replica does far less work to apply those data changes.
This is one reason why MySQL replication is fast.

Another reason has become the default with MySQL 8.x: multi-threaded replication (MTR).
(Not to be confused with [multi-source replication](https://dev.mysql.com/doc/refman/8.0/en/replication-multi-source.html).)
Check out [A Dive Into MySQL Multi-Threaded Replication](https://www.percona.com/blog/a-dive-into-mysql-multi-threaded-replication/) by Yves and Francisco at Percona to learn more.

In practice, MySQL replication is usually fast.
But if it begins to lag, knowing what's going on under the hood will help you understand why.
For example, RBR has a flip side that this example demonstrated: 1 query generated 50,194 row images.
Extreme cases can "flip the script" such that a query is fast and easy on the source but generates so many row images that it overloads replication. 
And while MTR should help by parallelizing the application of binary log events, how well (or how much) a workload can be parallelized is another issue&mdash;you might find that a MySQL replica doesn't keep 4  workers busy.

Bottom line: MySQL replication is fast and also quite complex.
