---
date: "2021-07-26T15:40:00-04:00"
title: "MySQL Data Locks: Mapping 8.0 to 5.7"
tags: ["mysql", "data-locks"]
aliases:
  - /mysql-data-locks
  - /post/mysql-data-locks-mapping-80-to-57/
params:
  path: trx
---

As of MySQL 8.0, [`performance_schema.data_locks`](https://dev.mysql.com/doc/refman/8.0/en/performance-schema-data-locks-table.html) shows InnoDB data locks.
Before MySQL 8.0, you must `SET GLOBAL innodb_status_output_locks=ON` and ruminate on the output of `SHOW ENGINE INNODB STATUS`.
The image below (click to see full size) shows how the former maps to the latter for three record locks and one table lock on table `t`.

<a href="/img/mysql-data-locks-mapped-to-innodb-engine-status-locks.png">
<img src="/img/mysql-data-locks-mapped-to-innodb-engine-status-locks.png">
</a>

Information Schema tables `INNODB_LOCKS` and `INNODB_LOCK_WAITS` are deprecated as of MySQL 5.7 and removed as of MySQL 8.0.
They are better than nothing, but ["Persistence and Consistency of InnoDB Transaction and Locking Information"](https://dev.mysql.com/doc/refman/5.7/en/innodb-information-schema-internal-data.html) cautions their usage.
Moreover, `INNODB_LOCKS` only shows locks blocking other transactions, which makes it unsuitable to examine InnoDB row locking without a blocking transaction.
