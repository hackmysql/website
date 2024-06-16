---
date: "2023-05-28"
title: "Benchmarking"
tags: ["eng", "benchmarking"]
summary: "A primer on the fundamentals of database benchmarking: results, workload, benchmark types, cheats, challenges, and reporting"
lastmod: "2023-07-01T14:11:00-04:00"
aliases:
  - /benchmarking
---

This page is a primer on database benchmarking fundamentals: useful results, workload fidelity and complexity, benchmark types, cheats (how to avoid being cheated), challenges, and reporting.
The focus is fundamentals, not practice, for two reasons.
First, there seems to be little written on the fundamentals and, consequently, I see engineers misapply the practice, misunderstand the results, or both.
Second, the practice is database- and benchmark tool-specific, so you can consult the specific documentation of your database and benchmark tool.

Database benchmarking fundamentals aren't profound or difficult, they're just often glossed over in favor of the results.
If you're running benchmarks, you need a solid understanding of the fundamentals to produce reliable, high-quality results.
If you're evaluating results, you need a solid understanding of the fundamentals to interpret and determine if they are useful.

## Useful Results

Benchmark results are useful when they help you make your database faster or cheaper.
Here's why.

A database only needs to be fast enough and affordable enough for the business (security, availability, and other considerations notwithstanding).
And most engineers work on database performance only when it's too slow or too expensive.
Even then, "slow" and "expensive" are usually determined by complaint: it's slow if users are complaining (else it's fast enough); and it's expensive if managers are complaining (else it's affordable enough).
Although this situation isn't efficient for the database, it persists because it's efficient for the business.

It's important to know when (and why) benchmark results are useful because they have many uses, but not all of them are useful to you.
For example, vendors often tout their products with alluring benchmark results.
But most times, those results aren't useful to you because they're based on unrealistic workload.
It's like a car company touting amazing fuel economy by rolling the car down a mountain.

Benchmarks are fun and interesting, but they're only _useful_ when they help you make your database faster or cheaper.

## Workload

Every database benchmark executes a _workload_: a combination of data, queries, and access patterns.
Your application (or whatever uses the database) executes a real workload, but a benchmark executes a workload that ranges from synthetic to realistic.

![Benchmark Fidelity Spectrum from Synthetic to Realistic](/img/benchmark_workload.svg)

Synthetic workload
: A synthetic workload uses schemas, data, and queries that are nothing like any real (or reasonable) workload.
Nevertheless, synthetic workloads are common and useful (some are even necessary) for reasons explained in the following sections.

Realistic workload
: A realistic workload tries to mimic the real workload as closely as possible.
The key word is "tries": there are always differences between real workloads and benchmark workloads.
But with effort, a benchmark workload can be made so realistic that the differences become negligible.

In my experience, most database benchmarks tend towards synthetic.
That's not surprising because useful results can be gleaned from synthetic workloads, and crafting realistic workloads is very difficult.

