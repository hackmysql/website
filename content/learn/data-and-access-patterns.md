---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Data and Access Patterns"
weight: 3
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn about MySQL data storage and access patterns:

<div class="intro">
Even when you master indexes and indexing, you will encounter queries that are simple and properly indexed but still slow.
That’s when you begin to optimize <i>around</i> the query, starting with the data that it accesses.
To understand why, let’s think about rocks.

Imagine that your job is to move rocks, and you have three piles of different sized rocks.
The first pile contains pebbles: very light, no larger than your thumbnail.
The second pile contains cobbles: heavy but light enough to pick up, no larger than your head.
The third pile contains boulders: too large and heavy to pick up; you need leverage or a machine to move them.
Your job is to move one pile from the bottom of a hill to the top.
Which pile do you choose?

I presume that you choose the pebbles because they’re light and easy to move.
But there’s a critical detail that might change your decision: weight.
The pile of pebbles weighs two metric tons (the weight of a full-size SUV).
The pile of cobbles weighs one metric ton (the weight of a very small car).
And there’s only one boulder that weighs half a metric ton (the weight of ten adult humans).
Now which pile do you choose?

On the one hand, the pebbles are still a lot easier to move.
You can shovel them into a wheelbarrow and roll it up the hill.
There’s just a lot of them (pebbles, not wheelbarrows).
The boulder is a fraction of the weight, but its singular size makes it unwieldy.
Special equipment is need to move it up the hill, but it’s a one-time task.
Tough decision.

Data is analogous to a pile of rocks, and executing queries is analogous to moving the rocks uphill.
When data size is small, direct query optimization is usually sufficient because the data is trivial to handle—like walking (or running) up a hill with a handful of pebbles.
But as data size increases, indirect query optimization becomes increasingly important—like lugging a heavy cobble up a hill and stopping midway to ask, "Can we do something about these rocks?"

Chapter 1 provided a "proof" that data size affects performance: `TRUNCATE TABLE` dramatically increases performance—but **do not** use this "optimization".
It's just a joke, but it also proves a point that is not frequently followed through to its logical consequence: _less data is more performance_.
You can improve performance by reducing data because less data requires less system resources (CPU, memory, storage, and so on).

But isn't _more_ data the reality and reason that drives engineers to learn about performance optimization?
Yes, and sharding addresses MySQL at scale, but first it’s imperative to learn to reduce and optimize data when it’s relatively small and problems are tractable.
Ignoring data size until it’s crushing the application is the most stressful time to learn.

---

_Access patterns_ describe how an application uses MySQL to access data.
Changing access patterns has a powerful affect on MySQL performance, but it usually requires a greater level of effort than other optimizations.
That’s why it’s the last leg of the journey: first optimize queries, indexes, and data—then optimize access patterns.
Let’s think again about rocks.

Suppose you have a truck, which is analogous to MySQL.
If used efficiently, the truck makes moving any pile of rocks uphill easy.
But if used inefficiently, the truck provides little value, and it might even make the job take longer than necessary.
For example, you could use the truck to haul the cobbles _one by one_ up the hill.
That’s easy for you (and the truck), but it’s terribly inefficient and time-consuming.
A truck is only as useful as the person who uses it.
Likewise, MySQL is only as useful as the application that uses it.

Sometimes, an engineer puzzles over why MySQL isn't running faster.
For example, when MySQL is executing 5,000 QPS and the engineer wonders why it’s not executing 9,000 QPS instead.
Or when MySQL is using 50% CPU and the engineer wonders why it’s not using 90% CPU instead.
The engineer is unlikely to find an answer because they’re focused on the effect (MySQL) rather than the cause: the application.
Metrics like QPS and CPU usage say very little—almost nothing—about MySQL; they only reflect how the application uses MySQL.

An application can outgrow the capacity of a _single_ MySQL instance, but again: that says more about the application than MySQL because there are innumerable large, high-performance applications using a single MySQL instance.
Without a doubt, MySQL is fast enough for the application.
The real question is: does the application use MySQL efficiently?
After many years with MySQL, hundreds of different applications, and thousands of different MySQL instances, I assure you: MySQL performance is limited by the application, not the other way around.

{{< book-excerpt-copyright c="Chapter 3 and Chapter 4" >}}
</div>

## Key Points

* Less data yields better performance
* Less QPS is better because it’s a liability, not an asset
* Indexes are necessary for maximum MySQL performance, but there are cases when indexes may not help
* The _Principle of Least Data_ means: store and access only needed data
* Ensure that queries access as few rows as possible
* Do not store more data than needed: data is valuable to you, but it’s dead weight to MySQL
* Deleting or archiving data is important and improves performance
* MySQL does nothing except execute application queries
* No database can utilize 100% of hardware capacity
* Data access patterns describe how an application uses a database
* You must change the application to change its data access patterns
* Scale up hardware to improve performance as the _last_ solution

## Pitfalls

* Scaling up hardware before optimizing queries
* Storing data without need or reason
* Not using efficient column types or data representations
* Not normalizing (and rarely: normalizing too much)
* Selecting columns that the app doesn't use
* Not limiting results when app only uses limited result
* Sorting too much (instead of sorting in app if possible)
* Not archiving old or unused data
* Archiving rows too fast, in batches too large, or both
* Thinking MySQL is slow instead of the application workload
* Access patterns that don't work well on a transactional OLTP RDBMS

## Hack MySQL Articles

{{< path-articles path="data" >}}

## Additional Resources

| Resource | Type | About |
|----------|------|-------|
|[Data Types](https://dev.mysql.com/doc/refman/en/data-types.html)|MySQL manual|Common knowledge for developers, but necessary to have a complete understanding of all MySQL data types.|
|[Optimizing InnoDB Disk I/O](https://dev.mysql.com/doc/refman/en/optimizing-innodb-diskio.html)|MySQL manual|Advanced and low-level. More suitable for DBAs than developers.|
|[Configuring InnoDB I/O Capacity](https://dev.mysql.com/doc/refman/en/innodb-configuring-io-capacity.html)|MySQL manual|Even more advanced and low-level. Not typically something developers need to know, but definitely something DBAs need to know.|
