---
date: "2005-12-23T00:00:00-05:00"
lastMod: "2024-06-05T11:09:00-05:00"
title: "MySQL Select and Sort Status Variables"
summary: "A deep dive into the MySQL select and sort status variables"
tags: ["mysql", "sysvar"]
aliases:
  - /selectandsort
---

This page is a reboot of the original written 15 years ago in 2005.
Back then, I must have been using MySQL 4.1 or 5.0.
Today, I am using MySQL 8.0.22.
A lot changed in MySQL from 4.1 to 8.0, but it still has the same `Select_%` and `Sort_%` status variables which are equally important today in 2021.
Let's examine them in greater detail and with better examples.

The MySQL `Select_%` and `Sort_%` status variables (metrics) are:

* `Select_scan`
* `Select_range`
* `Select_full_join`
* `Select_full_range_join`
* `Select_range_check`
* `Sort_scan`
* `Sort_range`
* `Sort_merge_passes`
* `Sort_rows`

Using MySQL 8.0.22 Community, the test tables are:

```
CREATE TABLE `t1` (
  `id` int NOT NULL AUTO_INCREMENT,
  `c1` int NOT NULL,
  `c2` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `c1` (`c1`)
) ENGINE=InnoDB 

CREATE TABLE `t2` (
  `id` int NOT NULL AUTO_INCREMENT,
  `c1` int NOT NULL,
  `c2` int NOT NULL,
  PRIMARY KEY (`id`),
  KEY `c1` (`c1`)
) ENGINE=InnoDB
```

Each table has about 30 rows.

## Select

| Metric | First Table | Join Table |
| ------ | ----------- | ---------- |
|`Select_scan`            |&check;|| 
|`Select_range`           |&check; || 
|`Select_full_join`       || &check;|
|`Select_full_range_join` || &check;|
|`Select_range_check`     || &check;|

`Select_scan` and `Select_range` apply to the first (or only) table. `Select_full_join`, `Select_full_range_join`, and `Select_range_check` apply to the second and subsequent tables.

