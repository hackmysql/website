---
date: "2020-11-01T20:25:00-05:00"
title: "Query Metrics Requirements for MySQL"
tags: ["mysql", "query-metrics"]
comments: true
aliases:
  - /post/query-metrics-requirements-for-mysql/
disqus_url: "https://hackmysql.com/post/query-metrics-requirements-for-mysql/"
---

Let's answer a question which, to my knowledge, has never been systematically addressed: _What are the requirements for a production-ready query metrics app at scale?_ I am uniquely qualified to answer that because I have written four query metrics apps, two of which are the open-source standard for MySQL: [pt-query-digest](https://www.percona.com/doc/percona-toolkit/LATEST/pt-query-digest.html) and the original (v1) code behind the query metrics/analysis part of [Percona Monitoring and Management](https://www.percona.com/software/database-tools/percona-monitoring-and-management). I've also published a couple of packages related to query metrics: [go-mysql/slowlog](https://github.com/go-mysql/slowlog) and [go-mysql/query](https://github.com/go-mysql/query).

## Query Metrics vs. System Metrics

Let's make sure we're talking about the same thing. System metrics come from `SHOW GLOBAL STATUS` (usually, but tools should really use the Performance Schema) and include metrics like [Threads_running](https://dev.mysql.com/doc/refman/8.0/en/server-status-variables.html#statvar_Threads_running). These and other metrics are system metrics, and there are _a lot_ of apps (open-source, proprietary, hosted/SaaS, etc.) for collecting and charting them. There are so many solutions in this space for two reasons: they're easy and common. They're easy to collect, aggregate, and report because they're just gauges and counters. They're common for the same reason: just gauges and counters which any system should provide and every engineer expects.

Query metrics ("QM") are the statistics of MySQL query metrics aggregated by a dimension, almost always by [statement digest](https://dev.mysql.com/doc/refman/8.0/en/performance-schema-statement-digests.html) (a.k.a. "fingerprint"). Raw, non-aggregated query metrics are collected from the [slow query log](https://dev.mysql.com/doc/refman/8.0/en/slow-query-log.html) or [Performance Schema](https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html) (or, rarely, from the network by sniffing the MySQL protocol). There are _very few_ apps for collecting and visualizing QM because it's quite difficult and very data-intensive. I won't go into technical details, but it's fair to say that an engineer can whip up a solution for system metrics in a few days, but a QM app requires 6 engineering months at least. That's how long it took me and another engineer (3 calendar months == 6 engineering months) to create a QM app for Square with all the _Must Have_ requirements below, and that's with me having had 10+ years experience with query metrics and using some open-source packages I had already written. I'd advise a company to plan for 3 exceptional engineers and 2 calendar years to create a production-ready QM app at scale from the ground up.

### Why Query Metrics?

Query metrics tell you what MySQL is doing (or, _has done_, since they're not real-time). Moreover, QM tells you what MySQL is _busy doing_. When system metrics tell you that MySQL is running many threads and QPS is very low, the first question is: _Why?_ Only QM can answer that. Query metrics are almost always required to troubleshoot and fix MySQL performance problems. It's only logical: MySQL does little more than execute queries, so knowing which queries take the most time, examine the most rows, etc. answers many questions. There are cases when one needs only system metrics, but I've never seen or heard of any company successfully running MySQL without query metrics.

## Retail Solutions

QM apps are difficult to create, which is why there are only two&mdash;yes, _2_&mdash;retail (i.e. not private) solutions that I know of: [Percona Monitoring and Management](https://www.percona.com/software/database-tools/percona-monitoring-and-management) and [SolarWinds Database Performance Monitor](https://www.solarwinds.com/database-performance-monitor) (formerly VividCortex). 

A big name in the metrics/APM industry is developing a third solution, but I don't know if that's public knowledge yet, so I'll refrain from saying which company. Point is: another solution is forthcoming.

Amazon RDS for MySQL has [Performance Insights](https://aws.amazon.com/rds/performance-insights/), but I've only looked at it enough to know that it's not standard QM based on query time (which queries MySQL spends time executing); rather, it seems based on wait time (where MySQL spends time waiting). There is merit to this approach (analysis by wait time), but it's not common MySQL practice. I don't think it would make immediate sense to MySQL experts. However, as previously said: it has merit, and some day I'd like to give it a more thorough examination.

MySQL Workbench has [Performance Schema Reports](https://dev.mysql.com/doc/workbench/en/wb-performance-reports.html) which are kind of query metrics. But Workbench is a standalone app, so I don't count it as a solution at scale, same as pt-query-digest.

## Requirements

I want more companies to create retail QM apps because it's important that the state of the art keeps evolving and improving. Competition helps do that, as well as lower prices. Granted, [Percona Monitoring and Management](https://www.percona.com/software/database-tools/percona-monitoring-and-management) is free but maybe not an ideal solution in a big enterprise which has money to buy a product and let the vendor handle everything.

Following are requirements for a query metrics app to be, in my opinion, production-ready at scale:

### Must Have

A query metrics app must have these features to be useful for production MySQL at scale:

* Aggregate by Query Digest

Query metrics mean nothing unless queries are abstracted and grouped by [digest](https://dev.mysql.com/doc/refman/8.0/en/performance-schema-statement-digests.html) and shown as such in the app. Real query samples `SELET * FROM t WHERE id = 1` and `SELET * FROM t WHERE id = 5` are the same logical query: `SELET * FROM t WHERE id = ?`. This latter form is the query digest (a.k.a. "fingerprint"). The app must be built around this concept but not necessarily hard-coded to query digests.

* Disable Samples

The app must report query digests, but reporting real query samples must be opt-in. Samples are not required to troubleshoot issues, but they are very nice to have. However, security often prevents them from being transmitted or stored, so the app must _not_ do so by default and only do so when explicitly enabled.

* Minimum Resolution: 60s

The app must consume, aggregate, and report query metrics at intervals no grater than 60s. Like system metrics, the higher the resolution, the more detail captured and seen which is necessary for troubleshooting short-lived issues. A maximum resolution of 1s is quite difficult to achieve because query metrics require a lot more processing and data than system metrics. If MySQL is doing 2,000 QPS, the challenge is: can the code digest 2,000 queries _and_ process the query metrics in less than 1s? That's very difficult.

* Minimum Retention: 2w (Full Resolution)

Query metrics must be retained, at full resolution, for at least 2 weeks. The reason is: if an issues happens today, there might not be a full incident review until next week, or the deep-dive analysis might take awhile. Longer retention is better, but 2 weeks is the minimum. After 2 weeks, the app can downsample to save space.

* Source: Slow Log or Performance Schema

The app must consume the slow query log or the relevant Performance Schema tables. If using slow log, it must support the Percona Server slow log extensions (extra query metrics). If using Performance Schema, it must do so correctly and efficiently, which is not trivial.

Sniffing the wire to get query metrics from the MySQL protocol is not sufficient because it contains almost no metrics. The MySQL protocol was never intended for this purpose, which makes it ill-suited. It's useful, however, for augmenting slow log or Performance Schema query metrics.

* Time Frame (UTC and Local)

The app, like any normal metrics system, must allow the user to select a time frame, both relative and absolute. It's common to look at QM for the last 30 minutes, or to look at QM for a specific time frame further in the past. Additionally, the app time zone must have at least UTC and local time. UTC is used when coordinating with other engineers or servers. Local time is used when one is looking at QM alone.

* Database Grouping

There are two issues the app must address. First, "the" database is most likely at least 2 MySQL instances, probably more. Although we need to see per-instance query metrics, we also usually consider "the" database to be a cluster of database instances connected in the same replication topology. Second, different teams have different databases, and we probably do not need (or want) to see databases that we don't own. Broadly speaking, there are two ways to address both issues: accounts or metadata.

If the app is partitioned by account (or sub-accounts), then I could use an account that contains only my databases. That solves the second issue, but it might not suffice for the first issue. (This approach is also nice for cost attribution/billing.)

The app can allow (or require) adding metadata (dimensions, labels, tags, etc.) to the data from each database instance. For example, I label query metrics from my databases with `team=foo` and `cluster=db1`, and the app allows me to filter by these labels. This approach is more flexible because it allows others uses of the metadata, but to make it work nicely the app needs to remember my filters so I don't have to re-filter every time.

The end result should be: I see only my databases (not other teams' databases), and by "database" I mean either a single database instance or all database instances in the cluster. Note: although I want to see databases grouped by cluster, only per-instance query metrics are must-have.

* Profile and Report

For any given interval (i.e. time frame selected by the user), there will be hundred or thousands of unique query digests. A query profile is necessary to show the meaningful and actionable "signals" among all the "noise". A default query profile shows the top N "slowest" queries, where "slowest" means "most execution time in the interval", i.e. what MySQL spent most its time doing. The query profile must allow different metrics (not necessarily all metrics, because many are not be useful as the profile sort metric); for example, top N queries by rows examined. From the profile we must be able to select a query digest to see all its aggregated metrics in the interval&mdash;a query report.

A query report is where all the details and metrics for a given query (by digest) are shown. A query report must present all metrics available and at least the usual statistics: minimum, average, maximum. All values must be converted to sensible units: show "249 ms" not "0.249001", convert bytes to KB/MB/GB, etc. Query reports are very information-dense, so a beautifully designed UI is critical.

* Deep Linking

It is very common for engineers to share QM app links. The app must have "deep links" that load the _exact_ page as the original user was seeing. This includes everything above: profile, report, database grouping (any filters), time frame, etc.

* Simple Agent

The app will most likely have an "agent" of some sort: a binary to collect query metrics from the slow log or Performance Schema, pre-aggregate, and send to a back-end API for further processing which powers the front-end web app. This agent must be extremely simple to install and configure, and support all MySQL connection options (TLS, cleartext password for other auth methods, etc.). In short, the back-end setup must be super simple, fast, and easy to deploy with automation.

* Affordable

Affordability is relative, but look at the current retail solutions and strive to do better for less money. One way to get an advantage: figure out pricing that takes into account the fact that, almost always, only 1 database in a logical cluster is writable, so all the replicas report little to no query metrics. (This doesn't apply to a real cluster where all nodes are writable.) Query metrics require a lot of data processing and storage, so driving down costs will require extremely efficient programming and a system designed for massive scale from the start.

If the price is too high, people will find a way to make [Percona Monitoring and Management](https://www.percona.com/software/database-tools/percona-monitoring-and-management) work. And if Amazon RDS for MySQL ever makes a more standard QM app, that could be very price-competitive since they already have all the infrastructure to support it.

### Premium

A premium query metrics app would have these features to justify its cost. In order of importance:

1. EXPLAIN Plan

One of the first things engineers do is look at the MySQL EXPLAIN plan for the top queries in the profile. The app should do and shows this automatically. This does not require samples: the agent would EXPLAIN the query and transmit only the EXPLAIN plan, not the sample. There should be an EXPLAIN plan for each interval; or if possible, get the EXPLAIN plan on-demand.

2. Side-by-Side Comparison

A common task is comparing QM now to some time in the past because there's a problem now and we want to see what's different. Users can compare two intervals using two web browser tabs, but it's a lot nicer if the app has built-in support for showing two intervals side-by-side. This leads to _Advanced 1_.

3. Pretty-Print Digest SQL

A query report will contain the query digest, and it's really helpful if it's pretty-printed SQL. It helps engineers study complex queries, and it's pretty easy to do (there are libraries; it's a solved problem).

4. Search Queries

Generally, a QM app delivers value in the profile and reports, but sometimes users need to search for specific queries. Premium QM apps should have this feature, and it leads to the next feature...

5. Comment Metadata

Putting metadata in multi-line comments is a common practice, like:

```none
SELECT id FROM t WHERE id = 1 /* file:app.go line:300 traceId:abc123 */
```

A premium QM app should parse the three key:value pairs from the comment and make them available as searchable, filterable query metadata. This is extremely useful for developers to link queries back to code. It also leads to _Advanced 2_.

### Advanced

An advanced query metrics app would have these features to be genuinely advanced with respect to the current state of the art:

1. Workload Difference

It's quite common for engineers to look at query metrics only when there's a problem and the burning question is: "What has changed?" Presuming a change in MySQL workload (i.e. all queries MySQL is executing) is the culprit, an advanced QM app should do the heavy lifting and number crunching to compare two intervals and report the significant differences, making it easy for the engineer to see what has changed. Granted, a simple side-by-side comparison (_Premium 2_) usually makes this obvious, but there are subtle cases that don't appear by comparing profiles.

2. Profile by Comment Metadata

The profile needs a metric to sort by, and query execution time is the default. A few other native query metrics like rows examined, lock time, etc. are useful, but an advanced QM app should allow sorting by the user-defined metadata from _Premium 5_. This is really difficult, though, because there are only a few useful native query metrics but unlimited user-defined metadata. Regardless, with such an ability, engineers can do things like (from the example above), profile queries with `traceId = abc123` to see which is the most time-consuming. Presumably, all queries with `traceId = abc123` are related, and the user-defined metadata groups them whereas, otherwise, they would be unrelated queries that may or may not show up in a profile together.

3. Link to Code

Another common tasks is linking queries back to code. But this feature is almost impossible unless the QM app vendor is also doing general APM for the app and has access to the code.

4. Smart Sampling

Even though sampling needs to be disabled by default, sampling is really important, especially if done intelligently. The problem is: in rare cases, a query will change dramatically based on input. A classic example is an `IN()` list with 100 values vs. 10,000 values. The latter can cause MySQL to switch from a good execution plan to a full table scale. But this nuance won't surface unless the right samples are taken to reveal the execution plan change in _Premium 1_&mdash;and if the QM app is extremely advanced, _Advanced 1_ will detect and surface the change in execution plan, too.

5. Cluster Query Metrics

Normal MySQL is not a cluster database, but there are cluster variants like [Percona XtraDB Cluster](https://www.percona.com/software/mysql-database/percona-xtradb-cluster) and [MariaDB Galera Cluster](https://mariadb.com/kb/en/what-is-mariadb-galera-cluster/) and [MySQL 8 Group Replication](https://dev.mysql.com/doc/refman/8.0/en/group-replication.html). I guess this latter isn't a variant; MySQL 8 is moving towards native cluster support. That's why a premium QM app needs to support cluster-level query metrics: aggregate and report the query metrics from all database instances. This way we can get a profile representative of the cluster. For right now, this would be the exception, far from the norm. But MySQL is moving in this direction.

## What About Charts?

You may notice that charts are not a requirement. The retail solutions have charts, but I don't think they're a requirement. For example, spark lines and spark charts are not uncommon, but I don't think anyone ever saw&mdash;let alone solved&mdash;a problem by looking at them. They make screenshots look good, but the core value of query metrics (unlike system metrics) is the profile: pinpointing troublesome queries in a given interval. As such, we're less concerned with the query metrics of a particular query over time. That's usually only of interest when comparing intervals (_Premium 2_ and _Advanced 1_).
