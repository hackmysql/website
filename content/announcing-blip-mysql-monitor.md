---
type: "page"
date: "2023-03-28T13:40:00-04:00"
title: "Announcing Blip: A New MySQL Monitor"
tags: ["blip", "mysql", "monitoring"]
aliases:
  - /post/announcing-blip-mysql-monitor/
---

<a href="https://github.com/cashapp/blip" target="_blank">Blip</a> is a new MySQL monitor that collects and reports server metrics.
But wasn't this problem solved long ago?
Not really...

<!--more-->

---

**TL;DR: https://cashapp.github.io/blip/v1.0/intro/concepts**

---

## A Problem Remains

In the MySQL ecosphere, there are go-to tools for almost everything.
[Percona Toolkit](https://www.percona.com/software/database-tools/percona-toolkit) is the most well known suite of such tools, but there are others like [gh-ost](https://github.com/github/gh-ost).
And certain commercial products are popular, like [Datadog](https://www.datadoghq.com/), which has remarkably good MySQL monitoring.

For free open source MySQL monitoring (collecting and reporting server metrics), the go-to standard since 2015 has been [`mysqld_exporter`](https://github.com/prometheus/mysqld_exporter).
And while it's widely used, it's not _truly_ general purpose or future-proof.
Fact is that it was created for [Prometheus](https://prometheus.io/), not for MySQL.
As such, it works only one way and it requires an additional system: something to scrape the exporter.

Along came [Percona Monitoring and Management (PMM)](https://www.percona.com/software/database-tools/percona-monitoring-and-management) around 2016.
When we (I and other engineers at Percona) created it, we debated whether or not to write a MySQL monitor or use `mysqld_exporter`.
The latter was chosen because Percona is fundamentally committed to open source.
But since `mysqld_exporter` is not _truly_ general purpose or future-proof, along came [`percona/mysqld_exporter`](https://github.com/percona/mysqld_exporter).

It seems PMM has been successful.[^1]
But it's not a MySQL monitor; it's "an open source database observability, monitoring, and management tool for MySQL, PostgreSQL, and MongoDB."
So if you all need is a MySQL monitor, then a problem remains: there is no free, open source MySQL monitor that's modern, flexible, and future-proof.

[^1]: I left Percona in 2016; PMM v1.0 was my last project. So I can gauge its success only from the outside.

## Blip Is the Solution

<a href="https://github.com/cashapp/blip" target="_blank">Blip</a> is the best and most advanced MySQL monitor ever written.
Big claim!
But with just shy of 20 years experience writing MySQL tools, if I can't claim that, then who can?

Following are two big reasons why I think Blip will serve the MySQL industry very well for a decade or more to come.

#### Blip Doesn't Care Where

To my knowledge, Blip is the first and only MySQL monitor written specifically for MySQL and _not_ for any other product, service, or system.
That means Blip works with every MySQL, everywhere: on-premise or in the cloud; MySQL or MariaDB; even "MySQL-compatible" products like [Aurora](https://aws.amazon.com/rds/aurora/) and fully-managed MySQL platforms like [PlanetScale](https://planetscale.com/).[^2]

[^2]: Somebody might be annoyed that I put these two in the same sentence, but Blip is impartial.

Blip doesn't care if you're a trillion-dollar cloud provider or a precocious kid spinning up their first instance of MySQL 8.0 Community Edition.
Blip was built from the ground up _for MySQL_ and only MySQL.

Likewise, Blip doesn't care where or how you report the metrics that it collects.
It can report metrics anywhere, in any format, but it's really a separate concern that leads us to the next point.

#### Blip Is Designed for Change

In shortest technical terms: Blip uses a plugin architecture for almost everything.
Here's why this matter.

If you want a tool to be useful for a general audience for a long time (5&ndash;10+ years), you must design it for change.
MySQL has changed _a lot_ over the last 20 years&mdash;even just the last 7 years since PMM was released.
And we're certain that the future will bring more changes.

Moreover, there is no standard MySQL setup: configuration, environment, and so forth.
MySQL in the cloud can be a very different setup than MySQL on bare metal.

Oh right, I almost forgot: on top of those two, there's no telling where or how users will report metrics.
What if your company uses a hosted metrics and monitoring platform like [Splunk](https://www.splunk.com/)?

A future-proof tool must account for&mdash;and allow for&mdash;changes in:

1. MySQL distributions and versions
1. How MySQL is set up and run
1. Where and how metrics are reported

Blip does all three.

Because of point 1, MySQL metrics are far trickier to collect that one might think: metrics have changed significantly over 20 years of distros and versions.
`SHOW GLOBAL STATUS` still reigns, but experienced DBAs know that there are far more metrics and sources of metrics.

<mark>To future-proof metrics collection, all Blip metric collectors are plugins that make it possible to extend Blip without changing any core code.</mark>

For example, need [group replication (GR)](https://dev.mysql.com/blog-archive/mysql-group-replication-a-quick-start-guide/) metrics?
Blip v1.0 doesn't have built-in support for GR metrics, but it's easy for you (or anyone) to write a metrics collector plugin for GR.
You don't even have to modify or contribute upstream: you can extend Blip in your own private repo.
However, in the spirit of open source, we encourage you to [contribute to Blip](https://github.com/cashapp/blip/blob/main/CONTRIBUTING.md).

Blip is extendable in many more ways, but I'll stop here to keep this blog post somewhat short.

#### More Reasons

Blip was designed to solve real-world problems: https://cashapp.github.io/blip/about/problem-solved

Problem 6 is a game changer; no other MySQL monitor can collect metrics like Blip.

## What Now?

Although technology changes quickly, people (and businesses) tend not to change quickly.
That's especially true in the database world where stability is a virtue.
So I don't expect Blip to change the MySQL industry over night, but I hope and expect that it will change the industry over time because it really is the most advanced MySQL monitor ever built&mdash;and it was built for everyone.

Where I work, we have a very large, heterogeneous fleet of MySQL.
Blip has been running for over a year, and it has proven its value: every time something changes, whether big or small, Blip adapts or extends easily.
I am grateful and thankful to my colleagues who made significant contributions, testing, and feedback to Blip:

* Joy Nag
* Wenhui Sun
* Ian Oberst
* Prudhvi Dhulipalla
* Serj Sililian
* Jemiah Westerman
* Allan Liu
* Morgan Tocker
* Jash Lal

Now that you're aware of <a href="https://github.com/cashapp/blip" target="_blank">Blip</a>, when you're ready to take your MySQL monitoring to the next level, give it a try and contribute to the project.

Until then, if you just want to read more, check out the <a href="https://cashapp.github.io/blip/" target="_blank">Blip docs</a>.