MySQL table join order is determined by the query planner (to create the best execution plan) not the [JOIN clause](https://dev.mysql.com/doc/refman/8.0/en/join.html) clause (unless STRAIGHT_JOIN is used).

```
mysql> EXPLAIN SELECT * FROM t1, t2 WHERE t1.c1 = t2.c2 ORDER BY t1.c2;
+-------------+-------+------+---------------+------+---------+------------+------+----------+---------------------------------+
| select_type | table | type | possible_keys | key  | key_len | ref        | rows | filtered | Extra                           |
+-------------+-------+------+---------------+------+---------+------------+------+----------+---------------------------------+
| SIMPLE      | t2    | ALL  | NULL          | NULL | NULL    | NULL       |   26 |   100.00 | Using temporary; Using filesort |
| SIMPLE      | t1    | ref  | c1            | c1   | 4       | test.t2.c2 |    1 |   100.00 | NULL                            |
+-------------+-------+------+---------------+------+---------+------------+------+----------+---------------------------------+

mysql> EXPLAIN FORMAT=TREE SELECT * FROM t1, t2 WHERE t1.c1 = t2.c2 ORDER BY t1.c2;
+-------------------------------------------------------------------------+
| EXPLAIN                                                                 |
+-------------------------------------------------------------------------+
| -> Sort: t1.c2
    -> Stream results  (cost=11.95 rows=26)
        -> Nested loop inner join  (cost=11.95 rows=26)
            -> Table scan on t2  (cost=2.85 rows=26)
            -> Index lookup on t1 using c1 (c1=t2.c2)  (cost=0.25 rows=1) |
+-------------------------------------------------------------------------+
```

Top output is a standard EXPLAIN plan with the first table on top, so `t2` is the first table and `t1` is the second table. Note that the tables are listed differently in the FROM clause. MySQL is accessing table `t2` first because it produces a better execution plan which you can see in detail by [tracing the optimizer](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_OPT_TRACE.html#USER_ENABLE_TRACING).

Bottom output is an "EXPLAIN tree" which is new as of MySQL 8.0. It shows the query execution plan _from the bottom up, per-node_. The EXPLAIN tree reads:

1. Nested loop inner join
   1. Table scan on t2
   1. Index lookup on t1 using c1 (c1=t2.c2)
1. Stream results
1. Sort: t1.c2

Step 3 refers to "Using temporary" in the EXPLAIN plan, and step 4 refers to "Using filesort". See [How MySQL executes ORDER BY](https://petrunia.net/2007/08/29/how-mysql-executes-order-by/) by Sergei Petrunia for a beautifully illustrated explanation of MySQL ORDER BY.

The first table, `t2`, is a table scan ("type: ALL"), so `Select_scan` will be incremented. The second table, `t1`, is neither a table scan nor a range scan, so no metric will be incremented because there are no select metrics for other [join types](https://dev.mysql.com/doc/refman/8.0/en/explain-output.html#explain-join-types). Let's clear the session metrics, execute the query, and check the select metrics:

```
mysql> FLUSH STATUS;

mysql> SELECT * FROM t1, t2 WHERE t1.c1 = t2.c2 ORDER BY t1.c2;
--
-- Output removed
--
20 rows in set (0.00 sec)

mysql> SHOW SESSION STATUS LIKE 'Select_%';
+------------------------+-------+
| Variable_name          | Value |
+------------------------+-------+
| Select_full_join       | 0     |
| Select_full_range_join | 0     |
| Select_range           | 0     |
| Select_range_check     | 0     |
| Select_scan            | 1     | -- t2
+------------------------+-------+
```

As expected, `Select_scan` = 1 due to the table scan on `t2`.

### Select_scan

`Select_scan` refers to the first table in a join, or the only table if there is only one table. It means MySQL did a table _or_ index scan. For such tables, EXPLAIN lists "ALL" or "index" in the "type" column.

Table scans ("type: ALL") are usually (but not always) terrible for performance because reading an entire table is slow. However, table scans are common. It's not uncommon to see a server where 50% of all SELECT queries are `Select_scan`. A SELECT results in a table scan when no index can be used to for the WHERE conditions. From a performance perspective it's safe to say that you always want to decrease `Select_scan`&mdash;zero is best. However, in some cases the value of `Select_scan` can increase after optimizing queries because MySQL is able to do more. Ultimately, `Select_scan` is a performance limiter which should decrease to allow increased overall QPS (queries per second).

Index scans ("type: index") are better than table scans, especially when "Extra: Using index" appears in the EXPLAIN plan which means a covering index is being used. Without "Using index", the query is still a full table scan but MySQL uses the index to read rows in order, which is usually the result of an [ORDER BY optimization](https://dev.mysql.com/doc/refman/5.7/en/order-by-optimization.html).

### Select_range

`Select_range` refers to the first table in a join, or the only table if there is only one table. It means MySQL read a range of rows from the table. For such tables, EXPLAIN lists "type: range". MySQL used an index to limit table reads to rows within the range, which saves time that would otherwise be wasted on disk seeks for non-matching rows. Therefore, `Select_range` is a lot faster than `Select_scan`. A query like `SELECT * FROM t1 WHERE c1 > 5 AND c1 < 13` specifies an exclusive range between 5 and 13.. Since column `c1` is indexed, MySQL reads the index for the range to find and read only rows in that range. If `c1` was not indexed, MySQL would have to do a full table scan. See [Range Optimization](https://dev.mysql.com/doc/refman/8.0/en/range-optimization.html) for a lot more details.

### Select_full_join

`Select_full_join` refers to the second or greater table in a join. It means MySQL did a table scan to join the table to the preceding table. For such tables, EXPLAIN lists "ALL" in the "type" column. `Select_full_join` results when no index can be used to join the table. Like `Select_scan`, this is a performance limiter that should be avoided.

The worst case is a table scan on both join tables:

```
mysql> EXPLAIN SELECT * FROM t1, t2 WHERE t1.c2 = t2.c2 ;
+-------------+-------+------+---------------+------+---------+------+------+----------+--------------------------------------------+
| select_type | table | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra                                      |
+-------------+-------+------+---------------+------+---------+------+------+----------+--------------------------------------------+
| SIMPLE      | t1    | ALL  | NULL          | NULL | NULL    | NULL |   20 |   100.00 | NULL                                       |
| SIMPLE      | t2    | ALL  | NULL          | NULL | NULL    | NULL |   26 |    10.00 | Using where; Using join buffer (hash join) |
+-------------+-------+------+---------------+------+---------+------+------+----------+--------------------------------------------+

mysql> EXPLAIN FORMAT=TREE SELECT * FROM t1, t2 WHERE t1.c2 = t2.c2 ;
+-------------------------------------------------------------------------+
| EXPLAIN                                                                 |
+-------------------------------------------------------------------------+
| -> Inner hash join (t2.c2 = t1.c2)  (cost=54.50 rows=52)
    -> Table scan on t2  (cost=0.03 rows=26)
    -> Hash
        -> Table scan on t1  (cost=2.25 rows=20)                          |
+-------------------------------------------------------------------------+

mysql> SHOW SESSION STATUS LIKE 'Select_%';
+------------------------+-------+
| Variable_name          | Value |
+------------------------+-------+
| Select_full_join       | 1     | -- t2
| Select_full_range_join | 0     |
| Select_range           | 0     |
| Select_range_check     | 0     |
| Select_scan            | 1     | -- t1
+------------------------+-------+
```

The "type: ALL" for both tables indicates a table scan. `Select_full_join` was incremented for the table scan on the second table (`t2`), and `Select_scan` was incremented for the table scan on the first table (`t1`). This query does table scans because the tables are joined on column `c2` which is not indexed on either table.

This is the worst case because, as the MySQL manual notes:

> Because type is ALL for each table, this output indicates that MySQL is generating a Cartesian product of all the tables; that is, every combination of rows. This takes quite a long time, because the product of the number of rows in each table must be examined. 

The first table has 20 rows and the second has 26 rows, so the result is 20 * 26 = 520 rows. The worst I have ever seen was a three table join that caused a cross product of 112 billion rows (actually, the query never finished before it caused the server to halt). With only 1,000 rows in each table, the product is 1 million rows which will be noticeably slow.

Both EXPLAIN outputs show another new feature in MySQL 8.0: [hash joins](https://dev.mysql.com/doc/refman/8.0/en/hash-joins.html). See [Hash join in MySQL 8](https://dev.mysql.com/blog-archive/hash-join-in-mysql-8/) by the MySQL Server Team for an illustrated explanation. 

### Select_full_range_join

`Select_full_range_join` refers to the second or greater table in a join. It means MySQL joined the table to the preceding table using a range scan, which is significantly better than `Select_full_join`. For such tables, EXPLAIN lists "type: range". Like `Select_range`, `Select_full_range_join` requires an index and the same [range optimizations](https://dev.mysql.com/doc/refman/8.0/en/range-optimization.html) apply.

```
mysql> EXPLAIN SELECT * FROM t1, t2 WHERE t1.c1 = 10 AND t2.c1 > 13;
+-------------+-------+-------+---------------+------+---------+-------+------+----------+------------------------------------------------------+
| select_type | table | type  | possible_keys | key  | key_len | ref   | rows | filtered | Extra                                                |
+-------------+-------+-------+---------------+------+---------+-------+------+----------+------------------------------------------------------+
| SIMPLE      | t1    | ref   | c1            | c1   | 4       | const |    1 |   100.00 | NULL                                                 |
| SIMPLE      | t2    | range | c1            | c1   | 4       | NULL  |   13 |   100.00 | Using index condition; Using join buffer (hash join) |
+-------------+-------+-------+---------------+------+---------+-------+------+----------+------------------------------------------------------+

mysql> EXPLAIN FORMAT=TREE SELECT * FROM t1, t2 WHERE t1.c1 = 10 AND t2.c1 > 13;
+-----------------------------------------------------------------------------------------------+
| EXPLAIN                                                                                                                                                                                                                                     |
+-----------------------------------------------------------------------------------------------+
| -> Inner hash join (no condition)  (cost=6.46 rows=13)
    -> Index range scan on t2 using c1, with index condition: (t2.c1 > 13)  (cost=6.11 rows=13)
    -> Hash
        -> Index lookup on t1 using c1 (c1=10)  (cost=0.35 rows=1)                              |
+-----------------------------------------------------------------------------------------------+

mysql> SHOW STATUS LIKE 'Select_%';
+------------------------+-------+
| Variable_name          | Value |
+------------------------+-------+
| Select_full_join       | 0     |
| Select_full_range_join | 1     | -- t2
| Select_range           | 0     |
| Select_range_check     | 0     |
| Select_scan            | 0     |
+------------------------+-------+
```

Note that the condition on `t1` is constant: `t1.c1 = 10`. Since MySQL knows column values from the preceding table (`t1`), it also knows that it can use those column values to range scan the join table (`t2`). This is not always the case, as the next select metric indicates.

### Select_range_check

`Select_range_check` refers to the second or greater table in a join. It means "MySQL checks whether it is possible to use a range or index_merge access method to retrieve rows." In other words, it means MySQL wants to do `Select_full_range_join` but cannot because it does not know the column values from the preceding table, so it checks the index on the join table for each new row (column values) from the preceding table.

```
mysql> EXPLAIN SELECT * FROM t1, t2 WHERE t1.c1 > t2.c1;
+-------------+-------+------+---------------+------+---------+------+------+----------+------------------------------------------------+
| select_type | table | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra                                          |
+-------------+-------+------+---------------+------+---------+------+------+----------+------------------------------------------------+
| SIMPLE      | t1    | ALL  | c1            | NULL | NULL    | NULL |   20 |   100.00 | NULL                                           |
| SIMPLE      | t2    | ALL  | c1            | NULL | NULL    | NULL |   26 |    33.33 | Range checked for each record (index map: 0x2) |
+-------------+-------+------+---------------+------+---------+------+------+----------+------------------------------------------------+

mysql> EXPLAIN FORMAT=TREE SELECT * FROM t1, t2 WHERE t1.c1 > t2.c1;
+--------------------------------------------------------------------------------------+
| EXPLAIN                                                                              |
+--------------------------------------------------------------------------------------+
| -> Nested loop inner join  (cost=54.50 rows=173)
    -> Table scan on t1  (cost=2.25 rows=20)
    -> Filter: (t1.c1 > t2.c1)  (cost=0.06 rows=9)
        -> Index range scan on t2 (re-planned for each iteration)  (cost=0.06 rows=26) |
+--------------------------------------------------------------------------------------+

mysql> SHOW SESSION STATUS LIKE 'Select_%';
+------------------------+-------+
| Variable_name          | Value |
+------------------------+-------+
| Select_full_join       | 0     |
| Select_full_range_join | 0     |
| Select_range           | 0     |
| Select_range_check     | 1     | -- t2
| Select_scan            | 1     | -- t1
+------------------------+-------+
```

The condition `t1.c1 > t2.c1` triggers the range check. As MySQL scans `t1`, it reads column `c1` values. In this example, we know the values ahead of time because the test table is tiny and static. But in a real database, table writes and transaction isolation levels mean the values can change, therefore MySQL cannot know them ahead of time. For each row, MySQL checks if can use the index on `t2.c1` to read the `t2` row matching the current `t1.c1` value. It is possible that `t1.c1` has values not in `t2.c1`.

Even if MySQL determines that it can do a range scan (or index merge), it does _not_ increment `Select_full_range_join`. Only `Select_range_check` is incremented.

See "Range checked for each record" in [EXPLAIN Output Format](https://dev.mysql.com/doc/refman/8.0/en/explain-output.html) for a good explanation.

## Sort

The sort metrics `Sort_scan`, `Sort_range`, `Sort_merge_passes`, and `Sort_rows` apply to queries that use ORDER BY or GROUP BY, regardless of how many tables.

A sort as indicated by "filesort" in EXPLAIN output. The term "filesort" is misleading. The MySQL Server Team says, "In MySQL, filesort is the catch-all algorithm for producing sorted results for ORDER-BY or GROUP-BY queries." ([Filesort optimization in 5.7.3: pack values in the sort buffer](https://dev.mysql.com/blog-archive/filesort-optimization-in-5-7-3-pack-values-in-the-sort-buffer/)) See also [What does Using filesort mean in MySQL?](https://www.percona.com/blog/2009/03/05/what-does-using-filesort-mean-in-mysql/)

Memory allocation for sorting is set by the system variable [sort_buffer_size](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_sort_buffer_size).
Resist the temptation to tune this variable or simply increase its value.
Read [More on understanding sort_buffer_size](http://ronaldbradford.com/blog/more-on-understanding-sort_buffer_size-2010-05-10/) by Ronald Bradford.
Also read [Impact of the sort buffer size in MySQL](https://www.percona.com/blog/2010/10/25/impact-of-the-sort-buffer-size-in-mysql/) by Percona.

<p class="note">
As of MySQL 8.0.12, <i>sort_buffer_size</i> is allocated incrementally as needed.
Before MySQL 8.0.12, the full size is allocated up front.
</p>

For a deeper technical understanding of sorting in MySQL 8.0, read [Sorting](http://www.unofficialmysqlguide.com/sorting.html) in _The Unofficial MySQL 8.0 Optimizer Guide_ by Morgan Tocker.

### Sort_scan

As of MySQL 8.0, `Sort_scan` is the total number of all sort operations. In MySQL 5.7 and older, `Sort_scan` was the number of sort operations for queries _not_ using a range scan; see [Sort_range]({{< ref "#sort_range" >}}).

The value of `Sort_scan` is usually very high because sorting rows is common. Monitor the rate of this metric (sort ops/second) and watch for unexpected changes.

### Sort_range

As of MySQL 8.0, `Sort_range` means nothing. The status variable remains, but the code that incremented it was removed. In MySQL 5.7 the code was in `sql/filesort.cc`:

```cpp
  if (tab->quick())
    thd->inc_status_sort_range();
  else
    thd->inc_status_sort_scan();
```

But in MySQL 8.0 that if-else block was replaced with a single line:

```cpp
  thd->inc_status_sort_scan();
```

In MySQL 5.7 and older, `Sort_range` and `Sort_scan` were mutually exclusive, as shown in the code snippet above. `Sort_range` was incremented instead of `Sort_scan` for queries using a range scan.

```
`Select_scan`  + filesort = `Sort_scan`++
`Select_range` + filesort = `Sort_range`++
```

Let's use MySQL 5.7.31 and the `salaries` table in the [employees sample database](https://dev.mysql.com/doc/employee/en/):

```
CREATE TABLE `salaries` (
  `emp_no` int(11) NOT NULL,
  `salary` int(11) NOT NULL,
  `from_date` date NOT NULL,
  `to_date` date NOT NULL,
  PRIMARY KEY (`emp_no`,`from_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
```

Column `salary` is not indexed, so the following query causes a table scan, not a range scan, which means `Sort_scan` will be incremented:

```
mysql> EXPLAIN SELECT emp_no, salary FROM salaries WHERE salary > 250000 ORDER BY emp_no, salary LIMIT 10;
+-------------+----------+------------+------+---------------+------+---------+------+---------+----------+-----------------------------+
| select_type | table    | partitions | type | possible_keys | key  | key_len | ref  | rows    | filtered | Extra                       |
+-------------+----------+------------+------+---------------+------+---------+------+---------+----------+-----------------------------+
| SIMPLE      | salaries | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 2834690 |    33.33 | Using where; Using filesort |
+-------------+----------+------------+------+---------------+------+---------+------+---------+----------+-----------------------------+

mysql> SELECT emp_no, salary FROM salaries WHERE salary > 250000 ORDER BY emp_no, salary LIMIT 10;
Empty set (0.74 sec)

mysql> SHOW SESSION STATUS LIKE 'Sort_%';
+-------------------+-------+
| Variable_name     | Value |
+-------------------+-------+
| Sort_merge_passes | 0     |
| Sort_range        | 0     |
| Sort_rows         | 0     |
| Sort_scan         | 1     | -- Due to type: ALL
+-------------------+-------+
```

Now the proof: index `salary` to cause a range scan:

```
mysql> ALTER TABLE salaries ADD INDEX (salary);
Query OK, 0 rows affected (15.52 sec)
Records: 0  Duplicates: 0  Warnings: 0

mysql> EXPLAIN SELECT emp_no, salary FROM salaries WHERE salary > 250000 ORDER BY emp_no, salary LIMIT 10;
+-------------+----------+------------+-------+---------------+--------+---------+------+------+----------+------------------------------------------+
| select_type | table    | partitions | type  | possible_keys | key    | key_len | ref  | rows | filtered | Extra                                    |
+-------------+----------+------------+-------+---------------+--------+---------+------+------+----------+------------------------------------------+
| SIMPLE      | salaries | NULL       | range | salary        | salary | 4       | NULL |    1 |   100.00 | Using where; Using index; Using filesort |
+-------------+----------+------------+-------+---------------+--------+---------+------+------+----------+------------------------------------------+

mysql> FLUSH STATUS;

mysql> SELECT emp_no, salary FROM salaries WHERE salary > 250000 ORDER BY emp_no, salary LIMIT 10;
Empty set (0.18 sec)

mysql> SHOW SESSION STATUS LIKE 'Sort_%';
+-------------------+-------+
| Variable_name     | Value |
+-------------------+-------+
| Sort_merge_passes | 0     |
| Sort_range        | 1     | -- Due to type: range
| Sort_rows         | 0     |
| Sort_scan         | 0     |
+-------------------+-------+
```

Therefore, in MySQL 5.7 and older, the total number of all sort operations is `Sort_scan + Sort_range`.

### Sort_merge_passes

`Sort_merge_passes` is the number of merge buffer operations. `Sort_merge_passes` is incremented by 1 each time function `merge_buffers()` is called (in `sql/filesort.cc`).

When [sort_buffer_size](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_sort_buffer_size) is not large enough to hold all unsorted rows, MySQL writes "merge buffers" to temporary files on disk, then merges the buffers to produce the final, sorted result.


Let's use a table with 1 million rows created by [sysbench](https://github.com/akopytov/sysbench):

```
CREATE TABLE `sbtest1` (
  `id` int NOT NULL AUTO_INCREMENT,
  `k` int NOT NULL DEFAULT '0',
  `c` char(120) NOT NULL DEFAULT '',
  `pad` char(60) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `k_1` (`k`)
) ENGINE=InnoDB AUTO_INCREMENT=1000001 DEFAULT CHARSET=utf8 |
```

The query,

```none
SELECT c FROM sbtest1 WHERE id > 100 ORDER BY c
```

produces a sorted result of 999,900 rows which does not fit in any sane `sort_buffer_size`, thereby causing merge buffers to disk and sort merge passes.

As mentioned at the beginning of the [Sort]({{< ref "#sort" >}}) section: _Resist the temptation to “tune” this variable or simply increase its value._ But to demonstrate how `sort_buffer_size` affects `Sort_merge_passes` and query response time, let's try the query above with different sort buffer sizes: 32 KB (minimum), 10 MB (very large), 32 MB (dangerous), and 128 MB (insane).


***sort_buffer_size = 32 KB (minimum)***

```
mysql> SELECT c FROM sbtest1 WHERE id > 100 ORDER BY c;
--
-- Output removed
--
999900 rows in set (3.60 sec)

mysql> SHOW SESSION STATUS LIKE 'Sort_%';
+-------------------+--------+
| Variable_name     | Value  |
+-------------------+--------+
| Sort_merge_passes | 1917   |
| Sort_range        | 0      |
| Sort_rows         | 999900 |
| Sort_scan         | 1      |
+-------------------+--------+
```

```json
"filesort_summary": {
  "memory_available": 32768,
  "key_size": 240,
  "row_size": 610,
  "max_rows_per_buffer": 53,
  "num_rows_estimate": 493200,
  "num_rows_found": 999900,
  "num_initial_chunks_spilled_to_disk": 11494,
  "peak_memory_used": 33368,
  "sort_algorithm": "std::sort",
  "sort_mode": "<fixed_sort_key, packed_additional_fields>"
}
```

With only 32 KB, MySQL must use 11,494 merge buffers as indicated by `num_initial_chunks_spilled_to_disk` in the [optimizer trace](https://dev.mysql.com/doc/dev/mysql-server/latest/PAGE_OPT_TRACE.html#USER_ENABLE_TRACING) output at bottom. (This value was fixed as of [MySQL 8.0.2](https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-2.html): "In optimizer trace output, num_tmp_files did not actually indicate number of files. It has been renamed to num_initial_chunks_spilled_to_disk and indicates the number of chunks before any merging has occurred. (Bug #25733784, Bug #85487)".) The number of merge passes (1,917) is far less because each call to `merge_buffers()` merges several buffers (currently 7: `constexpr size_t MERGEBUFF = 7;` in `sql/sql_sort.h`). All 32 KB was used, as indicated by `peak_memory_used`.

The query took 3.6s to execute.

***sort_buffer_size = 10 MB (very large)***

Does a very large sort buffer increase query response time? Let's try 10 MB:

```
mysql> SELECT c FROM sbtest1 WHERE id > 100 ORDER BY c;
--
-- Output removed
--
999900 rows in set (2.49 sec)

mysql> SHOW SESSION STATUS LIKE 'Sort_%';
+-------------------+--------+
| Variable_name     | Value  |
+-------------------+--------+
| Sort_merge_passes | 6      |
| Sort_range        | 0      |
| Sort_rows         | 999900 |
| Sort_scan         | 1      |
+-------------------+--------+
```

```json
"filesort_summary": {
  "memory_available": 10485760,
  "key_size": 240,
  "row_size": 610,
  "max_rows_per_buffer": 17189,
  "num_rows_estimate": 493200,
  "num_rows_found": 999900,
  "num_initial_chunks_spilled_to_disk": 36,
  "peak_memory_used": 10486104,
  "sort_algorithm": "std::stable_sort",
  "sort_mode": "<fixed_sort_key, packed_additional_fields>"
}
```

Yes, query response time decreased 30% to 2.49s due to a 99.7% decrease in `Sort_merge_passes`: 1917 to 6. MySQL used all 10 MB of the sort buffer.


***sort_buffer_size = 32 MB (dangerous)***

```
mysql> SELECT c FROM sbtest1 WHERE id > 100 ORDER BY c;
--
-- Output removed
--
999900 rows in set (2.24 sec)

mysql> SHOW SESSION STATUS LIKE 'Sort_%';
+-------------------+--------+
| Variable_name     | Value  |
+-------------------+--------+
| Sort_merge_passes | 1      |
| Sort_range        | 0      |
| Sort_rows         | 999900 |
| Sort_scan         | 1      |
+-------------------+--------+
```

```json
"filesort_summary": {
  "memory_available": 33554432,
  "key_size": 240,
  "row_size": 610,
  "max_rows_per_buffer": 55007,
  "num_rows_estimate": 493200,
  "num_rows_found": 999900,
  "num_initial_chunks_spilled_to_disk": 12,
  "peak_memory_used": 33557336,
  "sort_algorithm": "std::stable_sort",
  "sort_mode": "<fixed_sort_key, packed_additional_fields>"
}
```

With a 32 MB sort buffer, merge passes drops to 1 but query response time remains similar to a 10 MB sort buffer: 2.24s vs. 2.49s, respectively. Not surprising: 1 merge pass vs. 6 is not a significant difference.

I call a 32 MB `sort_buffer_size` "dangerous" for two reasons. First, sort buffers are allocated per-connection, so it can use a lot of memory on busy servers. Second, several MySQL experts recommend against large values. Granted, each server is different, so do your own analysis and use a larger `sort_buffer_size` if there is a proven need for it. As of MySQL 8.0.12, `sort_buffer_size` is allocated incrementally as needed, so it is less dangerous.

***sort_buffer_size = 128 MB (insane)***

```
mysql> SELECT c FROM sbtest1 WHERE id > 100 ORDER BY c;
--
-- Output removed
--
999900 rows in set (2.52 sec)

mysql> SHOW SESSION STATUS LIKE 'Sort_%';
+-------------------+--------+
| Variable_name     | Value  |
+-------------------+--------+
| Sort_merge_passes | 1      |
| Sort_range        | 0      |
| Sort_rows         | 999900 |
| Sort_scan         | 1      |
+-------------------+--------+
```

```json
"filesort_summary": {
  "memory_available": 134217728,
  "key_size": 240,
  "row_size": 610,
  "max_rows_per_buffer": 220029,
  "num_rows_estimate": 493200,
  "num_rows_found": 999900,
  "num_initial_chunks_spilled_to_disk": 3,
  "peak_memory_used": 134229360,
  "sort_algorithm": "std::stable_sort",
  "sort_mode": "<fixed_sort_key, packed_additional_fields>"
}
```

A 128 MB `sort_buffer_size` proves an important point: <mark>performance can _decrease_  when `sort_buffer_size` is too large</mark>.

Query response time was 2.52s with 128 MB compared to 2.24s with 32 MB and 2.49s with 10 MB. Why? I do not have formal proof, but I am confident that it is due to the fact that `Sort_merge_passes` is negligible (1, 1, 6, respectively) but it takes longer to allocate 128 MB since, as of MySQL 8.0.12, sort buffer memory is allocated incrementally as needed which means more overhead to allocate large amounts of memory.

### Sort_rows

`Sort_rows` is the total number of rows sorted. The value is usually so high that it is nearly meaningless, even as a rate (rows sorted/second). If necessary, monitor the rate and watch for unexpected changes.
