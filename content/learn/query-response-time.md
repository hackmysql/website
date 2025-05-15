---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Query Response Time"
weight: 1
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn MySQL query response time:

<div class="intro">
Performance is query response time.

This book explores that idea from various angles with a single intent: to help you achieve remarkable MySQL performance.
<i>Efficient</i> MySQL performance means focusing on the best practices and techniques that directly affect MySQL performance&mdash;no superfluous details or deep internals required by DBAs and experts.
I presume that you’re a busy professional who is using MySQL, not managing it, and that you need the most results for the least effort.
That’s not laziness, that’s efficiency.
To that end, this book is direct and to the point.
And by the end, you will be able to achieve remarkable MySQL performance.

MySQL performance is a complex and multi-faceted subject, but you do not need to become an expert to achieve remarkable performance.
Focus dramatically narrows the scope of MySQL complexity and allows me to show you what is essential.
MySQL performance begins with query response time.

<i>Query response time</i> is how long it takes MySQL to execute a query.
Synonymous terms are: <i>response time</i>, <i>query time</i>, <i>execution time</i>, and (inaccurately) <i>query latency</i>.
Timing starts when MySQL receives the query and ends when it has sent the result set
to the client.
Query response time comprises many stages (steps during query execution) and waits (lock waits, I/O waits, and so on), but a complete and detailed breakdown is neither possible nor necessary. As with many systems, basic troubleshooting and analysis reveal the majority of problems.

{{< book-excerpt-copyright c="Chapter 1" >}}
</div>

## Key Points

* Performance is query response time
* Query response time is the North Star of MySQL performance because it's the only metric users _experience_
* Query response time is one of several _query metrics_: metrics about queries, not the server
* Query metrics originate from the slow query log or the Performance Schema
* The Performance Schema is the best source of query metrics
* Query metrics are grouped and aggregated by digest: normalized SQL statements
* A query profile shows queries sorted descending by total time; the first is the "slowest"&dagger;
* A query report shows all available information for one query; it’s used for query analysis
* The goal of query analysis is understanding query execution, not solving slow response time
* Query analysis requires query metrics, metadata (EXPLAIN plans, table structures, and so on), and knowledge of the application
* Improving query response time (query optimization) has two parts: direct query optimization, then indirect query optimization
* Direct query optimization is changes to queries and indexes
* Indirect query optimization is changes to data and access patterns
* The best way to make MySQL faster is to improve response time

&dagger; Some tools can sort queries by other metrics, but total time is the virtually universal default.

## Pitfalls

* Not understanding that, first and foremost, _performance is query response time_
* Not having or reviewing query metrics (slow queries)
* Waiting until there's a problem to review slow queries
* Using averages instead of the P95 or a higher percentile
* Not sorting queries by total time to find the slowest&dagger;
* Focusing only on server metrics to gauge performance

## Hack MySQL Articles

{{< path-articles path="qrt" >}}

## Additional Resources

| Resource | Type | About |
|----------|------|-------|
|[The Slow Query Log](https://dev.mysql.com/doc/refman/en/slow-query-log.html)|MySQL manual|Sparse for programmers but necessary for DBAs to read.|
|[Identifying and profiling problematic MySQL queries](https://planetscale.com/blog/identifying-and-profiling-problematic-mysql-queries) by Benjamin Dicken @ PlanetScale | Article | Excellent article on using Performance Schema to identify slow queries. Although this approach is manual (one typically uses a tool), it's good to know (and necessary to know if you're a DBA). |
|[_MySQL 8 Query Performance Tuning: A Systematic Method for Improving Execution Speeds_](https://www.amazon.com/MySQL-Query-Performance-Tuning-Systematic/dp/1484255836/) by Jesper Wisborg Krogh|Book|At over 900 pages, it might be more of a reference than a read. Part of the length is due to covering topics beyond what the title suggests ("Chapter 26. Replication", for example). Focus on the query performance turning parts and it's worth reading.|
|[pt-query-digest](https://docs.percona.com/percona-toolkit/pt-query-digest.html) @ Percona | Open source tool | The most venerable and widely-used tool for analyzing the MySQL slow query log. |
|[Deep Dive SQL Workload Analysis using pt-query-digest](https://severalnines.com/blog/deep-dive-sql-workload-analysis-using-pt-query-digest/) @ Severalnines | Article | Exactly what the article title says. Although originally publish in 2015, this article was updated in 20222 and is still valid. |
|[Deep Dive into MySQL Query Performance](https://archive.fosdem.org/2023/schedule/event/deep_dive_mysql_perf/) by Peter Zaitsev @ FOSDEM 2023 | Conference presentation | Peter Zaitsev is a renowned MySQL expert. All his presentations are worth watching.|
|[Rows Examined Blindspot when Looking for non-Existing Data](https://jfg-mysql.blogspot.com/2023/06/rows-examined-blindspot-when-looking-for-non-existing-data.html) by Jean-François Gagné | Article | Good to know article about the `Rows_examined` query metric. |
|[Rows Examined not Trustworthy because of Index Condition Pushdown](https://jfg-mysql.blogspot.com/2022/03/rows-examined-not-trustworthy-because-index-condition-pushdown.html) by Jean-François Gagné  | Article | Another interesting article about the `Rows_examined` query metric. |