The difference matters most when doing an [application-specific benchmark](#application-specific) since, as the name implies, the intent is to benchmark a specific application.
If the workload isn't realistic with respect to the application, then the results will not tell you something about real application performance.

Otherwise, most types of database benchmarks can yield useful results with a synthetic workload, and the important factor to consider and control is benchmark complexity.

![Benchmark Complexity Spectrum from Trivial to Difficult](/img/benchmark_complexity.svg)

Trivial workload
: A trivial workload does not stress the database.
Trivial is less than easy.
("Easy" would be to the right of "Trivial" in the diagram.)
For example, `SELECT 1` is trivial because it's a virtual no-op (no table or data access).
Not stressing the database is useful for [system benchmarks](#system).
For example, to see if MySQL can stress the storage system, a trivial workload executes non-contentious writes just to generate a lot of data on disk.

Difficult workload
: A difficult workload stresses many parts of the database.
For example, a write-only workload is difficult for most relational databases.
This extreme is useful for [feature benchmarks](#feature) when you're trying to stress a particular part of the database.

Benchmark tools have options to vary the workload complexity.
For example, a read-only workload with 10 clients and a 1,000 QPS throttle is easy.
But increase to 10,000 clients without a throttle and the workload becomes much more difficult for the database.

Benchmarks and workloads are two sides of the same coin.
Given a particular type of benchmark, you need a reasonable workload for the benchmark results to be meaningful.
"Reasonable", instead of "right", means you can use any type of workload as long as you know why you're combining the two&mdash;and document it so future engineers will know why, too.
As the following six types of benchmarks will show, there are use cases for every type of workload.

## Types

<p class="note">
For each type of benchmark, the diagram shows the expected workload.
</p>

### Database

Does a database benchmark say something about the database, or the workload?
The former is the default, and usually implicit, presumption: if you just "benchmark MySQL", the results say something about _MySQL_ (the database), not the workload.
It's not uncommon to hear or read about database benchmarks with no details about the workload.
But there is a meaningful difference in the distinction, which is why there are two sub-types of database benchmarks: general and application-specific.

#### General

![General database benchmark fidelity and complexity](/img/bench_db1.svg)

A _general database benchmark_ answers the question "What kind of performance is possible with this database?"
The expected workload is balanced in an attempt to be general.

Engineers want (and need) to know what kind of performance a database can deliver.
Putting aside the fact that performance is complex and multifaceted, it's fair to ask if it's possible for a database to achieve 500,000 reads/second?
Or 100,000 writes/second?
Or single-digit millisecond commit latency?
General database benchmarks answer these kinds of general, high-level questions.

Since the benchmark is general, the results are also general, which raises the question: can general results be [useful](#useful-results)?
In my experience, general results are usually not useful and, rather, they [raise more questions and issues]({{< ref "are-aurora-performance-claims-true" >}}) than they answer.
For example, Amazon Aurora advertises 100,000 UPDATE/s (or sometimes "writes/"), which sounds impressive, but that doesn't mean _you_ will see that kind of performance in your application.
At the very least, general database results give us some idea of what the database can do.
Amazon doesn't advertise 10,000 or 1 million UPDATE/s&mdash;the vague performance potential is around 100,000 UPDATE/s.

To make a general database benchmark more meaningful, you need to ask a more specific question, like: "Can the database achieve 500,000 reads/second with 100 GB of hot data, 16 cores, 64 GB of RAM, 2000 clients, and a P999 response time of 50 milliseconds with the following schema..."
But, not ironically, the more specific the question, the less general the benchmark, which leads us to the second sub-type of database benchmark: application-specific.

#### Application-specific

![Application-specific database benchmark fidelity and complexity](/img/bench_db2.svg)

An _application-specific database benchmark_ answers the question "What kind of performance is possible with my application on this database?"
The expected workload is as realistic as possible, and the more difficult the better (without overloading the database).

Application-specific benchmark results are the most useful because they mimic your real application workload.
Unfortunately, though, this type of benchmark is rare because it's not easy to recreate an application workload.
But that's why I created [Finch](https://github.com/square/finch): to make writing application-specific benchmarks as easy as possible.

The only caveat to application-specific benchmarks is that they're not useful to other people.
For example, Amazon wrote in the Aurora white paper, [“Amazon Aurora: Design considerations for high throughput cloud-native relational databases”](https://www.amazon.science/publications/amazon-aurora-design-considerations-for-high-throughput-cloud-native-relational-databases), that it has many customers with many databases and tables, and that's what Aurora excels at handling.
But that's application-specific, and it's the opposite of many small databases with only one database, as typically found in microservice environments.
That difference explains why, for example, you probably won't get 100,000 UPDATE/s (its performance claim) out of a single table.
(Actually, you can if you do it just right, but now we're talking about a third and different application-specific setup.)

### Comparison

![Comparison database benchmark fidelity and complexity](/img/bench_comparison.svg)

A _comparison benchmark_ answers the question "How does A compare to B?", or "Which is faster: A or B?"
The expected workload is general but difficult to make the comparison interesting.

Comparison benchmarks are like general database benchmarks but with a purpose: to compare databases.
As such, the workload should be more difficult, else the comparison might not yield any interesting differences.
For example, all databases (that I know of) can handle 100 writes/second&mdash;that's trivial&mdash;but what about 100,000 writes/second?
That why Amazon Aurora markets that result: it's nontrivial write throughput.
(But read my long blog post, [Are Aurora Performance Claims True?]({{< ref "are-aurora-performance-claims-true" >}}).)

Since comparison benchmark are the go-to for marketing, they're the most susceptible to [cheating](#cheats).
When reading about comparison benchmark results, be _extra_ skeptical and pay extra attention to the details.

Although typically used to prove "who's faster?", not all comparison benchmarks are competitive.
Some are positive in the sense of demonstrating progress, like the countless MySQL major version comparisons over the decades.
We like to know if (and expect that) 8.0 is faster than 5.7.

Comparison benchmarks might highlight particular results or differences, like [commit latency]({{< ref "commit-latency-aurora-vs-rds-mysql-8.0" >}}), but they're not meant to be feature-specific.
That would be a [feature benchmark](#feature), or possibly a regression benchmark in a specific part of the databases.

### Regression

![Regression database benchmark fidelity and complexity](/img/bench_regression.svg)

A _regression benchmark_ answers the question "Have changes made the database slower?"
The expected workload is somewhat realistic (so the results are meaningful) but easy (to automate and run the benchmark easily).

Regression benchmarks tend to be simpler and automated, and the results are only useful when they're worse (slower) than some baseline.
The results are only useful to you and, perhaps, only one application or codebase.
That's why you almost never seen benchmark results published: they're just an internal development detail.

### System

![System database benchmark fidelity and complexity](/img/bench_system.svg)

A _system benchmark_ answers the question "How well is the database utilizing the system?", or "How well is the system performing for the database?"
The expected workload is synthetic and trivial for the database because the focus is system.

Most database benchmarks focus on the database server and presume the system (hardware and OS/kernel) is either optimal or a nonissue.
That's a safe presumption for most systems, but database developers and experts need to reverse that: focus on the system and presume the database is either optimal or a nonissue.
For example, you upgrade the storage bus from SATA to NVMe: is the database utilizing the new storage system capacity?
Or, you change the memory allocator library used by the databases: does this affect memory usage?
Or, you fiddle with NUMA settings: how does this affect database performance?

[Testing Intel® SSD 910](https://www.percona.com/blog/testing-intel-ssd-910/) by Vadim at Percona is a good example.

The database is complex, but the system is even more complex, which is why system benchmarks are typically done by database developers or experts.
There is also interaction between the two: if the database isn't fully utilizing the system, is the problem the database or the system?
That question can be exceedingly difficult to answer.

### Feature

![Feature database benchmark fidelity and complexity](/img/bench_feature.svg)

A _feature benchmark_ answers the question "How does this feature affect performance?"
The expected workload is completely synthetic (to isolate the feature) and very difficult (to stress the feature).

A feature benchmark is like a [comparison benchmark](#comparison) but with a singular focus: one feature of the database.
"Feature" is used in a broad sense.
It can mean an optional feature that the database doesn't need, or it can be a core subsystem that database cannot work without.
With MySQL, for example, the adaptive hash index (AHI) is an optional feature: turning it on or off doesn't matter.
But the InnoDB redo log is a core subsystem that MySQL cannot work without.
More examples of MySQL features are:

* Doublewrite buffer
* Binary logging
* Query cache
* Log file size
* LRU scan depth

And many more.
A feature benchmark examines the affects of such features on performance, and they're more difficult to create and run than they seem.
For example, it's often debated whether the AHI helps or hurts performance.
How do you benchmark this?
The first idea is to run benchmarks with AHI on and compare the results to the same benchmark with AHI off.
But how do you know if the workload made heavy use of the AHI or not?

Other features are even trickier to isolate and benchmark, like LRU scan depth: see [MySQL LRU Flushing and I/O Capacity]({{< ref "mysql-lru-flushing-io-capacity" >}}) to get a sense of the craziness involved.
Consequently, like system benchmarks, feature benchmarks are typically done by database developers or experts.

### Limit

![Limit database benchmark fidelity and complexity](/img/bench_limit.svg)

A _limit benchmark_ answers the question "Is it possible for the database to..."
The expected workload is synthetic and beyond difficult to test the limits.

Limit benchmarks are exceptionally rare because they're exceptionally difficult to produce.
Reaching a limit does not mean hammering the database until performance stops increasing (or decreases).
That's just overloading the database.
A limit benchmark is focused liked a feature benchmark; it's testing _a limit_, not "the limits".
[MySQL Challenge: 100k Connections](https://www.percona.com/blog/mysql-challenge-100k-connections/) is a good example: focused and way beyond the limit for most databases.
Another example would be provisioning maximum IOPS in the cloud and attempting to achieve that limit.
I've done that, but failed to reach the limit, only to be told by the company that the database can't utilize maximum provisioned IOPS.
(Why allow users to provision IOPS the database can't use?)

Limit benchmarks are special because the results are more about the limit than the database.
As such, the results tend to be useful only to database developers and researchers&mdash;not even DBAs.

## Cheats

Benchmarks can be crafted to yield almost any results.
This allows unscrupulous characters to cheat and make almost any performance claim.
But fortunately for the rest of us, computers are finite deterministic machines, so the cheats are nearly impossible to hide when you know what to look for:

* Using a trivial workload
* Over-provisioning the hardware
* Disabling durability (for ACID-complaint data stores)
* Not configuring the databases (using out of the box defaults)
* Using specialized hardware/OS not for sale (or _extremely_ expensive)
* Running the benchmark for a matter of seconds (or less than 5 minutes)
* Not providing all details of the benchmark: tool, workload, database configuration, etc.
* Enabling nonstandard caching (e.g. enabling query cache in MySQL 5.7 that is off by default)

There's another "pseudo-cheat" to guard against: hype, claiming revolutionary breakthroughs, advancements, sliver bullets, etc.
That's not a technical cheat like the others; it's more like a psychological cheat because people are inclined to believe what they want (despite evidence to the contrary), and we want amazing performance.
This is common in the database industry; there's always some vendor making grandiose claims.
The reality, however, is that databases improve slowly&mdash;on the order of years and decades.
And the reason is that _true_ durability at scale is very difficult, and a distributed database is even more difficult.

<p class="note warn">
Benchmarks can be made to report almost any results.<br>
Don't believe any results until you have verified all the details.
</p>

In the MySQL industry, I've seen a lot of hype come and go over the last 20 years.
What endures are companies and products that craft honest benchmarks (no cheats, no hype) and let the results speak for themselves.

## Challenges

Benchmarking is difficult and time-consuming.
It's scientific experimentation (laboratory work), and as any experimental scientist will tell you: controlling the variables and getting good, reproducible results is painstaking work.
If you're new to benchmarking, expect to invest significant time and effort&mdash;and make mistakes.
If you find the work difficult, then you're probably doing it right.

At a high level, the primary challenge of benchmarking is _providing answers_.
(It's no coincidence that each [benchmark type](#types) starts with "A ... benchmark answers the question...")
It's a field of work where others can say, "I don't know, you tell me."
For example, when I say "configure the database properly and reasonably", I don't know what that means; you tell me&mdash;it's your experiment, your benchmark.
But a starting point to the question is probably the type of benchmark and what you're trying to show or prove with it.

To get philosophical for a moment, with benchmarking you're attempting to establish  _truth_, justified true knowledge.
That is difficult because databases, computers, and performance are complicated; and any claims are easily undercut by poor methodology.
This isn't overly dramatic when you realize that businesses make decisions based on what they believe to be true, and those decisions influence "big money".
Why do you think Amazon Aurora repeats its 5X performance claim every where, every time it can?

Philosophy aside, the following is a non-complete list of technical challenges that make database benchmarking difficult.

Database configuration
: Did you properly and reasonably configure the database?
Did that configuration hold or revert after restart the database?
Did you set a session variable instead of a global variable?
The wrong configuration can ruin a benchmark, so you must ensure that the database is properly and reasonably configured every time, all the time.
(Humans are forgetful and databases are complex, so this is easier said than done.)

System configuration
: Make sure the whole system (hardware, OS, kernel) is properly and reasonably configured.
This is the same challenge as database configuration but more challenging because system configuration is vast and nuanced.
If you're unsure, at least document the makes, models, and versions of the system: CPUs, RAM, storage bus and devices, OS, kernel, and any relevant cloud resources (like instance class types and sizes).

Fake data
: If you can load real data (from a production database backup, for example), that's ideal.
But most likely you need to load tables with fake data, and that poses a challenge: generating fake data for indexed columns that produces reasonable cardinality and selectivity.
For example, don't fill an indexed column with the same value (cardinality = 1), or unique values if the index is nonunique (cardinality too high).
This is easier said than done because benchmark tools might not have ways to control fake data generation.
If nothing else, at least be aware of (and possibly document) how the benchmark tool generates data, and what the resulting index statics are like.

Data access
: When accessing data, use a reasonable data distribution.
[Sysbench and the Random Distribution Effect](https://www.percona.com/blog/sysbench-and-the-random-distribution-effect/) is a great example.
In the natural sciences, a Gaussian distribution is so common that it's called the normal distribution.
But a database is artificial, so it might not be a reasonable method of data access.
This challenge goes hand in hand with fake data generation and cardinality.
Ideally, the data and its access make sense _together_.
That doesn't happen automatically; it's something you have to consciously and carefully create.

Noisy neighbors
: Ensure the server isn't busy doing other work that makes your benchmark artificially slow.
(Or, make sure you didn't forget to stop previous benchmarks! It happens to all of us.)
Ideally, you benchmark on dedicated bare metal, but that's increasingly rare and expensive.
In the cloud, shared tenancy is the norm, so you never know if your benchmark is running on an idle server, or a busy server.
(After all, you're doing the same to others: running benchmarks makes _you_ the noisy neighbor.)

Power and temperature
: Make sure the hardware isn't adjusting CPU frequency for power saving or thermal regulation.
In case you didn't know: modern CPUs tend _not_ to run at full speed; they vary to save power and reduce heat.
This even true for enterprise-grade rack servers because data center power and temperature control are critical.
(I used to work in a data center.)
If you're running your own bare metal hardware, check the BIOS settings (or, many systems can report and control this through the OS).

Runtime
: Run the benchmark for long enough to account for warm up, filling (and recycling) logs, resource credits and burst limits, and so forth.
These things explain why performance over 10 minutes can be quite different than performance over 1 hour or 1 day.
It's generally not necessary to run a benchmark for more than a matter of hours unless your focus is less about the database and more about fluctuations in the environment where the database is running.

Credits and burst limits
: In the cloud, CPU and I/O usage can have credits and burst limits.
The tricky part is how they're consumed or replenished over time.
Avoid short runs that don't exhaust credits or exceed burst limits.
Some people can run fast for 10 minutes, but nobody can sustain that pace for 1 day.
The same is often true for databases.

Errors
: Benchmarks shouldn't spew errors, and they certainly shouldn't ignore them.
A tiny number of errors probably doesn't matter, but any noticeable amount casts down on the workload because errors can artificially increase or decrease query response time.
For example, if an error occurs immediately but is ignored, it can look like the query was very fast, which isn't true because it didn't really execute.
As always there are exceptions, like when you're intentionally causing or injecting errors to measure the affects on performance.

Another special type of challenge is what I call "apples to apples with oranges and bananas".
This refers specifically to [comparison benchmarks](#comparison) between two different products.
The different products are the oranges and bananas, but the benchmark is supposed to be a fair "apples to apples" comparison.
But how do you do that with different products?
The simple, unscientific answer: you do the best you can and document the important differences.
For example, if one product has a built-in cache that's core to its design, but the other product does not, that's a significant difference.
Or, if one product uses clustered indexes (MySQL) and the other uses heap tables (PostgreSQL), that's a significant difference.

## Reporting

A good benchmark needs great reporting.
But reporting benchmark results is a fair amount of work, too.
So again: if you're new to benchmarking, expect to invest significant time and effort&mdash;and make mistakes.

I won't belabor this topic with paragraphs.
It's sufficient to list the main points because they're not difficult, they just need to be made clear and applied.

***Report***

* Provide a summary of all key results.
Not everyone will read or study your benchmark report, especially when it's long and detailed.
[MySQL Performance : Understanding InnoDB IO Internals & "Checkpointing"](http://dimitrik.free.fr/blog/posts/mysql-80-innodb-checkpointing.html) is an example: long, detailed, summary provided.
It also helps to keep in mind that "a picture is worth a thousand words": a single graph/chart can take a long time to "read" and understand.
* Explain charts that aren't completely obvious; explain what the chart is "saying".
* Provide the database configuration, or enough details about key configuration settings/changes.
* If possible, provide the raw data on GitHub (or somewhere public and stable) in CSV or some very common format; don't use custom or binary formats.
* Provide enough information and detail for other engineers (especially _future_ engineers many years later) to accurately reproduce the benchmark.
Reproducibility is the goal for both you and other engineers: a truly great, high-quality, professional benchmark can reproduce the same results for different engineers at different times.

***Stats***

Sometimes it's sufficient to provide only charts/graphs, but if you need to provide numbers, include these statistics:

* Meta:
  * Runtime (seconds)
  * Interval number (if periodic stats)
  * MySQL clients/connections (count)
  * Errors (rate or count)
* For all queries, reads, writes, and commit:
  * QPS (all, read, write) / TPS (COMMIT)
  * minimum
  * P95, P99, or P999 (or user configurable)
  * maximum

There might be more (like event count or events/s), but are the minimum.

Don't mix units: use microseconds or milliseconds.

Average, mean, and median are not included because they're not useful.
Although average, in particular, is commonly reported, it's not useful because no one experiences the average.
Percentiles are better; P95 at minimum.
If possible, a histogram is even better because it visualizes the whole distribution of response time.

***Graphs***

* Keep graphs simple, focused.
* Use multiple graphs; don't overcrowd a graph.
* Make graphs big enough to read easily; link to full-size image.
* Use same graph size if possible (so X axes line up).
* Label axes, series, and units.
* Start Y-axis at zero.

---

I'll say it a third and final time: if you're new to benchmarking, expect to invest significant time and effort&mdash;and make mistakes.
But it's worth the time and effort because a good benchmark and its results are like a mystery told and revealed, and people love a good mystery.
For inspiration, browse the [vault of Percona benchmarks](https://www.percona.com/blog/category/benchmarks/).
