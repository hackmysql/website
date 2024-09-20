---
date: "2022-01-16T15:40:00-05:00"
title: "Configuring MySQL Query Metrics"
subtitle: "Chapter 1"
tags: ["mysql", "book", "efficient-mysql-performance", "query-metrics", "performance-schema", "slow-query-log"]
comments: true
aliases:
  - /post/book-1/
disqus_url: "https://hackmysql.com/post/book-1/"
series: "Behind the Book"
---

Editors and technical reviewers suggested that I cover how to configure MySQL query metrics in chapter 1 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance), but I deferred because it was out of scope for the book, which focuses on engineers _using_ MySQL, not DBAs.
As such, there's only a note in chapter 1 that says: "Ask your DBA or read the MySQL manual."
But I'll cover the topic here because that's what this blog post series is for: behind the book.

<!--more-->

This blog post is the second of eleven: one for the preface and ten for each chapter of the book.
The full list is [tags/efficient-mysql-performance](/tags/efficient-mysql-performance/).

MySQL provides query metrics through two sources: [slow query log](https://dev.mysql.com/doc/refman/8.0/en/slow-query-log.html) and [Performance Schema](https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html).
Chapter 1 of the book details what you need to know about each, so I won't repeat myself here.
First, let's start with choosing a query metric tool because that determines the source.
Then we'll look at configuring each source.

<p class="warning">
<b>WARNING</b>: This post is <i>not</i> a copy-paste guide; it presumes that you have basic experience configuring and operating MySQL.
Except for restarting MySQL, configuring the slow query log and Performance Schema are generally safe, but consult with a MySQL expert if you are not sure.
</p>

<br>

## Choose a Query Metric Tool

Start by choosing a query metric tool because it determines the source (slow query log or Performance Schema) and configuration.
For example, if the tool doesn't support the Performance Schema, then you must configure and manage the slow query log.
All of these tools "get the job done", so choose the one that works best for you.

<p class="note">
<b>NOTE</b>: I do not endorse or favor any tool because everything depends on your particular environment, company, team, budget, and so forth&mdash;none of which I know.
</p>

Some context-specific terminology used in the tables below:

Client
: Program that collects query metrics from source and sends to server where it is aggregated and reported.

Command line
: Tool runs and prints reports on the command line. This implies that tool must be run manually for each report.

GUI
: Tool is a traditional Windows/Mac/Linux desktop GUI for reporting. Probably uses a client to collect query metrics.

Mixed
: Tool uses command line for operations and web for reporting.

PFS
: Abbreviation for [_Performance Schema_](https://dev.mysql.com/doc/refman/8.0/en/performance-schema.html), one of two sources.

Slow log
: Sort for [_slow query log_](https://dev.mysql.com/doc/refman/8.0/en/slow-query-log.html), one of two sources.

Web app
: Fully hosted web app for all reporting. Typically commercial (not free) and requires local client to send metrics to the hosted web app.

### pt-query-digest

|Open source|Interface|Client|Sources|
|-----------|---------|------|-------|
|Yes|Command line|No|Slow log|

[pt-query-digest](https://www.percona.com/doc/percona-toolkit/LATEST/pt-query-digest.html) is the industry-standard command-line query metric tool.
It's really simple: run `pt-query-digest LOG`, where `LOG` is the path to your slow query log, and it prints a query profile and report for each query in that profile.

If you have never used query metrics before, you might start here because it's so simple: [enable the slow query log](#configuring-the-slow-query-log), and run `pt-query-digest` occasionally to gain essential performance insight into your MySQL database.

&lt;history&gt;
Since I can ramble in blog posts (zero rambling in the book&mdash;it's efficient right down to every word), I'll tell you some boring MySQL industry history.
In the beginning, MySQL shipped with a Perl script called `mysqldumpslow`, and it was not very good, in my opinion, but better than nothing.
At roughly the same time (circa 2004), both Baron Schwartz and I created better Perl scripts.
Then he and I joined Percona and created pt-query-digest (code initially from his script, then largely rewritten by me).
And that's how the MySQL industry worked for many years: just running pt-query-digest.
Some companies automated the process by creating back end services to run pt-query-digest automatically.
But by and large, the industry standard was simply running pt-query-digest on the command line.
&lt;/history&gt;

Today, as of 2022, `pt-query-digest` is still a useful tool (and many MySQL experts still use it), but several new web-based query metric tools exist, which offer a better user experience, especially with respect to reporting because, as I note in the book, reporting is a challenge and an art form.

### Percona Monitoring and Management (PMM)

|Open source|Interface|Client|Sources|
|-----------|---------|------|-------|
|Yes|Mixed|Yes|Slow log, PFS|

[Percona Monitoring and Management (PMM)](https://www.percona.com/software/database-tools/percona-monitoring-and-management) is a comprehensive, open source solution for MySQL query metrics and server metrics.
On the back end, it has clients to collect query and server metrics and send them to servers for aggregation.
It uses [Grafana](https://grafana.com) for all reporting, including query metrics (which it calls _Query Analytics_ because that's what I called it when I helped create PMM v1.0 long ago).

PMM, like all Percona tools and products, are developed and used by their experts in the course of their work.
Meaning: they're great tools because they're professionally developed and supported, and they're usually the industry standard.

If you prefer (or need) to use open source solutions, evaluate PMM.
It's basically the only comprehensive, free, open source solution with web-based reporting.

(Technically, there is also [Anemometer](https://github.com/box/Anemometer), which automates pt-query-digest and provides a web UI for reporting, but I'm not sure Anemometer is actively developed or supported any longer.)

&lt;history&gt;
What does "usually the industry standard" mean?
MySQL has a long an interesting history around the fact that MySQL AB (the original company) was bought by Sun Microsystems, and Sun Microsystems was bought by Oracle.
Big changes in ownership tend to create big changes in development plans, priorities, etc.
At the same time, MySQL had its "going viral" years from about 2000 to 2015, and those were the years of internet history during which many of the big tech companies we know/love/hate today also "went viral".
Consequently, you had MySQL doing one thing and powerful market forces asking/needing it to do another thing.
Enter Percona.
Percona, along with some major tech companies, often filled the gaps in MySQL the product that MySQL the company (whether MySQL, Sun, or Oracle) had yet to fill.
For many years, Percona Server (the Percona distribution of MySQL Community Edition) was ahead of MySQL Community Edition.
But today, MySQL 8.0 is often ahead because MySQL is much more stable, those market forces have moved on to other tech, and so forth.
We also have MariaDB Server that took (and continues to take) MySQL in another direction.
&lt;/history&gt;

### SolarWinds Database Performance Monitor

|Open source|Interface|Client|Sources|
|-----------|---------|------|-------|
|No|Web app|Yes|network capture, PFS|

[SolarWinds Database Performance Monitor](https://www.solarwinds.com/database-performance-monitor) was originally VividCortex: a company started by Baron Schwartz to develop an insanely good query metrics tool as a fully-hosted, commercial web app.
That tells you how imperative query metrics are to MySQL performance: Baron started a company initially focused solely on MySQL query metrics.
The company was successful, which is why SolarWinds bought it (and renamed it).

Since I always knew this product as "VC" (short for "VividCortex"), I'll call it that in this blog post.

The most interesting aspect of VC is that it uses network capture when running locally (on the same physical server as MySQL) to measure query response time.
In other words, the VC agent sniffs the local network for traffic on port 3306.
The technical reasons why are beyond the scope this post, but sufficient to say: it works for measuring query response time.
When running remotely&mdash;MySQL in the cloud, for example&mdash;it uses the Performance Schema.

To me, one of the most impressive things about VC is ironically not the query metrics but the initial setup (of the client).
I worked with Baron for many years, so I know: he really values and strives for an amazing setup experience&mdash;the smarter and more automated, the better.
I'm rarely impressed by setup procedures, but the VC setup is truly impressive&mdash;you'll see why if you try it.

VC has a free 14-day trial, so try it if you're shopping for commercial solutions.
Last time I used it (2020), it was still the exceptional product that Baron created, but time will tell if SolarWinds keeps it that way.

### Datadog Database Monitoring

|Open source|Interface|Client|Sources|
|-----------|---------|------|-------|
|No (client: yes)|Web app|Yes|PFS|

[Datadog Database Monitoring](https://www.datadoghq.com/product/database-monitoring/) is a relatively new web-based commercial query metric tool.
It shipped in 2021, but I used and evaluated it in 2020 while in development.
Even in 2020 development, it was a solid query metric tool that has the added bonus of (eventually) hooking into everything else Datadog offers.
For example, if you already use Datadog for application performance monitoring (APM), then adding Datadog Database Monitoring gets you the complete picture&mdash;from app to MySQL and back&mdash;in the same web app.

The initial setup of the Datadog client is really good.
In my opinion, it's not as good as the VC setup, but nothing is (so far) in this particular respect.
But the Datadog setup is really good, which is still high praise because, as you'll see in the second half of this blog post, configuring MySQL query metrics is not trivial.

Datadog also has a free trial, so try it if you're in the market for commercial solutions.

### MySQL Workbench

|Open source|Interface|Client|Sources|
|-----------|---------|------|-------|
|No|GUI|?|?|

[MySQL Workbench](https://www.mysql.com/products/workbench/) is:

> a unified visual tool for database architects, developers, and DBAs. 

This is the point in the blog post where you get to teach me because I have never used MySQL Workbench, which is why the table above contains two "?": I don't know how it works.
I only know that it has some kind of query metrics reporting.

I also know that some people and companies use MySQL Workbench or other Oracle products, so I include this product for completeness even though I can't tell you about its technical specifications.
But I'm sure Oracle will be happy to tell you all about it.

### AWS Performance Insights

|Open source|Interface|Client|Sources|
|-----------|---------|------|-------|
|No|Web app|No|PFS|

[AWS Performance Insights (PI)](https://aws.amazon.com/rds/performance-insights/) is a slightly different type of query metric tool.
The industry standard&mdash;as I write extensively throughout [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance)&mdash;is to focus on query _response_ time.
Why?
Because that's what MySQL is _doing_, and we most often need to know that so we can make it "do faster", which means execute queries faster.
But PI seems to focus on query _wait_ time: how long (and for which operations) MySQL was idle&mdash;basically doing nothing.
(Is waiting doing nothing? "Waiting" it something, but the act of waiting implies doing nothing.)

I say that it "seems to focus" because it does also report something like a more traditional query profile, which shows the top slowest queries.
And just a couple of weeks ago, my team used it to find and fix a slow query.
(We have a standard set of tools, including query metrics, but we also keep trying [and retrying] new tools because tools change over time and we like to stay relevant and current.)

But honestly: every time I use PI, I'm not figuratively sold on the product or experience.
It's acceptable, especially in lieu of having no other solution, but I would not buy it.
Fortunately, if you're already using AWS RDS, then PI is free for 7 days of data, which is probably sufficient (14 days is better for production, but 7 days free is a good offering).

My book still applies (performance is query _response_ time), but you'll have to translate most of chapter 1 to fit with PI.
Try PI if you're running AWS RDS, and remember: its reporting is unique, so read the docs and blog posts that AWS publishes.

### APM

|Open source|Interface|Client|Sources|
|-----------|---------|------|-------|
|Depends|Web app|No|Application|

Application performance monitoring (APM) products (like Datadog and New Relic) can measure query response time _in the application_.
I emphasis those last three words because, technically, this is different than query response time measured in MySQL.
For one thing, MySQL will almost certainly report faster query times because it does not measure network latency to and from itself (MySQL), whereas query time measured in the application includes network latency&mdash;and another other latency intrinsic to the application.
For another thing, MySQL can measure and report a lot more query metrics, whereas APM products simply do not have access to these additional metrics&mdash;they can really only measure query response time.

A true query metric tool is ideal, but if you already have APM that can measure query response time, it's a good start.

---

## Configure Performance Schema for Query Metrics

Let's start with the setup of the Performance Schema (PFS) because it's the most standard and consistent, which is why I recommend it in [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance).

Good news: the default PFS configuration is usually sufficient for query metrics.
You might not need to configure anything, but it depends on your query metric tool:

* Percona Monitoring and Management: [PMM v2.x Client Setup > Performance Schema](https://www.percona.com/doc/percona-monitoring-and-management/2.x/setting-up/client/mysql.html#performance-schema)
* SolarWinds Database Performance Monitor: [Enabling PERFORMANCE_SCHEMA on MySQL](https://docs.vividcortex.com/getting-started/off-host-installation/#enabling-performance-schema-on-mysql)
* Datadog Database Monitoring: [Configure MySQL settings](https://docs.datadoghq.com/database_monitoring/setup_mysql/selfhosted/?tab=mysql57#configure-mysql-settings)
* AWS Performance Insights: [Enabling the Performance Schema for Performance Insights on Amazon RDS for MariaDB or MySQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.EnableMySQL.html)

If you want the TL;DR, then read and apply the configuration as documented by those tools.
If you want the longer and more generic explanation, then read the rest of this section.

<p class="note">
<b>NOTE</b>: The Performance Schema is vast and complex, so I'm only going to address what's necessary and relevant to query metrics&mdash;I'm not going to explain instruments, consumers, and the myriad details of the PFS.
</p>

At a minimum, query metrics from the Performance Schema require three consumers that are enabled by default:

```sql
mysql> SELECT * FROM performance_schema.setup_consumers ORDER BY name;
+----------------------------------+---------+
| NAME                             | ENABLED |
+----------------------------------+---------+
| events_stages_current            | NO      |
| events_stages_history            | NO      |
| events_stages_history_long       | NO      |
| events_statements_current        | YES     | -- 1. query metrics
| events_statements_history        | YES     | -- 2. query metrics
| events_statements_history_long   | NO      | -- 3. query metrics
| events_transactions_current      | YES     |
| events_transactions_history      | YES     |
| events_transactions_history_long | NO      |
| events_waits_current             | NO      |
| events_waits_history             | NO      |
| events_waits_history_long        | NO      |
| global_instrumentation           | YES     |
| statements_digest                | YES     | -- 4. query metrics
| thread_instrumentation           | YES     |
+----------------------------------+---------+
```

The list above is all consumers, but I annotated the four consumers related to query metrics.
Notice that only consumer 3, `events_statements_history_long`, is _disabled_ by default.
Without going into a full explanation of what this consumer does, the short version is: it provides real SQL statements (query samples).
But as you'll read in chapter 1 of the book, many query metric tools do not use query samples by default for security.

For tools that require `events_statements_history_long`, you enable it in the `my.cnf`:

```ini
[mysqld]
performance_schema_consumer_events_statements_history_long=ON # query metrics
```

Set `performance_schema_consumer_events_statements_history_long=ON` in `my.cnf` under the `[mysqld]` section as shown.
That enables the consumer when MySQL starts, but the variable is dynamic so you can enable it the first time without restarting MySQL:

```sql
UPDATE performance_schema.setup_consumers SET enabled='YES' WHERE name='events_statements_history_long';
```

Then execute `SELECT * FROM performance_schema.setup_consumers ORDER BY name` to check that all query metric-related consumers are enabled.

In other guides about enabling PFS for query metrics, you might see a configuration like:

```ini
[mysqld]
performance_schema
performance_schema_consumer_statements_digest=ON
performance_schema_consumer_events_statements_history_long=ON
```

Usually, these guides are being explicit: having you explicitly enable PFS consumers (and other parts) even though many are enabled by default.
This is not a bad practice (because MySQL defaults might change), just be aware that there are many different ways to express the same configuration.

<p class="warning"><b>EXCEPTION</b>: Amazon RDS for MySQL disables the Performance Schema by default.
This is contrary to the industry standard, and it's odd given that their own product, Performance Insights, requires the PFS.<br><br>
To enable PFS on Amazon RDS for MySQL, set <code>performance_schema = 1</code> and (if needed) <code>performance_schema_consumer_events_statements_history_long = 1</code> in the parameter group.
Apply the parameter group changes, which requires restarting MySQL.
</p>

To check that PFS query metrics are working, run:

```sql
mysql> SELECT * FROM performance_schema.events_statements_summary_by_digest LIMIT 1\G
*************************** 1. row ***************************
                SCHEMA_NAME: NULL
                     DIGEST: 80c944deffba0a309d8246bc7f71a69dfaf62386ef0409a63d4fe1fb66a4d0b7
                DIGEST_TEXT: SELECT * FROM `performance_schema` . `setup_consumers` ORDER BY NAME
                 COUNT_STAR: 3
             SUM_TIMER_WAIT: 6475000000
             MIN_TIMER_WAIT: 168000000
             AVG_TIMER_WAIT: 2158333000
             MAX_TIMER_WAIT: 6016000000
              SUM_LOCK_TIME: 3629000000
                 SUM_ERRORS: 0
               SUM_WARNINGS: 0
          SUM_ROWS_AFFECTED: 0
              SUM_ROWS_SENT: 45
          SUM_ROWS_EXAMINED: 90
SUM_CREATED_TMP_DISK_TABLES: 0
     SUM_CREATED_TMP_TABLES: 0
       SUM_SELECT_FULL_JOIN: 0
 SUM_SELECT_FULL_RANGE_JOIN: 0
           SUM_SELECT_RANGE: 0
     SUM_SELECT_RANGE_CHECK: 0
            SUM_SELECT_SCAN: 3
      SUM_SORT_MERGE_PASSES: 0
             SUM_SORT_RANGE: 0
              SUM_SORT_ROWS: 45
              SUM_SORT_SCAN: 3
          SUM_NO_INDEX_USED: 3
     SUM_NO_GOOD_INDEX_USED: 0
                 FIRST_SEEN: 2022-01-15 16:17:53.349231
                  LAST_SEEN: 2022-01-15 16:51:57.777186
                QUANTILE_95: 6025595860
                QUANTILE_99: 6025595860
               QUANTILE_999: 6025595860
          QUERY_SAMPLE_TEXT: SELECT * FROM performance_schema.setup_consumers ORDER BY name
          QUERY_SAMPLE_SEEN: 2022-01-15 16:51:57.777186
    QUERY_SAMPLE_TIMER_WAIT: 291000000
```


Query metric tools primarily use table [events_statements_summary_by_digest](https://dev.mysql.com/doc/refman/8.0/en/performance-schema-statement-summary-tables.html) to generate query profiles and reports.
In the example above, you can spot the nine essential query metrics that chapter 1 explains in detail:

* `SUM_TIMER_WAIT` (query response time)
* `SUM_LOCK_TIME` (lock time _without_ row lock time)
* `SUM_ROWS_EXAMINED`
* `SUM_ROWS_SENT`
* `SUM_ROWS_AFFECTED`
* `SUM_SELECT_SCAN`
* `SUM_SELECT_FULL_JOIN`
* `SUM_CREATED_TMP_DISK_TABLES`
* `COUNT_STAR` (query count)

That covers basic configuration of PFS for query metrics, but you need one more thing: the MySQL user that the query metric tool uses needs a grant like:

`GRANT SELECT ON performance_schema.* TO ...`

Your query metric tool might require more privileges, but it certainly requires at least `SELECT` on PFS.

Lastly, I like the suggestion by Datadog to change the default value of these three system variables:

* `max_digest_length = 4096`
* `performance_schema_max_digest_length = 4096`
* `performance_schema_max_sql_text_length = 4096`

Set those three system variables in `my.cnf`.
They're not dynamic, so you have to restart MySQL.
That will cause PFS use to use a little more memory, but it's necessary for accuracy if you have queries greater than 1024 bytes long, which is not uncommon.

---

## Configuring the Slow Query Log

The [slow query log](https://dev.mysql.com/doc/refman/en/slow-query-log.html) is not as easy to configure or manage as the Performance Schema.
In the cloud, it's basically not usable, although some cloud providers (like AWS) allow you to download it, which makes [pt-query-digset](#pt-query-digest) an option.

If you must use the slow query log, your best options are [Percona Server](https://www.percona.com/software/mysql-database/percona-server) or [MariaDB Server](https://mariadb.org/) because, from my point of view, Oracle seems to prioritize Performance Schema development over slow query log development, which is probably the better technical decision.

Nevertheless, the slow query log is the classic source of query metrics&mdash;more than 20 years old and still important today.

### MySQL

Let me quote myself from chapter 1 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance):

>As of MySQL 8.0.14, enable system variable [`log_slow_extra`](https://oreil.ly/ibfRK) and the slow query log provides six of the nine metrics in "Query Metrics" on page 11, lacking only `Rows_affected`, `Select_scan`, and `Select_full_join`.
>It’s still a good source, but use the Performance Schema if possible.
>
>Before MySQL 8.0.14, which includes MySQL 5.7, the slow query log is bare bones, providing only `Query_time`, `Lock_time`, `Rows_sent`, and `Rows_examined`.
>You can still analyze queries with only these four metrics, but the analysis is much less insightful.
>Consequently, avoid the slow query log before MySQL 8.0.14 and instead use the Performance Schema.

Here's a starting point configuration for `my.cnf`:

```ini
[mysqld]
slow_query_log                = 1
long_query_time               = 0.001  # 1 millisecond
log_queries_not_using_indexes = 1
slow_query_log_file           = slow-query.log
#
# As of MySQL 8.0.14:
#
log_slow_extra                = 1 
```

<p class="warning">
<b>WARNING</b>: If you're not using MySQL 8.014 or newer, comment out the last line (<code>`log_slow_extra`</code>), else MySQL will error on startup.
</p>

Those system variables are dynamic, so you can set them without restarting MySQL, but they're not default values, so you must also set them in `my.cnf` so they're configured on startup.

The main decision to make is the value for [`long_query_time`](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_long_query_time): if set to zero, then MySQL logs _every_ query.
A zero value is basically never used because it causes too much storage I/O and generates too much data in the log file.
At a mere 1,000 QPS, for example, that's 60,000 log entries per minute, and each log entry is at least 3 lines long, so 180,000 lines/minute, which is 10.8 _million_ lines/hour or 259.2 million lines/day&mdash;and that's not even taking into consideration the log file size, which will probably be many gigabytes.

I chose 1 millisecond (`long_query_time = 0.001`) for this example, but **you must test it on your server: it might generate too much storage I/O overheard or use too much disk space.**
Adjust `long_query_time` until you find the smallest value that generates acceptable overhead and disk space.
Certain query metric tools, like [PMM](#percona-monitoring-and-management-pmm), can manage large slow query logs with tailing and rotation.

Finding the best value for `long_query_time` is difficult, which is why Percona implemented query sampling a long time ago...

### Percona Server

The Percona Server [extended slow query log](https://www.percona.com/doc/percona-server/5.7/diagnostics/slow_extended.html) has two important features: query sampling and extra query metrics.

Here's another starting point configuration for `my.cnf`:

```ini
[mysqld]
slow_query_log                = 1
long_query_time               = 0  # throttled by log_slow_rate_limit
log_queries_not_using_indexes = 1
slow_query_log_file           = slow-query.log
#
# Percona Server
#
log_slow_rate_type  = query              # query sampling
log_slow_rate_limit = 10                 # 1/10 = 10% queries logged
slow_query_log_always_write_time = 2     # always log really slow queries
log_slow_verbosity  = innodb,query_plan  # extra query metrics
```

With `log_slow_rate_type = query` and `log_slow_rate_limit = N`, you can set MySQL `long_query_time = 0` and get the best of both worlds: log virtually all queries with minimal overhead.
This is query sampling: logging every Nth query, which yields a percentage of all queries.
In this example, I chose `log_slow_rate_limit = 10`, which just happens to also equal 10% of queries logged.
The calculation is:

`(1 / log_slow_rate_limit) * 100 = % queries logged`

A quick reference for different values of `log_slow_rate_limit`, which ranges from 1 to 1000:

```
(1 /   1) * 100 = 100% (every query)
(1 /   2) * 100 =  50%
(1 /   3) * 100 =  33%
(1 /   4) * 100 =  25%
(1 /   5) * 100 =  20%
(1 /  10) * 100 =  10%
(1 / 100) * 100 =   1%
(1 / 500) * 100 = 0.2%
(1 /1000) * 100 = 0.1%
```

Even the highest value, 1000, works: on high QPS servers, logging only 0.1% of queries (every 1,000th query) quickly produces a complete and accurate picture.
This is analogous to video: you only need 24 frames per second to produce a video.
Likewise, with MySQL you only need to sample a small percentage of queries to produce an accurate query profile.

The other important feature is `log_slow_verbosity = innodb,query_plan`: this cause Percona Server to log the most query metrics of any source or distribution of MySQL.
It logs all nine essential query metrics explained in chapter 1 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance)&mdash;and a lot more.

The configuration above is a good starting point, but read the [extended slow query log documentation](https://www.percona.com/doc/percona-server/5.7/diagnostics/slow_extended.html) to learn more.

### MariaDB

MariaDB Server use the Percona Server extended slow query log code, so its configuration is the same.
See [Throttling the Slow Query Log](https://mariadb.com/kb/en/slow-query-log-overview/#throttling-the-slow-query-log) in the MariaDB documentation.
Two important notes about those docs:

* The `my.cnf` section header is `[mariadb]`
* The example shows `long_query_time=5.0` but change 5.0 to 0 when `log_slow_rate_limit` is enabled (greater than 1)

## History

Ironically, the history of "performance is query response time" originates from the book [_Optimizing Oracle Performance_](https://www.oreilly.com/library/view/optimizing-oracle-performance/059600527X/) published by O'Reilly in September 2003.
That's ironic because in 2003 MySQL was the "anti-Oracle" relational database.
Not just the fact that MySQL has always been free and open source, but the relative ease of using and managing MySQL&mdash;especially replication&mdash;made it the "anti-Oracle" relational database of choice for the internet.
But now in 2022, Oracle owns MySQL, and if you read that book and look at MySQL 8.0, you'll see the family resemblance.
The authors, Cary Millsap and Jeff Holt, where right about database performance 20 years ago and still right today: _performance is query response time_.
