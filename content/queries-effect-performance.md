---
date: "2020-01-12"
title: "Queries Effect Performance"
tags: ["mysql", "performance", "queries"]
aliases:
  - /post/queries-effect-performance/
params:
  path: qrt
---

Queries _effect_ database performance. That's not a typo: "effect" not "affect". The difference is not a word game but an important way to think about database performance.

Many things can affect performance. For example, if the system runs out of memory then starts swapping which causes high disk IO latency, that will negatively affect performance. But external factors like that notwithstanding (i.e. when hardware and MySQL are normal and stable), it's important to understand that queries effect performance.

## MySQL has one job

MySQL does only one thing: execute queries. Queries are the cause of everything MySQL does, and performance is the measured effect. Without queries, MySQL is idle and there is no performance to measure.  Therefore, queries effect performance.

For new engineers and non-database experts, this is important to understand when troubleshooting poor performance because it focuses attention on the most likely cause: queries. A common misunderstanding is that poor performance is primarily caused by MySQL or hardware. It can be, but it's primarily caused by queries, so effective troubleshooting begins with queries.

## Why not MySQL or hardware?

MySQL and hardware _can_ be the cause of poor performance, but they're usually not unless the hardware is very limited or MySQL is grossly misconfigured. With respect to hardware, modern CPUs are fast, RAM is plentiful, and SSD is standard. (In the cloud, this might be a different story. Cheap cloud compute can be extremely limited for a database. Be careful.) And MySQL really only has one configuration that needs to be set properly: [InnoDB buffer pool size](https://dev.mysql.com/doc/refman/5.7/en/innodb-buffer-pool-resize.html). (There are many settings, but performance is primarily determined by IDB buff pool size.) In my experience, poor performance caused by MySQL or hardware is the exception, not the norm.

## Why queries?

Let's use an analogy: baking cookies. You are a master chef (properly configured MySQL), and you have a professional kitchen (powerful hardware). I (the application) give you various ingredients (queries). Whatever I give you, you must use to bake cookies (MySQL executes every query). And we have customers buying these cookies, so we need to keep up with demand (query response time).

What do you need to be successful (good performance)? Since you're a master chef with a professional kitchen, you only need me to give you the correct ingredients in the correct amounts at the correct times. If I do, then you can bake all the cookies our customers demand. Problems with you and the kitchen (MySQL and hardware) notwithstanding, everything depends on me (app) and the ingredients (queries).

If I give you all the right ingredients but forget the sugar, the result will look like cookies but taste terrible. Or, if I give you too much salt and you decide to throw away the salty cookies and bake new ones, that increases customer wait time now and for the next batch of cookies. Or, if I give you 10x all the right ingredients because we went viral and customers are forming a line around the block, can you keep up? Maybe, but it depends on other factors: how many mixing bowls and baking sheets are there? How many ovens and racks are there? How fast can we wash and reuse the cooking utensils? Do the cookies have nuts, and if so, are some customers allergic?

With problems like these, troubleshooting the chef or kitchen won't help; we have to address the ingredients. Performance is a direct result of problems with the ingredients. Likewise, MySQL works with what it's given: queries. With a good configuration (mostly InnoDB buffer pool size) and decent hardware, performance is a direct result of queries. So troubleshooting MySQL and hardware won't help.

## Effect and affect

"MySQL performance" is not a thing. It's not a feature or subsystem of MySQL, like semi-synchronous replication or page flushing. It's not even a known characteristic of the system, like horsepower is to a car. MySQL, all by itself, has no performance. Performance is a measurement. There are many potential measurements, but the one that matters most is how fast it executes queries&mdash;query response time. This is why it's grammatically correct to say that queries effect performance.

But for completeness, it's also true that queries can affect performance. A common case: data backfills. An otherwise good database starts to run slowly because non-typical queries for a data backfill cause MySQL to lock a lot of rows, as one example. In this case, the backfill queries are affecting the performance of the normal queries. And all queries together effect total MySQL performance.

## Conclusion

This isn't a blog post about query optimization, which is covered by countless other blogs and books. The point is to understand that queries effect database performance. When troubleshooting a slow database under normal conditions (i.e. when hardware and MySQL are normal and stable), queries are the cause. Instead of asking, "What's wrong with MySQL? Why is it running slowly?", ask, "Which queries are using the most of MySQL's time? How can we make them faster?" It's a subtle but important shift in thinking.
