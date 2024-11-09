---
date: "2022-02-27T14:28:00-05:00"
title: "MySQL EXPLAIN ANALYZE"
subtitle: "Chapter 2"
tags: ["mysql", "explain", "book", "efficient-mysql-performance"]
comments: false
lastmod: "2023-02-18T13:23:00-05:00"
aliases:
  - /post/book-2/
disqus_url: "https://hackmysql.com/post/book-2/"
series: "Behind the Book"
---

As of MySQL 8.0.18, [`EXPLAIN ANALYZE`](https://dev.mysql.com/doc/refman/8.0/en/explain.html#explain-analyze) is an indispensable tool for understanding query execution because it breaks down the query execution stage of response time by measuring each step of the query execution plan.
The information is illuminating, but the output is not intuitive: it requires practice and some understanding of how MySQL executes queries beyond the table join order shown by traditional `EXPLAIN` output.
This blog post closely examines three different examples of `EXPLAIN ANALYZE` output.

<!--more-->

<p class="note">
This blog post is the third of eleven: one for the preface and ten for each chapter of my book <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a>.
The full list is <a href="/tags/efficient-mysql-performance/">tags/efficient-mysql-performance</a>.
</p>


## Background and Terminology

Slide 9 of ["MySQL 8.0 EXPLAIN ANALYZE" by Norvald Ryeng](https://www.slideshare.net/NorvaldRyeng/mysql-80-explain-analyze) enumerates and illustrates how the MySQL query executor changed in 8.0:

![Slide 9](/img/slide-9-ryeng.jpg)

Before MySQL 8.0, instrumenting steps in a query execution plan was infeasible because the code was scattered and heterogeneous.
As of MySQL 8.0, instrumenting steps in a query execution plan is trivial because each step is essentially the same thing: an iterator.
And since the iterator is an interface, it's possible to transparently wrap each real iterator in a timing iterator ([sql/timing_iterator.h](https://github.com/mysql/mysql-server/blob/8.0/sql/iterators/timing_iterator.h)):

```cpp
template <class RealIterator>
bool TimingIterator<RealIterator>::Init() {
  ++m_num_init_calls;
  steady_clock::time_point start = now();     /* start time    */
  bool err = m_iterator.Init();               /* real iterator */
  steady_clock::time_point end = now();       /* end time      */
  m_time_spent_in_first_row += end - start;
  m_first_row = true;
  return err;
}
```

That's part of the `TimingIterator` class wrapping and measuring the wall-clock time of a real iterator (comments added by me).
When executing a query, MySQL directly executes real iterators.
For `EXPLAIN ANALYZE`, MySQL wraps each real iterator in a `TimingIterator` (and discards the result set).

The iterator interface has two methods: `Init()` and `Read()`.
A "loop" is one invocation of the iterator: a call to `Init()`, then `Read()` until there are no more rows.
`EXPLAIN ANALYZE` prints measurements for each iterator, like:

```
(actual time=0.106..9.991 rows=2844 loops=2)
```

0.106
: <mark>_Init time_</mark>: average time (in milliseconds) for `Init()` and first row (first `Read()`)

9.991
: <mark>_Read time_</mark>: average time (in milliseconds) for `Init()` and all rows (all `Read()`)

rows=2844
: Total number of rows read (all loops)

loops=2
: Number of calls to `Init()` (number of times iterator invoked)

The first time value, which I call "init time", is considered start up cost, and it's usually very low, but it depends on the iterator&mdash;the next section, [Example 1: Filesort](#example-1-filesort), is an example of this.

The second time value, which I call "read time", is the most useful when multiplied by `loops` to calculate <mark>_iterator time_</mark>: total time (in milliseconds) that the iterator spent reading rows.
In this example, 9.991 ms &times; 2 &equals; 19.982 ms iterator time.

When `loops=1`, read time and iterator time are the same.

<p class="note">
The terms <i>init time</i>, <i>read time</i>, and <i>iterator time</i> are my terms, not official MySQL terms because MySQL does not specific succinct names for these values.
</p>

Generally speaking, iterator time is cumulative from leafs to root.

```none
-> A (200ms loops=1)
   -> B (185ms loops=1)
      -> C (90ms loops=2)
```

Given the pseudo iterator tree above, the leaf iterator `C` took 180 ms (90 &times; 2 loops).
Since iterator `B` calls iterator `C`, the time for iterator `B` (exclusive of iterator `C`) is 5 ms (185 ms &minus; 180 ms).
Likewise, iterator `A` calls iterator `B`, so the time for the former is 15 ms (200 ms &minus; 185 ms).
This is important because the query took 200 ms, _not_ the sum of times report (565 ms).
This is generally true, but not always&mdash;MySQL always has fun little surprises like this.

For more technical details, read:

* [Volcano&mdash;An Extensible and Parallel Query Evaluation System](https://paperhub.s3.amazonaws.com/dace52a42c07f7f8348b08dc2b186061.pdf) by Goetz Graefe
* [MySQL WL#11785: Volcano iterator design](https://dev.mysql.com/worklog/task/?id=11785)
* [MySQL WL#12074: Volcano iterator executor base](https://dev.mysql.com/worklog/task/?id=12074)

## Output Format and Annotation

`EXPLAIN ANALYZE` output is not trivial to read (except for trivial queries).
Here's the real output format:

```none
mysql> EXPLAIN ANALYZE SELECT c FROM sbtest1 WHERE k < 450000 ORDER BY id\G
*************************** 1. row ***************************
EXPLAIN: -> Sort: sbtest1.id  (cost=84245.94 rows=133184) (actual time=1347.876..1357.375 rows=68440 loops=1)
    -> Index range scan on sbtest1 using k_1, with index condition: (sbtest1.k < 450000)  (cost=84245.94 rows=133184) (actual time=41.021..1298.076 rows=68440 loops=1)

1 row in set (1.37 sec)
```

The output is dense and tedious to read when there are many iterators.
That's not a criticism of MySQL, it's just how `EXPLAIN` output works in the MySQL CLI/shell.
([MySQL Workbench](https://www.mysql.com/products/workbench/) has a "visual EXPLAIN" feature, but I don't know if it works with `EXPLAIN ANALYZE`.)

Here's how I reformat and annotate the output in the following three examples:

```js
1 -> Sort: sbtest1.id
     (actual time=2043.416 .. 2051.792 rows=68440 loops=1)
0     -> Index range scan on sbtest1 using k_1, with index condition: (sbtest1.k < 450000)
         (actual time=109.302 .. 1996.350 rows=68440 loops=1)
```

The numbers in the left margin, starting with 0, number the iterators in _reading order_: how to read the output to follow the flow of row access.
This is helpful because the output generally reads top to bottom and depth first, but not always.
I refer to iterators by these numbers, like "the index range scan (0) executes during&hellip;".

Additionally, to make the output easier to read and follow:
* `(cost=...)` is removed
* `(actual time=...)` is put on its own line
* Init time and read time have extra white space: `41.021..1298.076` to `41.021 .. 1298.076`
* Syntax highlighting makes the numbers stand out from the text

Now we can examine and discuss some examples without straining your eyes too much.

## Example 1: Filesort

```js
1 -> Sort: sbtest1.id
     (actual time=2043.416 .. 2051.792 rows=68440 loops=1)
0     -> Index range scan on sbtest1 using k_1, with index condition: (sbtest1.k < 450000)
         (actual time= 109.302 .. 1996.350 rows=68440 loops=1)
```

In chapter 2 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance), which teaches index and indexing, I take a page (literally one page: page 70 in print), to use `EXPLAIN SELECT c FROM sbtest1 WHERE k < 450000 ORDER BY id` to prove that the data access, not the filesort, is the slowest part of that query.

I explain the output in the book, so I won't repeat myself here.
Instead, let's reuse this simple example to more deeply understand `EXPLAIN ANALYZE` before reading more complex examples.

The output of `EXPLAIN ANALYZE` is somewhat the reverse of how we think about query execution.
For this query and others like it, we reasonably think that MySQL fetches _then_ sorts rows (can't sort rows that haven't been fetched yet), but the output shows it differently: index range scan (0) nested (indented) one level within sort (1), which looks like fetching rows&mdash;index range scan (0)&mdash;happens after sort (1).
But that's not the case; the annotated numbers in the left margin are the order of row access.
The output reflects how these iterators are implemented and called, as noted in [sql/iterators/sorting_iterator.h](https://github.com/mysql/mysql-server/blob/8.0/sql/iterators/sorting_iterator.h):

```cpp
/**
  An adapter that takes in another RowIterator and produces the same rows,
  just in sorted order. (The actual sort happens in Init().)
```

As that comment notes, the sort iterator (1) is an _adapter_ that, under the hood, calls another iterator to fetch rows&mdash;index range scan (0) in this case.
Then sort (1) sorts the rows fetched by index range scan (0).
And sort (1) does all this in `Init()`.
sort (1) `Read()` simply returns the already fetched and sorted rows in order, which is why read time is very close to init time: it's mostly init time, with only a few milliseconds to return the sorted 68,440 rows.

As a result, neither sort (1) init time nor read time are purely measurements of sorting time, which is (imho) what we'd expect to see from timing a sort iterator since its purpose is sorting, but it's simply not programmed that way.
Instead, sort (1) init time includes both index range scan (0) read time and time spent sorting rows.

Since index range scan (0) read time is only time spent fetching rows, we can subtract it from sort (1) init time to roughly calculate time spent sorting rows: 2043.416 &minus; 1996.350 &equals; 47 ms.

<div class="note warn left-icon">
<img class="ion" src="/img/ionicons/warning-outline.svg">
<p>
Alas, the aforementioned means that my original explanation on page 70 of <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a> is not accurate.
I wrote that "the filesort (line 1) started after [2043.416] milliseconds and ended after [2051.792]  milliseconds, which means the filesort took 8 milliseconds."
The conclusion is still correct: "The answer is no: filesort does not make this query slow. The problem is data access: 68,439 rows is not a small result set."
But how I arrived at the conclusion was incorrect.
</p>
</div>

The moral of the story is: sometimes you need to understand how iterators work under the hood (in the MySQL source code) in order to correctly interpret the reported timing values.

## Example 2: Simple Join

```js
3 -> Nested loop inner join
     (actual time=0.022..0.036 rows=4 loops=1)
1     -> Filter: (elem.a in ('Ag','Au','At'))
         (actual time=0.015..0.024 rows=4 loops=1)
0         -> Covering index range scan on elem using idx_a_b
             (actual time=0.013..0.022 rows=4 loops=1)
2     -> Single-row index lookup on elem_names using PRIMARY (symbol=elem.a)
         (actual time=0.002..0.002 rows=1 loops=4)
```

That is the `EXPLAIN ANALYZE` output for example 2-19 that you find in the book on page 74 and download the [examples](https://github.com/efficient-mysql-performance/examples/tree/main/).
The query is:

```sql
SELECT name FROM elem JOIN elem_names ON (elem.a=elem_names.symbol) WHERE a IN ('Ag', 'Au', 'At');
```

This example highlights how you typically read `EXPLAIN ANALYZE` output: depth first.
Although query execution is rooted in the join (3), row access starts with the covering index scan (0) on table `elem`.
Then rows are filtered (1) for the `IN()` clause.
Matching rows are used to lookup and join corresponding rows in table `elem_names`: primary key lookup (2).

Note that `loops=1` for both covering index scan (0) and filter (1): the first table in a join is accessed once.
But `loops=4` for the primary key lookup (2) because joined table (the second and subsequent tables in a join) are typically accessed many times for each row from preceding tables.
Likewise, filter (1) matched `rows=4`, which corresponds with primary key lookup (2) `loops=4`: four rows from the first table cause MySQL to access the joined table four times.
To learn more, read section "Table Join Algorithms" at the end of chapter 2 in [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance).

## Example 3: Sakila

```js
5 -> Table scan on <temporary>
     (actual time=0.001 .. 0.002 rows=2 loops=1)
4     -> Aggregate using temporary table
         (actual time=26.210 .. 26.210 rows=2 loops=1)
3         -> Nested loop inner join
             (actual time=0.140 .. 20.580 rows=5687 loops=1)
0             -> Table scan on staff
                 (actual time=0.023 .. 0.028 rows=2 loops=1)
2             -> Filter: (payment.payment_date like '2005-08%')
                 (actual time=0.106 .. 9.991 rows=2844 loops=2)
1                 -> Index lookup on payment using idx_fk_staff_id (staff_id=staff.staff_id)
                     (actual time=0.098 .. 7.099 rows=8024 loops=2)
```

This is the example that Norvald Ryeng uses in [MySQL EXPLAIN ANALYZE (MySQL Blog Archive)](https://dev.mysql.com/blog-archive/mysql-explain-analyze/).
The query is a simple two-table join with a `GROUP BY` clause, which is why there is an aggregate (4) and temp table scan (5):

```sql
SELECT first_name, last_name, SUM(amount) AS total
FROM staff INNER JOIN payment ON staff.staff_id=payment.staff_id AND payment_date LIKE '2005-08%'
GROUP BY first_name, last_name;
```

The flow of row access from table scan (0) to index lookup (1) to filter (2) to accomplish the join (3) is similar to the previous examples.

Aggregate (4) is new: it receives and groups rows from the join (3).
Notice that join (3) `rows=5687` but aggregate (4) `rows=2`: the query returns only 2 groups (one row per group).
Interestingly, both init time and read time for aggregate (4) are the same, which suggests that all work is done in `Init()`&mdash;we'd have to check the MySQL source code to verify.

As Norvald points out in his blog post, most of the time spent in this query is _not_ the table scan (0), which is somewhat surprising because table scans are presumed to be very slow.
But for this query there is a very simple explanation: `rows=2` on table scan (0)&mdash;the table has only two rows.
As a result, 97% of join (3) is spent looking up and filter rows (index lookup (1) and filter (2), respectively).
Filter (2) time includes time spent in index lookup (1), and iterator time for filter (2) is 9.991 ms &times; 2 &equals; 19.982 ms, which is 97% of join (3) iterator time 20.580 ms.
Table scans are generally slow, but this example shows that if one table is small, then index lookups on joined tables might be more time-consuming.
Or to state it the other way: if you see `type: ALL` in an EXPLAIN plan (traditional `EXPLAIN` output), there's a chance that the full table scan is _not_ the most time-consuming part of query response time.

The weird part of this example is temp table scan (5): its times do not include the times of other iterators even though it is the root iterator.
I can't tell from the MySQL source code why this is the case, but I presume it's because temp table scan (5) happens after aggregate (4) has completely finished, almost as if temp table scan (5) is a completely separate iterator that does not contain and call aggregate (4).

In any case, the point is: you must read `EXPLAIN ANAZLYE` output quite carefully, extract the relative numbers from related (nested) iterators, and make some allowances for output that doesn't fit typical interpretation based on an understanding of how MySQL actually executes a query.
Regardless of these challenges, `EXPLAIN ANALYZE` provides valuable low-level insight into query response time.

## Other Resources

Surprisingly, the MySQL community has written very little about `EXPLAIN ANALYZE`, and even the MySQL manually doesn't explain it as thoroughly as usual.
Here are some additional resources (some of which were already linked earlier) that discuss `EXPALIN ANALYZE`:

* [Obtaining Information with EXPLAIN ANALYZE (MySQL manual)](https://dev.mysql.com/doc/refman/8.0/en/explain.html#explain-analyze)
* [MySQL EXPLAIN ANALYZE (MySQL Blog Archive)](https://dev.mysql.com/blog-archive/mysql-explain-analyze/)
* [WL#4168: Implement EXPLAIN ANALYZE](https://dev.mysql.com/worklog/task/?id=4168)
* [Using Explain Analyze in MySQL 8 (Percona)](https://www.percona.com/blog/2019/10/28/using-explain-analyze-in-mysql-8/)
* [MySQL 8.0 EXPLAIN ANALYZE (slides)](https://www.slideshare.net/NorvaldRyeng/mysql-80-explain-analyze)
* [Use MySQL EXPLAIN for Query Optimization (video)](https://www.youtube.com/watch?v=TukZd6LjeBc)
* [MySQL 8 Query Performance Tuning (chapter 20)](https://link.springer.com/book/10.1007/978-1-4842-5584-1)

Beyond those resources and this blog post, I suggest that you practice with your own queries.
Start with a traditional `EXPLAIN` to see the table join order, then `EXPLAIN ANALYZE` and read the output in a generally top-down, depth-first manner, taking into account the table join order to help guide you.
If you see something that doesn't quite make sense, it could very well be an oddity of the output and not a misreading.

Lastly, remember that `EXPLAIN ANALYZE` actually executes the query&mdash;locks and all&mdash;so do not run it on an active production server: use a read-only replica or a staging server with the same data because data is a factor in query execution and performance in general.
