---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Indexes and Indexing"
weight: 2
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn MySQL indexes and indexing:

<div class="intro">
Many factors determine MySQL performance, but indexes are special because performance cannot be achieved without them.
You can remove other factors—queries, schemas, data, and so on—and still achieve performance, but removing indexes limits performance to brute force: relying on the speed and capacity of hardware.
If this book were titled <i>Brute Force MySQL Performance</i>, the contents would be as long as the title: "Buy better, faster hardware."
You laugh but just a few days ago I met with a team of developers who had been improving performance in the cloud by purchasing faster hardware until stratospheric costs compelled them to ask, "How else can we improve performance?"

MySQL leverages hardware, optimizations, and indexes to achieve performance when accessing data.
Hardware is an obvious leverage because MySQL runs on hardware: the faster the hardware, the better the performance.
Less obvious and perhaps more surprising is that hardware provides the _least_ leverage.
I explain why in a moment.
_Optimizations_ refer to the numerous techniques, algorithms, and data structures that enable MySQL to utilize hardware efficiently.
Optimizations bring the power of hardware into focus.
And focus is the difference between a light bulb and a laser.
Consequently, optimizations provide more leverage than hardware.
If databases were small, hardware and optimizations would be sufficient.
But increasing data size _deleverages_ the benefits of hardware and optimizations.
Without indexes, performance is severely limited.

To illustrate these points, think of MySQL as a fulcrum that leverages hardware, optimizations, and indexes to figuratively lift data, as shown below.

<img src="/img/book/no_indexes.jpg" alt="No indexes">

Without indexes (on the right side), MySQL achieves limited performance with relatively small data.
But add indexes to the balance, and MySQL achieves high performance with large data:

<img src="/img/book/good_indexes.jpg" alt="Good indexes">

Indexes provide the most _and the best_ leverage.
They are required for any nontrivial amount of data.
MySQL performance requires proper indexes and indexing, both of which this chapter teaches in detail.

I have a story about the power of good indexes.
Several years ago, I designed and implemented an application that stores a lot of data.
Originally, I estimated the largest table not to exceed a million rows.
But there was a bug in the data archiving code that allowed the table to reach one _billion_ rows.
For years, nobody noticed because response time was always great. Why? Good indexes.

{{< book-excerpt-copyright c="Chapter 2" >}}
</div>

## Key Points

* Indexes provide the most and the best leverage for MySQL performance
* Do not scale up hardware to improve performance—that’s the last solution
* Tuning MySQL is not necessary to improve performance with a reasonable configuration
* An InnoDB table is a B-tree index organized by the primary key
* MySQL accesses a table by index lookup, index scan, or full table scan—index lookup is the best
* To use an index, a query must use a leftmost prefix of the index—the _leftmost prefix requirement_
* MySQL uses an index to find rows matching `WHERE`, group rows for `GROUP BY`, sort rows for `ORDER BY`, avoid reading rows (covering index), and to join tables
* `EXPLAIN` prints a _query execution plan_ (or _EXPLAIN plan_) that details how MySQL executes a query
* Indexing requires thinking like MySQL to understand the query execution plan
* Good indexes can lose effectiveness for a variety of reasons
* MySQL uses three algorithms to join tables: nested-loop join (NLJ), block nested-loop (BNL), and hash join

## Pitfalls

* Not having a left-most prefix
* Indexing "all the columns"
* Duplicate indexes
* Too many indexes
* Very low cardinality
* Focusing on advanced optimizations before mastering the basics
* Not realizing that indexes cannot provide infinite leverage (benefit)

## Hack MySQL Articles

{{< path-articles path="index" >}}

## Additional Resources

| Resource | Type | About |
|----------|------|-------|
|[Optimization and Indexes](https://dev.mysql.com/doc/refman/en/optimization-indexes.html)|MySQL manual|Foundational knowledge. Must read.|
|[Understanding the Query Execution Plan](https://dev.mysql.com/doc/refman/en/execution-plan-information.html)|MySQL manual|Foundational knowledge. Must read.|
|[Introduction to indexes](https://planetscale.com/learn/courses/mysql-for-developers/indexes/introduction-to-indexes) @ PlanetScale | Vidoes | Fantastic series of videos. Must watch. |
|[B-trees and database indexes](https://planetscale.com/blog/btrees-and-database-indexes) by Benjamin Dicken @ PlanetScale | Article | Fantastic article about B-tree indexes. Must read. |
|[_Database Internals_](https://www.databass.dev/) by Alex Petrov|Book|Fantastic book that provides deep, technical knowledge&mdash;including how B-tree indexes are implemented. Not written for MySQL but directly applicable to MySQL.|
