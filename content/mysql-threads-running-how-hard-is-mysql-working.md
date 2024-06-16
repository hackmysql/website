---
type: "page"
date: "2020-04-25T16:18:00-03:00"
title: "MySQL Threads Running"
subtitle: "How Hard is MySQL Working?"
tags: ["mysql", "threads running", "metrics"]
comments: true
aliases:
  - /post/mysql-threads-running-how-hard-is-mysql-working/
disqus_url: "https://hackmysql.com/post/mysql-threads-running-how-hard-is-mysql-working/"
---

Queries per second (QPS) measures database throughput, but it does not reflect how hard MySQL is working. The latter is measured by _[Threads_running](https://dev.mysql.com/doc/refman/8.0/en/server-status-variables.html#statvar_Threads_running)_, expressed as a gauge (whereas QPS is a rate). Before discussing _Threads_running_, let's consider an analogy:

<!--more-->

![Digital instrument cluster](/img/digital-instrument-cluster.jpg)

The image above is a digital instrument cluster from a car. The big circle on the left is the speedometer, and the big circle on the right is the tachometer. Speedometers are familiar to most: they show how fast the car is going. Above, the speedometer reads 84 km/h. Tachometers are common but not included in every instrument cluster. They show how hard the engine is working, measured in revolutions per minute (RPM). Above, the tachometer reads just under 3,000 RPM. (The "M3" in the middle of the tachometer is the transmission gear. We can ignore that.)

QPS is analogous to speed (84 km/h), and _Threads_running_ is analog to RPM (~3k RPM).

Speed and RPM vary greatly due to many factors: acceleration and deceleration, going uphill or downhill, headwind or tailwind, and (increasingly in newer cars) computer programming to optimize fuel economy. Consequently, the same speed can be achieved at different RPMs, but typically cars burn less fuel at lower RPMs and more fuel at higher RPMs. Also, higher RPMs mean greater stress on the engine which increases the chance of mechanical failure. We care about burning fuel and mechanical failure because both cost us money. This is why cars have tachometers: RPM is an important metric.

QPS and _Threads_running_ also vary greatly due to many factors: hardware specs (CPU cores and speed, storage type and IOPs, etc.), query type (read vs. write), query plan, table size, row size, table schema (column types, indexes—especially indexes), data access patterns (all reads vs. all writes. vs. mix), "noisy neighbors", time of day (e.g. business hours), time of year (e.g. tax season), special promos, bad actors, backfills&mdash;you name it! Consequently, like a car, the same QPS can be achieved at different _Threads_running_, so it is an important metric.

<mark>Threads_running indicates how hard MySQL is working.</mark> Several databases where I work do 10,000 QPS with only 10 threads running. Others struggle do 3,000 QPS with 100 threads running. From the previous paragraphs we know why: varying factors.

QPS alone cannot tell us if MySQL is barely stressing the system or if, figuratively speaking, it is starting to burn oil and grind to a halt.

It is critical to monitor and address high _Threads_running_. A tachometer has a maximum value that you usually cannot push a car beyond, but MySQL is very ambitious: it has no maximum value and it will try to run as many threads as needed. It will try, but it will slow and eventually fail as _Threads_running_ increases:

| Threads_running | MySQL |
| --------------- | ----- |
| 0 - 10          | Normal: no problem for almost all hardware |
| 10 - 30         | Busy: usually ok for most hardware since modern servers have as many CPU cores |
| 30 - 50         | High: very few workloads need this many threads running. It can work for sustained bursts (< 5min), but response time will most likely be unacceptable if sustained long-term. |
| 50 - 100        | <span style="color:red">Overloaded</span>: some hardware can handle this, but do not expect to operate successfully in this range. Momentary bursts (< 5s) in this range are usually ok for our production on-premise hardware.
| > 100           | <span style="color:red">Failing</span>: in rare cases, MySQL can run > 100 threads, but expect failure in this range|

TL;DR guideline values:

* _Threads_running_ < 50
* 1:1000 _Threads_running_ to QPS

Let's switch gears and clarify an important point: a MySQL thread is one database connection. _Threads_running_ is the number of database connections with an active query. It is important to remember that each app instance has its own database connection pool. Therefore, the maximum possible connections (threads) is: `Max Connections = App Instances * Database Connection Pool Size`

A connection pool size of 100 is reasonable, but if the app is deployed to 5 app instances there could be 500 database connections. This is often the case: apps usually have hundreds of idle database connections, which is the purpose of a connection pool. (MySQL has a metrics for threads connected, too.) It's not a problem until too many connections (threads) are running at once.

More than once has an app scaled out (i.e. deployed to more app instances) to handle more requests but, in so doing, overloaded the database with too many threads running. There is no quick or easy solution to fix this type of database performance limit. The reason is simple: if you want MySQL to do more units of work (queries) in the same amount of time (per second), each unit must take less time, else the math does not add up. If a query takes 100ms, it is impossible to do more than 10 QPS. "Ah, but what about using more CPU cores?", you ask. 

Gotcha! Using another CPU core means running another thread, and now we're moving quickly toward a much lower ceiling: 50 threads running. But this is exactly what MySQL tries to do. As mentioned earlier, MySQL is very ambitious: it has no maximum value for _Threads_running_ and it will try to run as many threads as needed. Whereas the ceiling for QPS (if one exists) is very high, the ceiling for _Threads_running_ is very low. Why is this?

50 threads running is a reasonable ask. By now, 2020, even 1,000 threads running should be a reasonable ask. Let me answer the question with another question: Why does a Toyota not have the speed and power of a Ferrari? The top speed of a Toyota is 200 km/h, and a Ferrari is 340 km/h. Why can't the Toyota just go faster? Why can't MySQL just go faster?

The answer for both is in every single detail of engineering. A Ferrari, for example, goes really fast because it has a really large, powerful engine, but you can't stop there. Every detail of the car is designed either to enable that power or not break under it. For example, an airplane can take off and fly at 258 km/h, so a Ferrari at 340 km/h will fly unless the aerodynamics of its body keep it on the ground. A Toyota can go 340 km/h if engineered to. And MySQL can run 1,000 threads if engineered to.

Like a Toyota, MySQL is well-built, dependable, and more than you need, but nothing about it or around it&mdash;hardware, operating system, and application&mdash;are engineered to be a Ferrari.

Real-world experience shows that MySQL does not performance well for most applications past 50 threads running. Back in 2014, MySQL expert Alexey Straganov benchmarked MySQL 5.6 with very high _Threads_running_: [Percona Server: Improve Scalability with Percona Thread Pool](https://www.percona.com/blog/2014/01/23/percona-server-improve-scalability-percona-thread-pool/). TL;DR: performance peaks at 64 threads running. Those are lab results; real application queries are more challenging than synthetic benchmark queries.

The solution? Scale out the database by sharding. But that's another long topic.

Let's end on a positive note. Perhaps the world's foremost expert on MySQL performance is Vadim Tkachenko, and he recently achieved 100,000 threads running: [MySQL Challenge: 100k Connections](https://www.percona.com/blog/2019/02/25/mysql-challenge-100k-connections/). There are no limits.
