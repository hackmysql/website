---
type: "page"
date: "2023-11-28T17:39:00-05:00"
title: "The Infamous ORDER BY LIMIT Query Optimizer Bug"
subtitle: "16 Years of Fun"
tags: ["mysql", "query-optimization", "bug"]
comments: true
lastmod: "2025-04-23T13:37:00-04:00"
aliases:
  - /post/infamous-order-by-limit-query-optimizer-bug/
disqus_url: "https://hackmysql.com/post/infamous-order-by-limit-query-optimizer-bug/"
params:
  path: index
---

Which is faster: `LIMIT 1` or `LIMIT 20`?
Presumably, fetching less rows is faster than fetching more rows.
But for 16 years ([since 2007](https://github.com/mysql/mysql-server/commit/cf3942929584#diff-f3db433ca1b69c2c77575643263bf78d)) the MySQL query optimizer has had a "bug"&dagger; that not only makes `LIMIT 1` _slower_ than `LIMIT 20` but can also make the former a table scan, which tends to cause problems.
This happened last week where I work, and although MySQL DBAs are familiar with this bug, I'm writing this blog post for developers to more clearly illustrate and explain what's going on and why because it's really counterintuitive.

<!--more-->

<p class="note">
&dagger; It's technically not a bug because the result isn't wrong, it's just slower.
But I'll call it a bug because that's easier to type than "query optimization that sometimes makes the query slower."
</p>

## Fundamentals

Before we look at a test case with 1,000,000 rows, let's nail down some fundamentals with only 6 rows depicted in two diagrams below.

The top diagram is a primary key (PK) on column `id` depicted as rows because with InnoDB the primary key is the table.
It's a B-tree index, so it's ordered from least to greatest value (ascending): `id = 1` at the start (head) to `id = 6` at the end (tail).
When the index is scanned, it can only be scanned in this order (ascending), or reverse (descending), but the default is ascending.

![PK and secondary index](/img/order_by_limit_bug_1.svg)

To bottom diagram is a secondary index (SI) on columns `<col2, co1>` depicted as index records, so each "column" (reading left to right) is an index record, `<a, x>`, `<a, y>`, and so on.
It's also a B-tree index, so it's ordered ascending and can only be scanned ascending or descending.

If you've read my book, [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance), you already know why the secondary index has PK values (copies, not pointers) appended to it: they tell MySQL where to find the corresponding rows. 
For example, when MySQL uses the SI to match `<b, r>`, it uses the appended PK value `5` to read that row from the primary key.

Now here's the query in question:

`SELECT * FROM t WHERE col2 = 'c' ORDER BY id LIMIT 1`

How should MySQL execute that query?
Developers tend to say "Use the secondary index for the WHERE condition `col2 = 'c'`."
That's reasonable; it makes sense.
(If not, then you really must [read my book](https://oreil.ly/efficient-mysql-performance).)

The secondary index has 2 matching records: `<c, n>` and `<c, o>`.
That will cause 4 lookups total: 2 secondary index reads + 2 corresponding primary key reads.
Furthermore, the query needs to order by `id`, which is not the order of the secondary index, so MySQL will also sort the results after those 4 lookups.
That means EXPLAIN will say "Using filesort".

Let's walk through the secondary index access step by step:

1. Match SI `<c, n>`
2. Read corresponding PK row `6` into sort buffer
3. Match SI `<c, o>`
4. Read corresponding PK row `3` into sort buffer
5. Sort the buffer for `ORDER BY`: `[6, 3]` &rarr; `[3, 6]`
6. Apply `LIMIT 1` to return PK row `<3, o, c>`

That's not a bad execution plan, but the query optimizer can choose a completely different plan: an index scan on the `ORDER BY` column which happens to be the primary key: `id`.
(Remember: an index scan on the primary is the same as a table scan because the primary key is the table.)
Why?
In the source code, `sql_select.cc` method `test_if_cheaper_ordering()`, a code comment explains:

```cpp
        /*
          Switch to index that gives order if its scan time is smaller than
          read_time of current chosen access method.
```

<mark>Reading rows _in order_ might be faster than unordered secondary index lookups plus sorting.</mark>
With this optimization, the new query execution plan would be:

1. Read PK row `1` and discard (`col2` value doesn't match)
1. Read PK row `2` and discard (`col2` value doesn't match)
1. Read PK row `3` (`col2` value matches)

Looks like MySQL is correct: by scanning the primary key in order, it reads 1 less row and avoids the filesort.
This is _might_ be faster, but I'm omitting various details to explain the fundamentals more simply.
For now, the point is that this query optimization works this way and might be faster.

What's weird is that MySQL does not overtly indicate when it automatically changes the execution plan to enable this query optimization.
For example, _before_ the change you would see an [EXPLAIN plan](https://dev.mysql.com/doc/refman/8.0/en/explain-output.html) like:

```none
-- BEFORE: Secondary index lookup
+-------+------+------------------+------------------+-------+------+----------------+
| table | type | possible_keys    | key              | ref   | rows | Extra          |
+-------+------+--------------------+----------------+-------+------+----------------+
| t     | ref  | idx_on_col2_col1 | idx_on_col2_col1 | const | 1000 | Using filesort |
+-------+------+------------------+------------------+-------+------+----------------+
```

But _after_ the change you would see an EXPLAIN plan like:

```none
-- AFTER: Primary key scan (query optimization)
+-------+-------+------------------+---------+------+------+-------------+
| table | type  | possible_keys    | key     | ref  | rows | Extra       |
+-------+-------+------------------+---------+------+------+-------------+
| t     | index | idx_on_col2_col1 | PRIMARY | NULL |  996 | Using where |
+-------+-------+------------------+---------+------+------+-------------+
```

Notice that fields `type`, `key`, `ref`, and `Extra` all change.
Also, `PRIMARY` is not listed for `possible_keys` before, but after (when MySQL changes the execution plan) it appears as the chosen `key`.
That's one telltale sign that MySQL changed the execution plan to enable this optimization, but the indisputable sign is only seen in an optimizer trace (line 10 of this snippet):

```json {linenos=inline}
"reconsidering_access_paths_for_index_ordering": {
  "clause": "ORDER BY",
  "steps": [
  ],
  "index_order_summary": {
    "table": "`t`",
    "index_provides_order": true,
    "order_direction": "asc",
    "index": "PRIMARY",
    "plan_changed": true,
    "access_type": "index"
  }
}
```

<div class="note" style="margin-top:15px">
Trace the optimizer:
<pre>
SET optimizer_trace="enabled=on";
-- Execute query or EXPLAIN
SELECT * FROM INFORMATION_SCHEMA.OPTIMIZER_TRACE\G
</pre>
</div>

Unfortunately, the optimizer trace information does not specify _why_ the index scan is faster.
Neither does the MySQL manual at the end of [8.2.1.19 LIMIT Query Optimization](https://dev.mysql.com/doc/refman/8.0/en/limit-optimization.html):

>For a query with an ORDER BY or GROUP BY and a LIMIT clause, the optimizer tries to choose an ordered index by default when it appears doing so would speed up query execution. Prior to MySQL 8.0.21, there was no way to override this behavior, even in cases where using some other optimization might be faster. Beginning with MySQL 8.0.21, it is possible to turn off this optimization by setting the optimizer_switch system variable's prefer_ordering_index flag to off.

(The phrase "even in cases where using some other optimization might be faster" is a polite way of referring to this bug.)

Is sorting rows really so slow that it justifies this query optimization?
There's more to it than that, but we need a lot more rows to understand why.

## Jeremy's Test Case

This bug has existed for a long time, and many MySQL experts have blogged about it over the years.
One such expert is Jeremy Cole and his blog post 
[Reconsidering access paths for index ordering… a dangerous optimization… and a fix!](https://blog.jcole.us/2019/09/30/reconsidering-access-paths-for-index-ordering-a-dangerous-optimization-and-a-fix/)
He provides a test case with 1,000,000 rows that reproduces the bug, but first let's demonstrate again that sometimes MySQL is right to change the execution plan.

The data dump is [jcole-1M.sql.gz](/jcole-1M.sql.gz), table `t` so be careful not to overwrite any existing table `t` you might have.
It contains 1M rows with values for column `other_id` repeating every 1,000 rows&mdash;this will become important later.
There's a secondary index on columns `<other_id, covered_column>`.

After you load the table, `ANALYZE TABLE t` to ensure the index statistics are correct.
Then run `EXPLAIN ANALYZE SELECT non_covered_column FROM t WHERE other_id=555 ORDER BY id LIMIT 1`:

```sh {linenos=inline}
-> Limit: 1 row(s)  (cost=0.999 rows=0.999) (actual time=1..1 rows=1 loops=1)
   -> Filter: (t.other_id = 555)  (cost=0.999 rows=0.999) (actual time=1..1 rows=1 loops=1)
      -> Index scan on t using PRIMARY  (cost=0.999 rows=996) (actual time=0.116..0.345 rows=555 loops=1)
```

Read my in-depth guide to [EXPLAIN ANALYZE]({{< ref "book-2" >}}) if you're not familiar with the output&mdash;it's something all developers need to know.

Apart from different column names and 1M rows rather than 6, everything is the same as you've learned so far.
The EXPLAIN ANALYZE output shows it in another way: on line 3, "rows=996" means MySQL estimated it would have to scan through 996 rows to find the first matching one, but "rows=555" means it scanned through only 555 rows&mdash;the optimization worked: it dramatically reduced row access.
Line 2 is filtering for `WHERE other_id=555`.
Line 3 is the `LIMIT 1`.
For lines 2 and 3 we see "rows=1" which is further evidence of the optimization at work: only 1 row was filtered and limited&mdash;and a filesort avoided.

Why did MySQL estimate 996 rows?
Because there are 1,000 rows matching `other_id=555`.
(It's a row _estimate_ so 996 is close enough to 1,000.)
This detail will be important later.

For the third time now, have you [read my book](https://oreil.ly/efficient-mysql-performance)?
If so, then you probably recall the very first sentence: _Performance is query response time_.
All this theory and EXPLAIN stuff is cool, but is the query actually faster with this optimization?
Yes, from the slow log:

<pre>
<mark># Query_time: 0.000737</mark>  Lock_time: 0.000003 Rows_sent: 1  Rows_examined: 555 Thread_id: 225 Errno: 0 Killed: 0 Bytes_received: 92 Bytes_sent: 92 Read_first: 1 Read_last: 0 Read_key: 1 Read_next: 554 Read_prev: 0 Read_rnd: 0 Read_rnd_next: 0 Sort_merge_passes: 0 Sort_range_count: 0 Sort_rows: 0 Sort_scan_count: 0 Created_tmp_disk_tables: 0 Created_tmp_tables: 0
SELECT non_covered_column FROM t WHERE other_id=555 ORDER BY id ASC LIMIT 1;

<mark># Query_time: 0.005518</mark>  Lock_time: 0.000002 Rows_sent: 1  Rows_examined: 1001 Thread_id: 225 Errno: 0 Killed: 0 Bytes_received: 136 Bytes_sent: 92 Read_first: 0 Read_last: 0 Read_key: 1 Read_next: 1000 Read_prev: 0 Read_rnd: 0 Read_rnd_next: 0 Sort_merge_passes: 0 Sort_range_count: 0 Sort_rows: 1 Sort_scan_count: 1 Created_tmp_disk_tables: 0 Created_tmp_tables: 0
SELECT non_covered_column FROM t FORCE INDEX (index_other_id_covered_column) WHERE other_id=555 ORDER BY id ASC LIMIT 1;
</pre>

Top result is with the optimization (scanning the primary key): 0.74 ms.
Bottom result is forcing the secondary index lookup plus sort: 5.52 ms.
The primary key scan is about 5x faster in _this_ case, but not all cases.

## The Bug in Action

After loading the data dump in the previous section, execute<br>`UPDATE t SET id=id+1000000 WHERE other_id=555;`<br>
That moves 1,000 rows matching `other_id=555` to the end of the table.
Then execute these queries:

```sql
SELECT non_covered_column FROM t WHERE other_id=555 ORDER BY id ASC LIMIT 1;

SELECT non_covered_column FROM t WHERE other_id=555 ORDER BY id ASC LIMIT 20;
```

With MySQL 5.7, 8.0, and even 8.1 you should get wildly different response times:

<pre>
<mark># Query_time: 0.416951</mark>  Lock_time: 0.000004 Rows_sent: 1  Rows_examined: 999001 Thread_id: 226 Errno: 0 Killed: 0 Bytes_received: 82 Bytes_sent: 92 Read_first: 1 Read_last: 0 Read_key: 1 Read_next: 999000 Read_prev: 0 Read_rnd: 0 Read_rnd_next: 0 Sort_merge_passes: 0 Sort_range_count: 0 Sort_rows: 0 Sort_scan_count: 0 Created_tmp_disk_tables: 0 Created_tmp_tables: 0
SELECT non_covered_column FROM t WHERE other_id=555 ORDER BY id ASC LIMIT 1;

<mark># Query_time: 0.002672</mark>  Lock_time: 0.000004 Rows_sent: 20  Rows_examined: 1020 Thread_id: 226 Errno: 0 Killed: 0 Bytes_received: 83 Bytes_sent: 273 Read_first: 0 Read_last: 0 Read_key: 1 Read_next: 1000 Read_prev: 0 Read_rnd: 0 Read_rnd_next: 0 Sort_merge_passes: 0 Sort_range_count: 0 Sort_rows: 20 Sort_scan_count: 1 Created_tmp_disk_tables: 0 Created_tmp_tables: 0
SELECT non_covered_column FROM t WHERE other_id=555 ORDER BY id ASC LIMIT 20;
</pre>

`LIMIT 1`: 471 ms<br>
`LIMIT 20`: 3 ms

20x more rows but 157x faster...<p style="font-size:22pt">🤯</p>

`EXPLAIN ANALYZE` for the `LIMIT 1` query shows the problem even better:

```none
   -> Index scan on t using PRIMARY  (cost=0.25 rows=999) (actual time=0.847..7856 rows=999001 loops=1)
```

"rows=999" is the row estimate, but "actual ... rows=999001" is the problem: MySQL assumed that the first matching row would be about 1k rows from the start of the table, but it was actually near the end of the table (999001 rows from the start) because of the `UPDATE` statement.

A crude ASCII depiction of what MySQL assumed versus reality created by the `UPDATE`:

```none
Assumed: ...555...555...555...
Reality: .....................555 555 555
```

MySQL uses this optimization for `LIMIT 1`, but the assumption proves false (the first matching row is not about ~1k rows from the start), and that causes the query to be slow.
But MySQL does not use this optimization for `LIMIT 20`, so neither the assumption nor the reality matter, and that causes the query to be a lot faster than `LIMIT 1`.

Now we have two related issues: MySQL assumes uniformly distributed data, and how/why the `LIMIT` value does or does not trigger MySQL to use this query optimization.

## Data Distribution

The MySQL query optimizer assumes that data is uniformly distributed.
For example, in the table depicted at the start of this blog post ([Fundamentals](#fundamentals)), the `a`, `b`, and `c` values are uniformly distributed: there's a `c` value every 3rd row (in the primary key).
The same is true for Jeremy's test case _before_ the `UPDATE`: rows matching `other_id=555` are uniformly distributed from the beginning to the end of the table, one occurrence every 1,000 rows.

When this assumption is true (when data is uniformly distributed), this query optimization works: it can increase performance (reduce response time).
But the calculation that makes MySQL use the optimization (or not) involves several factors:

* `select limit`: The `n` in `LIMIT n`
* `refkey rows`: How many rows the originally chosen index matches
* The read cost of using the originally chosen index
* `table rows`: Total number of rows in the table
* Records per key&Dagger;
* Various access costs

Using these factors, the query optimizer calculates the _index scan cost_.
If the index scan cost is less than the read cost (of using the originally chosen index), then the index scan is used.

<p class="note">
&Dagger; I cannot figure out "records per key" even with a debugger.
The value seems to always be 1, which makes it unused in this case.
I'm not familiar enough with this internal server detail, but for this example it doesn't make a difference.
</p>

The index scan cost calculation is roughly:

* `x = table rows / refkey rows * select limit`
* `index scan cost = x / records per key * access cost`

What's important is `x`: if we assume rows are uniformly distributed, and `other_id=555` matches 1,000 rows (`refkey rows`), then the first matching row for `LIMIT 1` should be `x = 1,000,000 / 1,000 * 1 = 1,000` rows from the beginning of the table (primary key).
Likewise, for `LIMIT 2` that increases to 2,000 rows, and `LIMIT 3` that increases to 3,000 rows, and so on.

<p class="note">
Don't be fooled by the easy, round numbers used here: 1M total rows / 1k matching rows = 1,000 again.
It's just a test case.
In the real world, the numbers can be anything.
For example, it happened to some developers where I work with LIMIT 21 and a table with 1.2 billion rows.
</p>

But of course, every row access has some cost, so `x` is divided by a value I don't understand (see &Dagger; above) and multiplied by an access cost that takes into account several other factors beyond the scope of this blog post.
For example, MySQL knows if a page is in memory (low cost memory access) or not (high cost storage I/O).

The end result is an index scan cost that can be compared to the original read cost, and (apart from several other conditionals) that's exactly what the code does: `index_scan_time < read_time`.
(The variables are called "time" but they're not really time, they're unit-less costs.)
If you're curious, here's what MySQL 8.0.35 calculates for `LIMIT 1` with [Jeremy's test case](#jeremys-test-case):

|Access|Cost|
|------|-|
|Read (ref)|310.59415278214396|
|Index scan|310.28355862936183|

Yes, the index scan is only slightly cheaper.
`LIMIT 2` doubles the index scan cost to 620, which is why MySQL doesn't use the optimization.

For developers the main point is: <mark>this bug may or may not happen based on `n` in `LIMIT n`, the estimated number of matching rows for the reference key (originally chosen index), and the total number of rows in the table.</mark>

## Everything Changes

This bug can appear or disappear over time because everything changes:

* The table is probably growing, or maybe shrinking
* The number of matching rows (for the reference key) can change
* The `LIMIT n` might be variable (pagination?)
* When MySQL is upgraded

These changes mean that you probably can't look once and be done unless you globally disable this optimization&mdash;see [Optimizer Flag](#optimizer-flag) below.

The last point is especially poignant because MySQL 5.7 became EOL last month (October 2023), so the world is hopefully upgrading to 8.0 (which became LTS as of 8.0.34).
Whereas 5.7 still had the query cache (QC), it's gone in 8.0.
It's been standard practice to disable the QC for a long time, but for example it's on by default in Amazon Aurora v2 for MySQL.
When you upgrade from 5.7 to 8.0, check any queries with `ORDER BY ... LIMIT` that might be affected by this bug and exacerbated by the loss of the QC.

The first point is also interesting because the problem is usually "this optimization decreases performance when MySQL uses it", but the opposite can happen too: your workload could rely on this optimization, but then MySQL stops using it, which causes a decrease in performance.
Imagine you've got a table and query for which MySQL is choosing this optimization _and it works_&mdash;it's faster than the unordered secondary index read.
But over time new rows are appended to the table without affecting the number of matching rows.
At some point, the larger table will change the cost calculations and MySQL will stop choosing this query optimization, which can make the query slower.
You can see this in action, too:

* Reload [jcole-1M.sql.gz](/jcole-1M.sql.gz)
* Insert +1M more rows but none with `other_id=555`
* Observe EXPLAIN plans and query times for `LIMIT 1` vs. `LIMIT 20`

With 2M rows instead of 1M, you'll see that MySQL no longer chooses this query optimization for `LIMIT 1` even though it's faster.
In this case, the only way to force the query optimization to happen again is `FORCE INDEX (PRIMARY)`.

## Optimizer Flag

Jeremy Cole created the [`prefer_ordering_index`](https://dev.mysql.com/doc/refman/8.0/en/switchable-optimizations.html#optflag_prefer-ordering-index) optimizer flag to disable this optimization[^1]:

`SET optimizer_switch = "prefer_ordering_index=off";`

When this optimizer flag is off, the function that does the cost calculations described in [Data Distribution](#data-distribution) is not called, so this query optimization does not happen.

[^1]: [WL#13929: Introduce new optimizer switch to disable limit optimization](https://dev.mysql.com/worklog/task/?id=13929)

Should you disable this optimization (globally)?

**MySQL &ge; 8.0.40**

Yes.
Disabling `prefer_ordering_index` is safe and recommended in MySQL &ge; 8.0.40 because I [fixed the bug](https://bugs.mysql.com/bug.php?id=113699) mentioned below.
This flag defaults to on, so disabling it requires explicitly configuring [`optimizer_switch`](https://dev.mysql.com/doc/refman/8.4/en/server-system-variables.html#sysvar_optimizer_switch).

**MySQL &le; 8.0.39**

Yes
: But only for _new development_.
Experts usually agree that assuming uniform data distribution is faulty logic because there are no _a priori_ reasons to presume that data will be uniformly distributed.
The long list of bug reports about this query optimization are proof to the contrary: data is often not uniformly distributed.
(Likewise, data _access_ can range from uniform [across the whole table] to extreme hot spots [a few rows].)
So if you have the luxury of knowing all this at the start of a new development, then yes: globally disable this optimization because you can still force it (with `FORCE INDEX`) if you ever find a slow query that would be faster using it.

No
: Despite all the bug reports over nearly two decades, it is logical to presume that there are many workloads around the world that are benefiting from this optimization, so turning it off might cause more harm than good on a global scale.
Oracle knows this, which is why it's still on by default.
If it's not affecting you yet, then just leave it be.
Sometimes pragmatism is the best technical choice.

Maybe
: Now that you deeply understand this query optimization, if you can convince your fellow developers, DBAa, and managers to take a gamble, then sure: disable it globally for an existing database.
If you win, nothing will happen; performance will stay the same.
If you lose, you can quickly re-enable it, or use `FORCE INDEX` to force the secondary index (use `EXPLAIN` to see what it is before MySQL changes the plan).

<div class="note warn left-icon">
<div>{{< warning-icon >}}</div>
<div>
Disabling <code>prefer_ordering_index</code> in MySQL &le; 8.0.39 causes another bug: MySQL does not scan the primary key for <code>SELECT ... FROM t ORDER BY pk_col LIMIT n</code>.
Instead, it does a <em><b>full</b> table scan</em> plus sort, which is unnecessary and very likely to cause problems.
Unlike the main subject of this blog post, I would call this a real bug.
Thank you to Jay Janssen and Morgan Tocker for brining this to my attention.
<br><br>
I fixed <a href="https://bugs.mysql.com/bug.php?id=113699">this bug</a> in MySQL 8.0.40.
</div>
</div>

Bottom line: you may never be bitten by the infamous ORDER BY LIMIT query optimizer bug, but if you are, you can disable the optimizer flag, or workaround by increasing the `LIMIT` value to change the cost calculations, or use `FORCE INDEX` to force the original secondary index.
