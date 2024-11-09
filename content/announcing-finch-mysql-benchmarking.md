---
date: "2023-08-01T13:41:00-04:00"
title: "Announcing Finch: A New MySQL Benchmarking Tool"
tags: ["mysql", "benchmarks", "finch"]
aliases:
  - /post/announcing-finch-mysql-benchmarking/
---

I'm happy to announce [Finch](https://github.com/square/finch): a new MySQL benchmarking tool for experts, developers, and modern infrastructure.
TL;DR: https://square.github.io/finch/

<!--more-->

Yes of course I know about [sysbench](https://github.com/akopytov/sysbench)&mdash;who doesn't?
But awhile ago I needed a benchmarking tool to do things that sysbench cannot do (or do easily).
Here are the four things that I couldn't do with sysbench but [Finch](https://github.com/square/finch) makes easy.

## 1. Stats to CSV

I need stats written to a CSV file so I can produce charts like the ones in [COMMIT Latency: Aurora vs. RDS MySQL 8.0]({{< ref "commit-latency-aurora-vs-rds-mysql-8.0" >}}).
You can make sysbench do this, but good luck figuring out how.
With Finch, it's a built-in first-class feature: [Statistics / CSV](https://square.github.io/finch/benchmark/statistics/#csv).

Moreover, Finch statistics reporting is a plugin interface, so you can implement your own stats reporter to send, dump, or output the values anywhere you want&mdash;without modifying any core code, just implement one Go interface.

## 2. Multi-node Benchmarking

How many Kubernetes nodes does your app run on?
Probably more than one.
And if you're running in the cloud, they might even be in different availability zones (data centers).

Likewise, I need to run a benchmarking tool on many compute nodes to accurately simulate how the app blasts MySQL.
You can do this with sysbench, but there are two problems.
First, you'll need to manually set up each instance with the same command line options (not too difficult).
Second, you'll need to manually combine the stats from each instance (very difficult).

By contrast, Finch can run in client/server (leader/follower) mode, basically forming a benchmarking bot network.
Even better: the clients (followers) don't need any configuration: they download all the benchmarking details from the server (leader).
It looks like this:

![Finch distributed compute](/img/finch_compute.svg)

Since compute instances are plentiful and cheap in the cloud, Finch allows me to easily generate massive load on a MySQL server.
And Finch automatically aggregates the distributed stats, including properly implemented distributed histograms (for accurately estimating percentiles).

## 3. Your Workload

Do you really know what sysbench executes?
Its schema and queries?
Its workload?

Maybe this was common knowledge 20 years ago, but most MySQL experts I ask today do not know off hand.
They have a general idea, which is fine sometimes, but given how important benchmarks are, you'd think MySQL experts would know every detail.

Does it matter?
Yes, a lot.
Sometimes companies [make big claims]({{< ref "are-aurora-performance-claims-true" >}}) based on the sysbench workload.
If you don't know what the workload is, how can know if the claims are true?

The sysbench workload is good enough, even if you don't know what it is, but I needed better.
I needed a more realistic and more complex workload on much larger data: several million of rows over three tables, not the tens or hundreds of thousands of rows people tend to create in one sysbench table.
Finch ships with this workload: [xfer](https://square.github.io/finch/benchmark/examples/#xfer).
But the important point is: with Finch, you can easily create _your_ workload.

## 4. Data Access Distribution 

In addition to not knowing the sysbench workload, I don't think most MySQL experts know how sysbench accesses data.
(I hope I'm wrong about that, though.)
Most people correctly guess that access is random, but there are different types (or distributions) of random access.

Sysbench has [random number options](https://github.com/akopytov/sysbench#random-numbers-options), but what does `--rand-type special` mean?
Thankfully, Marco Tusa explained in [Sysbench and the Random Distribution Effect
](https://www.percona.com/blog/sysbench-and-the-random-distribution-effect/).
But did you know [the default for `--rand-type` changed](https://github.com/akopytov/sysbench/issues/329)?

Figuring out a reasonable distribution for random data access is difficult.
But it's important because it affects MySQL performance.
Moreover, random access isn't always needed; sometimes sequential access is useful.
Finch documents the data access distribution for its [built-in data generators](https://square.github.io/finch/data/generators/).
And if those don't work for you, data generators are a plugin so it's easy to generate whatever kind of data access you need.

## Write SQL

In addition to the four reasons above, I wrote Finch for another reason: I wanted to write benchmarks in SQL&mdash;real and direct SQL.

For example, here's part of the _sysbench_ read-only benchmark:

```lua
function event()
   if not sysbench.opt.skip_trx then
      begin()
   end

   execute_point_selects()

   if sysbench.opt.range_selects then
      execute_simple_ranges()
      execute_sum_ranges()
      execute_order_ranges()
      execute_distinct_ranges()
   end

   if not sysbench.opt.skip_trx then
      commit()
   end

   check_reconnect()
end
```

Let's follow `execute_point_selects()`, which is defined in another another file:

```lua
function execute_point_selects()
   local tnum = get_table_num()
   local i

   for i = 1, sysbench.opt.point_selects do
      param[tnum].point_selects[1]:set(get_id())

      stmt[tnum].point_selects:execute()
   end
end
```

The rabbit hole goes deep before you find and figure out the SQL that the benchmark executes.

In my opinion, it's very difficult to write custom benchmarks with sysbench.
It's not enough to learn Lua; you must also learn sysbench internals and APIs.
Crafting good benchmarks is already difficult, and programming at the intersection of sysbench, Lua, and the SQL you want to execute as a benchmark is a nonstarter for most people&mdash;myself included.

Matthew Boehm wrote [Creating Custom Sysbench Scripts](https://www.percona.com/blog/creating-custom-sysbench-scripts/), and Amol Deshmukh wrote [Running Custom Workloads with Sysbench](https://medium.com/@amol.deshmukh_97340/running-custom-workloads-with-sysbench-c6d5338a503b), but that's about all you'll find on the topic.

Here's exact same sysbench read-only benchmark in Finch:

```sql
BEGIN

-- prepare
-- copies: 10
SELECT c FROM sbtest1 WHERE id=@id

-- prepare
SELECT c FROM sbtest1 WHERE id BETWEEN @id_100 AND @PREV

-- prepare
SELECT SUM(k) FROM sbtest1 WHERE id BETWEEN @id_100 AND @PREV

-- prepare
SELECT c FROM sbtest1 WHERE id BETWEEN @id_100 AND @PREV ORDER BY c

-- prepare
SELECT DISTINCT c FROM sbtest1 WHERE id BETWEEN @id_100 AND @PREV ORDER BY c

COMMIT
```

Or course, we trading one tool- and domain-specific set of information for another.
With sysbench, you have its command line options and Lua APIs.
With Finch you have its [statement modifiers](https://square.github.io/finch/syntax/trx-file/#statement-modifiers) like `--prepare` and [data keys](https://square.github.io/finch/data/keys/) like `@id`.
But with Finch you write benchmarks in real SQL as shown above.
Then you configure Finch (in YAML files) to tell it how to execute those SQL statements.
And it's all extensively documented: https://square.github.io/finch/

## Benchmarking for Developers

Benchmarking is difficult, even for experts.
But ideally it's something software developers can do and actually do.
To help make that reality is another reason why I wrote Finch&mdash;and the page [Benchmarking]({{< ref "eng/benchmarking" >}}).

I've already seen it in action once: where I work, a team of software engineers used Finch to recreate the critical part of their app's workload.
They benchmarked one database environment versus another and found the other had latency the app couldn't handle.
Their benchmark results allowed the team to avoid problems, which means our customers didn't experience problems.

## The Future of MySQL Benchmarking

Did you see [_Introducing MySQL Innovation and Long-Term Support (LTS) versions_](https://blogs.oracle.com/mysql/post/introducing-mysql-innovation-and-longterm-support-lts-versions)&nbsp;?
MySQL 8.0.34 will be the first LTS release (until 8.0 EOL scheduled for April 2026).
This is great news, and I hope it will usher in another 20-year era of MySQL productivity.

I hope that [Finch](https://github.com/square/finch) helps MySQL benchmarking become more mainstream and frequent.
With MySQL Innovation and LTS releases, and various MySQL-related cloud products, there are more reasons than ever to benchmark.
