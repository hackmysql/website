---
type: "page"
date: "2023-08-09T13:27:00-04:00"
title: "Deferred Join: A Deep Dive"
tags: ["mysql", "deferred-join", "query-optimizaiton", "finch"]
comments: true
aliases:
  - /post/deferred-join-deep-dive/
disqus_url: "https://hackmysql.com/post/deferred-join-deep-dive/"
params:
  path: data
---

Deferred join is powerful.
Deferred join is simple.
Deferred join is misunderstood.

<!--more-->

With a simple SQL rewrite, deferred join can make a query 2x faster or more.
It's true!
Now that I have your attention...

"Misunderstood" is too strong because I think the people who've written about it understand it correctly.
It would be more accurate to say "Deferred join is not explained well or thoroughly", but that's too wordy&mdash;it doesn't catch your attention like the pithy parallelism in the lead.

You might reap the benefits of a deferred join with a poor explanation.
But let me provide you a "rich" explanation of deferred join so that you can truly deepen your understanding of, and skill with, MySQL query optimization.
After all, it's not every day we get to examine the magic of an advanced yet simple query optimization.

## Origin

In April 2007, Peter Zaitsev first blogged about this query optimization by another name: [Using delayed JOIN to optimize count(\*) and LIMIT queries](https://www.percona.com/blog/using-delayed-join-to-optimize-count-and-limit-queries/).
But don't bother reading that 16 year old blog post because he doesn't explain why the join is "delayed", and he doesn't even use the word "delayed" in the body.
In fact, he doesn't really explain it at all.
But go easy on him: Percona was founded in 2006, so in 2007 Peter (and Vadim) were crazy-busy.

But Peter's 2007 blog post was _not_ the origin of the term "deferred join".
The origin of "deferred join" is [_High Performance MySQL, 3rd Edition_](https://www.oreilly.com/library/view/high-performance-mysql/9781449332471/) by Peter, Vadim, and Baron&mdash;published in 2012.

### 2012: HPM 3e

In HPM 3e chapter 5 ("Indexing for High Performance") section "Covering Indexes", Peter, et al. wrote:

```none
mysql> EXPLAIN SELECT *
    -> FROM products
    ->    JOIN (
    ->       SELECT prod_id
    ->       FROM products
    ->       WHERE actor='SEAN CARREY' AND title LIKE '%APOLLO%'
    ->    ) AS t1 ON (t1.prod_id=products.prod_id)\G
```

>We call this a "deferred join" because **it defers access to the columns.** MySQL uses the covering index in the first stage of the query, when it finds matching rows in the subquery in the FROM clause. It doesn't use the index to cover the whole query, but it’s better than nothing.

(Emphasis mine.)

The covering index is `(actor, title, prod_id)`.
(If you want to read more, I encourage you to buy an [O'Reilly online learning subscription](https://www.oreilly.com/online-learning/) to access HPM 3e because it's probably out of print since HPM 4e was published in 2021.)

The second mention of deferred join occurs later in chapter 5 section "Optimizing Sorts".
Peter, et al. are discussing `SELECT <cols> FROM profiles WHERE ... ORDER BY rating LIMIT 100000, 10`.
Despite the section title, the query is matter of pagination rather than pure sorting, but the two are closely related because `ORDER BY col LIMIT offset, n` is a common pagination technique.
Likewise, the authors note the problem with large offsets: "Such queries can be a serious problem no matter how they’re indexed, because the high offset requires them to spend most of their time scanning a lot of data that they will then throw away."

> Another good strategy for optimizing such queries is to use a deferred join, which again is our term for **using a covering indexing to retrieve just the primary key columns of the rows you'll eventually retrieve**.

(Emphasis mine.)

The query is written with a deferred join:

```sql
SELECT <cols> FROM profiles INNER JOIN (
   SELECT <primary key cols> FROM profiles
   WHERE ... ORDER BY rating LIMIT 100000, 10
) AS x USING(<primary key columns>);
```

The third and last mention of deferred join occurs in chapter 6 ("Query Performance Optimization") section "Optimizing LIMIT and OFFSET".
The authors write that "One simple technique to improve efficiency is to do the offset on a covering index, rather than the full rows. You can then join the result to the full row and retrieve the additional columns you need."

That's cryptic because how does one "do the offset on a covering index"?
The limit and offset are numbers not columns, but indexes cover columns?
The authors don't explain, but I will later in this blog post because&mdash;spoiler&mdash;it's the magic that makes a deferred join powerful.

The example SQL given here is functionally equivalent the previous example SQL, but here the context is explicitly optimizing LIMIT and OFFSET.

> This "deferred join" works because **it lets the server examine as little data as possible in an index without accessing rows**, and then, once the desired rows are found, join them against the full table to retrieve the other columns from the row. A similar technique applies to joins with LIMIT clauses.

(Emphasis mine.)

That's all Peter, et al. wrote about deferred join in _High Performance MySQL, 3rd Edition_.

## Applicability

According to HPM 3d, a deferred join uses a _covering index_ for the inner (sub) query.
Mention of covering index is common to all three examples.
However, a covering index is not the sole reason that makes a differed join so powerful.
If that were the case, then you could just use a covering index.

Moreover, every resource on the internet I can find about deferred join (except Peter's 2007 blog post) associates it with `LIMIT offset, n` pagination.
For example, <a href="https://aaronfrancis.com/2022/efficient-pagination-using-deferred-joins" target="top">Efficient Pagination Using Deferred Joins</a> by Aaron Francis associates the two: "A deferred join is a technique that defers access to requested columns until after the offset and limit have been applied."
While it is an optimization for that pagination technique, it applies more widely, as evidenced by Peter's 2007 blog post (no `ORDER BY`) and the first example in HPM 3e where it's defined (no `LIMIT`).

As is customary on the internet, not all resources about deferred join are clear or accurate.
For example, one resource uses `ORDER BY name` but doesn't give the schema.
Presumably, "name" is not unique, which means the sort order is non-deterministic.
An excellent write-up on this gotcha is [SQL - Is Your Sort Order Deterministic? A classic example of S.E.P. (Somebody Else’s Problem)](https://blog.kalvad.com/sql-paging-requires-a-deterministic-sort-order-a-classic-example-of-s-e-p-somebody-elses-problem/) by Gina Seto.
Remember this when you're paginating.

So what is deferred join, _really_?

## Deferred Join

<mark>_Deferred join_ is a query optimization that minimizes data access by pre-filtering rows in a [derived table](https://dev.mysql.com/doc/refman/en/derived-tables.html).</mark>

Good definitions are difficult when the subject is complex, subtle, and manifest in different ways.
I think that definition captures what's necessary and sufficient for a deferred join.

Before I break down that definition, let me introduce a concept that will anchor the two parts of the definition: ideal data access.

_Ideal data access_ is reading only the full rows in the final result set.

Let's say you have 10 rows numbered 1 through 10.
And let's say that, whatever else a query is doing, the final result set is rows 9 and 10.
Ideal data access is reading only full rows 9 and 10 and _nothing_ else&mdash;not even a secondary index read.

Ideal data access is possible for very simple primary key lookups without other conditions.
`SELECT ... FROM t WHERE <primary key col> IN (9, 10)` is one such example: MySQL will read rows 9 and 10, and nothing else.

But ideal data access is not the norm.
Queries typically have many conditions that cause MySQL to read rows that don't make into the final result set.
This is why query metrics have, for a long time, included "rows examined" and "rows sent": the ratio is a gauge of ideal data access.
1-to-1 rows examined to rows sent is ideal data access.

Note, however, that this applies only to MySQL.
If the application receiving the rows doesn't need or use some of the rows, then the application isn't ideal.
But that's outside MySQL, so outside the current scope.

Certain optimizations figuratively move the query closer to ideal data access.
Deferred join does this by minimizing data access.

#### Minimize data access

It might seem obvious that minimizing data access is necessary for a query optimization.
But not all optimization minimize data access: some make data access more _efficient_.
For example, optimizations that yield sequential access rather than random access.

For simplicity, let's focus on the canonical example for a deferred join optimization:  `LIMIT offset, n` pagination.
Later in [Analyses](#analyses), I'll use different queries to further prove that deferred join applies more widely, as defined above.

<p class="note">
<code>LIMIT offset, n</code> pagination is short for <code>ORDER BY col LIMIT offset, n</code>: the ORDER BY is presumed (pagination doesn't make much sense without it) but omitted for brevity.
</p>

It's important to remember that, normally, MySQL reads full rows.
For example, `LIMIT 500, 10` reads and throws away 500 full rows.
This is why `LIMIT offset, n` pagination is the canonical example for a deferred join optimization: high offsets waste a lot of data access.
Far from ideal data access.

For `LIMIT offset, n` that means just the `n` rows.
But there's a problem that neither HPM 3e nor current resources on the internet state: `LIMIT` is applied to the final result set.
In other words, LIMIT happens last.
(Not always, but generally speaking.)
This is another reason that "do the offset on a covering index" from above is cryptic: since LIMIT happens last, there's no time to "do the offset" to avoid wasting `offset` number of full row reads.

But now we know what we need: <u>`LIMIT` to apply early and not to full rows</u>.

That's not possible with a single query, but with two queries...

#### Pre-filter rows in a derived table

> A derived table is an expression that generates a table within the scope of a query FROM clause. For example, a subquery in a SELECT statement FROM clause is a derived table:
> <br><br>
> &nbsp;&nbsp;&nbsp;`SELECT ... FROM (subquery) [AS] tbl_name ...`

https://dev.mysql.com/doc/refman/en/derived-tables.html

The real magic behind a deferred join is using a derived table to pre-filter rows so that the outer query can achieve ideal data access.
As originally defined (in HPM 3e and quoted above), the subquery should use a covering index to avoid reading full rows.
I don't think this is strictly necessary as long as the subquery minimizes data access for the outer query.
It's difficult to imagine doing that without a covering index, but I bet someone will find a way.

Before using real queries and EXPLAIN plans, let's finish the breakdown of my definition for deferred join.
For simplicity, I'll use fake queries:

<div class="sidebyside">
<div>
<i>Simple Query</i>

```sql {linenos=true}
select * from t order by x limit 500, 20
 
 
```
</div>
<div class="right">
<i>Optimized Query</i>

```sql {linenos=true}
select * from t join (
  select pk from t order by x limit 500, 20
) dt using(pk)
```
</div>
</div>

Presume `pk` is the primary key column, and there's a unique index on column `x`, and the table has several other columns.

For the simple query, even with a unique index on `x`, MySQL has to read 500 + 20 full rows (and discard the first 500) because the index covers only columns `x` and (hidden on the end) `pk`.
The query planner might not even use the index because secondary index lookups require a corresponding primary key lookup, so it might be faster to do a full table scan and sort.
And to make matters worse: the query planner might be wrong about that; you have to do your own benchmarks to know for sure.
In any case, the larger the offset becomes, the farther the simple query is from ideal data access because MySQL reads full rows and applies LIMIT last.

But the subquery in the optimized query (line 2) executes first and it uses a covering index (on `x, (pk)`) to avoid reading full rows.
_This is very fast_.
And it's exactly what we need: <u>`LIMIT` to apply early and not to full rows</u>.
Granted, the subquery must also throw away 500 _values_ that it read from the covering index, but that's an in-memory operation at least one order of magnitude faster than reading full rows.

The subquery "tells" the outer query which rows to read by primary key value, which is also very fast.
(More technically, the subquery creates an in-memory derived table that's joined to the primary table using the primary key column, in this example.)
And that's how the outer query minimizes data access&mdash; in this case, it even achieves ideal data access.

<p class="note">
The term "pre-filter" is not standard.
I chose it for my definition of "deferred join" because I think it accurately describes the intent and requirement of a deferred join.
If the subquery doesn't help reduce row access in the outer query, then it probably hurts more than it helps.
Moreover, in HPM 3e, Peter, et al. benchmark the results of the inner query returning a various number of rows (Table 5-2).
TL;DR: the subquery shouldn't return too many <em>or too few</em> rows to the outer query.
</p>

## Analyses

Since you can easily find examples of deferred join optimizing `LIMIT OFFSET` pagination, let's analyze two different examples to prove that it has wider applicability.

### PZ

It's been 16 years since Peter wrote [Using delayed JOIN to optimize count(\*) and LIMIT queries](https://www.percona.com/blog/using-delayed-join-to-optimize-count-and-limit-queries/); I think it's time to finally explain his example more clearly.
Plus, we have two things today that Peter didn't have back then: [`EXPLAIN ANALYZE`]({{< ref "book-2" >}}) and [Finch](https://github.com/square/finch).

<div class="sidebyside">
<div>
<i>Simple Query</i>

```sql {linenos=true}
select
  i, pad
from
  fact
  left join dim on val=id
where
  i<100000
limit 500000,10;
```
</div>
<div class="right">
<i>Optimized Query</i>

```sql {linenos=true}
select
  i, pad
from
  (select i, val from fact where i<100000 limit 500000,10) res
  left join dim on val=id;
 
 
 
```
</div>
</div>

Those are the queries in Peter's 2007 blog post.
This is not a matter of pagination; it's a matter of facts and dimensions&mdash;data warehouse stuff that's not important right now.
What's important is that we're joining two tables: `fact` and `dim`.

Here are the table definitions and abridged EXPLAIN plans for each query:

```sql
CREATE TABLE `fact` (
  `i` int(10) unsigned NOT NULL,
  `val` int(10) unsigned NOT NULL,
  KEY `i` (`i`,`val`)
)

CREATE TABLE `dim` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `pad` varchar(100) NOT NULL,
  PRIMARY KEY  (`id`)
)
```

```none
/* Simple */
+----+-------------+-------+--------+---------------+---------+----------+---------+--------------------------+
| id | select_type | table | type   | possible_keys | key     | ref      | rows    | Extra                    |
+----+-------------+-------+--------+---------------+---------+----------+---------+--------------------------+
|  1 | SIMPLE      | fact  | range  | i             | i       | NULL     | 1681002 | Using where; Using index |
|  1 | SIMPLE      | dim   | eq_ref | PRIMARY       | PRIMARY | fact.val |       1 | NULL                     |
+----+-------------+-------+--------+---------------+---------+----------+---------+--------------------------+

/* Optimized */
+----+-------------+------------+--------+---------------+---------+---------+---------+--------------------------+
| id | select_type | table      | type   | possible_keys | key     | ref     | rows    | Extra                    |
+----+-------------+------------+--------+---------------+---------+---------+---------+--------------------------+
|  1 | PRIMARY     | <derived2> | ALL    | NULL          | NULL    | NULL    |  500010 | NULL                     |
|  1 | PRIMARY     | dim        | eq_ref | PRIMARY       | PRIMARY | res.val |       1 | NULL                     |
|  2 | DERIVED     | fact       | range  | i             | i       | NULL    | 1681002 | Using where; Using index |
+----+-------------+------------+--------+---------------+---------+---------+---------+--------------------------+
```

The first EXPLAIN plan for the simple query demonstrates why this in-depth study of deferred join is a useful lesson for MySQL query optimization: it's a good execution plan, the query is very simple, and there are no obvious challenges like `ORDER BY foo DESC, bar ASC` (practically impossible to optimize an ascending and descending sort).
The 1,681,002 row estimate is a little concerning (it's really only 701,871 rows; EXPLAIN uses estimates/table statistics), but with a covering index ("Using index") we might disregard this query as "good enough"... until we learn that it takes over 1 second to execute.

And now for an "I told you so" moment:

> Ironically, you can expect the majority of slow queries to use an index lookup. That’s ironic for two reasons. First, indexes are the key to performance, but a query can be slow even with a good index. Second, after learning about indexes and indexing (Chapter 2), engineers become so good at avoiding index scans and table scans that only index lookups remain, which is a good problem but ironic nonetheless.

That's from chapter 3 of my book, [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) section "Indexes May Not Help".
That chapter is titled "Data" and it's relevant to everything discussed here, so please go read it (and the rest of the book).

The second EXPLAIN plan for the deferred join is an interesting example of MySQL not revealing what's really going on under the hood.
For decades, MySQL DBAs had only this output.
But as of MySQL 8.0.18, EXPLAIN ANALYZE really reveals what's going on, so let's do the EXPLAIN again, same order (top: simple; bottom: optimized with deferred join):

```
/* Simple */
-> Limit/Offset: 10/500000 row(s)  (cost=925269 rows=10) (actual time=1283..1283 rows=10 loops=1)
    -> Nested loop left join  (cost=925269 rows=1.68e+6) (actual time=0.652..1253 rows=500010 loops=1)
        -> Filter: (fact.i < 100000)  (cost=336918 rows=1.68e+6) (actual time=0.0426..467 rows=500010 loops=1)
            -> Covering index range scan on fact using i over (i < 100000)  (cost=336918 rows=1.68e+6) (actual time=0.0386..401 rows=500010 loops=1)
        -> Single-row index lookup on dim using PRIMARY (id=fact.val)  (cost=0.25 rows=1) (actual time=0.00126..0.00131 rows=1 loops=500010)

/* Optimized */
-> Nested loop left join  (cost=461925 rows=10) (actual time=419..419 rows=10 loops=1)
    -> Table scan on res  (cost=336919..336921 rows=10) (actual time=419..419 rows=10 loops=1)
        -> Materialize  (cost=336919..336919 rows=10) (actual time=419..419 rows=10 loops=1)
            -> Limit/Offset: 10/500000 row(s)  (cost=336918 rows=10) (actual time=419..419 rows=10 loops=1)
                -> Filter: (fact.i < 100000)  (cost=336918 rows=1.68e+6) (actual time=0.015..392 rows=500010 loops=1)
                    -> Covering index range scan on fact using i over (i < 100000)  (cost=336918 rows=1.68e+6) (actual time=0.0137..330 rows=500010 loops=1)
    -> Single-row index lookup on dim using PRIMARY (id=res.val)  (cost=0.25 rows=1) (actual time=0.00274..0.00279 rows=1 loops=10)
```

<p class="note">
If you're new to reading this output, read <a href="{{< ref "book-2" >}}">my post about EXPLAIN ANALYZE</a>.
</p>

Starting with the simple query again, the important points are:

* The LIMIT happens last (1st node), just as discussed earlier in [Minimize data access](#minimize-data-access).
* The JOIN reads 500,010 row reads in `dim` (last node: loops=500010), but 500k are discarded later by the LIMIT.
* Even though the JOIN uses a "Single-row index lookup" (very fast `eq_ref`), it's slow because it's still 500,010 rows read: 0.00131 &times; 500010 loops = 655ms. This adds up correctly: 655 + 467 ("Filter:" node) = 1,122ms: close enough to the "Nested loop left join" parent node: 1253ms.

Now the optimized query with a deferred join:

* Different execution plan with the same stages as before plus two new ones: "Table scan on res" and "Materialize".
* The LIMIT happens early (4th node) and only to values (_not rows_) from `fact`. Remember the cryptic advice "do the offset on a covering index" from [2012: HPM 3e](#2012-hpm-3e)? This is what it means; the covering index is 6th node. It's only possible when this part of query execution is "factored out" (to use a programming term) into a subquery that executes before the rest of the (outer) query (nodes 1, 2, and 7 [last]).
* "Materialize" is part of the magic that the normal EXPLAIN output doesn't reveal in this case. See [Optimizing Subqueries with Materialization](https://dev.mysql.com/doc/refman/en/subquery-materialization.html) and [Optimizing Derived Tables, View References, and Common Table Expressions with Merging or Materialization](https://dev.mysql.com/doc/refman/en/derived-table-optimization.html) in the MySQL manual.
* The JOIN (1st node) takes virtually zero time because it joins the materialized derived table that has only 10 primary key values (since the LIMIT has already been applied), as evidenced by "loops=10" in the last node.

To reproduce this example, use [Finch](https://github.com/square/finch) to run [hackmysql/benchmarks/deferred-join/pz/](https://github.com/hackmysql/benchmarks/tree/main/deferred-join/pz).

### Negative Balances

To test my [definition of deferred join](#deferred-join), I needed a query unlike anything written about before.
So I decided to use the Finch example benchmark called [xfer](https://github.com/square/finch/tree/main/benchmarks/xfer), specifically the [`balances` table](https://github.com/square/finch/blob/main/benchmarks/xfer/trx/schema.sql) with an added nonunique index on the `cents` column.
The simple query and its EXPLAIN are:


```none
EXPLAIN SELECT * FROM balances WHERE cents < 0 LIMIT 10;
+----+-------------+----------+-------+---------------+-------+------+-------+----------------------------------+
| id | select_type | table    | type  | possible_keys | key   | ref  | rows  | Extra                            |
+----+-------------+----------+-------+---------------+-------+------+-------+----------------------------------+
|  1 | SIMPLE      | balances | range | cents         | cents | NULL | 55058 | Using index condition; Using MRR |
+----+-------------+----------+-------+---------------+-------+------+-------+----------------------------------+
```

That query returns any 10 negative balances.
On my laptop, it's max execution time is 23 milliseconds (slow log snippet):

<pre>
# Query_time: <mark><b>0.023139</b></mark>  Lock_time: 0.000003 Rows_sent: 10  Rows_examined: 10
select * from balances where cents<0 limit 10;
</pre>

This query is even faster and simpler than Peter's two-table JOIN in the previous section.
Moreover, MySQL automatically applies two query optimizations: [index condition pushdown (ICP)](https://dev.mysql.com/doc/refman/en/index-condition-pushdown-optimization.html) and [multi-range read (MRR)](https://dev.mysql.com/doc/refman/en/mrr-optimization.html).
Especially with ICP, it's difficult to imagine how rewriting this as a deferred join would make it faster.
Let's see a slow log snippet for the deferred join version:

<pre>
# Query_time: <mark><b>0.000776</b></mark>  Lock_time: 0.000006 Rows_sent: 10  Rows_examined: 20
select * from balances join (select id from balances where cents<0 limit 10) dt using (id);
</pre>

776 _microseconds_!
Well there you have it: deferred join is amazing and can't be beat.

### Not So Fast (Literally)

Does 23 _milliseconds_ for an index range scan with ICP on 55,000 rows seem right?
Not to me.
Let's look at EXPLAIN ANALYZE for both queries:

```
/* Simple */
-> Limit: 10 row(s)  (cost=53611 rows=10) (actual time=20.1..20.1 rows=10 loops=1)
    -> Index range scan on balances using cents over (cents < 0), with index condition: (balances.cents < 0)  (cost=53611 rows=55058) (actual time=20.1..20.1 rows=10 loops=1)

/* Optimized */
-> Nested loop inner join  (cost=11133 rows=10) (actual time=0.0787..0.127 rows=10 loops=1)
    -> Table scan on dt  (cost=11121..11124 rows=10) (actual time=0.0618..0.0659 rows=10 loops=1)
        -> Materialize  (cost=11121..11121 rows=10) (actual time=0.0601..0.0601 rows=10 loops=1)
            -> Limit: 10 row(s)  (cost=11120 rows=10) (actual time=0.0256..0.0431 rows=10 loops=1)
                -> Filter: (balances.cents < 0)  (cost=11120 rows=55058) (actual time=0.0247..0.0404 rows=10 loops=1)
                    -> Covering index range scan on balances using cents over (cents < 0)  (cost=11120 rows=55058) (actual time=0.0226..0.0359 rows=10 loops=1)
    -> Single-row index lookup on balances using PRIMARY (id=dt.id)  (cost=0.844 rows=1) (actual time=0.00535..0.00545 rows=1 loops=10)
```

Granted, the optimized query (deferred join) uses a covering index, but ICP in the simple query is essentially the same optimization _in this case_ (not generally speaking) because it allows InnoDB to fetch only 10 rows as evidenced by "rows=10" in the 2nd node.
That's ideal data access, and we know the LIMIT is not slow (it doesn't fetch rows; it just discards them), so how can reading 10 rows with ICP be _so slow_?

This is a case where experience is necessary to know what MySQL isn't telling you.
I don't know why basic EXPLAIN shows MRR but the more verbose EXPLAIN ANALYZE does not, but I know from experience that MRR can be a problem: MRR can increase response time rather than decreasing it.

It's funny because MRR sounds like a great optimization:

> MRR enables data rows to be accessed sequentially rather than in random order...

Remember earlier when I said some optimizations yield sequential access rather than random access?
MRR is one such optimization.
And yet we can prove that it's seriously hurting performance: `SET GLOBAL optimizer_switch="mrr=off"` and re-run the benchmarks:

<pre>
# Query_time: <mark><b>0.000317</b></mark>  Lock_time: 0.000003 Rows_sent: 10  Rows_examined: 10
select * from balances where cents<0 limit 10;
</pre>

317 microseconds! 🤯

I've observed this simple query as fast as 184 &micro;s, but don't take my word for it: use [Finch](https://github.com/square/finch) to run [hackmysql/benchmarks/deferred-join/balance](https://github.com/hackmysql/benchmarks/tree/main/deferred-join/balance).

---

I suspect there are more ways to use a deferred join to optimize a query because, at base, deferred join uses SQL to overcome a MySQL limit: one query, one plan.
(Subqueries notwithstanding.)
In that one plan, MySQL has to figure out how to do everything the query requires: find rows, filter rows, sort rows, limit rows, join rows&mdash;and _a lot_ more.
I call it a "limit" but that's not a criticism: one plan is tremendously difficult and MySQL does a really great job; more than one plan would be a problem probably few humans could solve reliably in code.
The cleverness of deferred join is that it uses a derived table join to hack in a second plan: same query, but executed in two steps instead of one.
Usually "less is more", but in this case more is more.
