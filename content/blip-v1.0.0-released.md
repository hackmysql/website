---
type: "page"
date: "2022-12-22T12:55:00-05:00"
title: "Blip: A New Open Source MySQL Metrics Collector"
tags: ["mysql", "metrics", "monitoring", "blip"]
aliases:
  - /post/blip-v1.0.0-released/
---

[Blip](https://github.com/cashapp/blip) is a new open source MySQL metrics collector, or "MySQL monitor" for short.
But isn't collecting MySQL metrics easy?
And don't we already have some open source MySQL monitors?
Let's take a trip down [memory lane](https://www.merriam-webster.com/dictionary/memory%20lane)...

<!--more-->

## Past

In ancient times, generic monitors like `statsd` and `collectd` were used to collect MySQL metrics for back ends like Graphite.
Some people still use this tech to collect MySQL metrics.

Then along came Prometheus in 2015, and with it `mysqld_exporter` became the new standard.
Release history for `mysqld_exporter` is heavy in 2015 and 2016, then it dwindled: 

|Year|Number of Releases|
|----|------------------|
|2017|1|
|2018|1|
|2019|2|
|2020|0|
|2021|1|
|2022|1|

Releases per year is _not_ the only indicator of liveliness or relevance.
It's quite possible that `mysqld_exporter` wasn't updated more frequently because it didn't need to be: few bugs, works great, all is well.
But I don't think that's the case based on its pileup of feature requests, which is a reflection of another bit of MySQL history...

MySQL 5.7 and `mysqld_exporter` were released in 2015.
Without digressing too much, 5.7 was the culmination of about 15 years of work and improvements&mdash;an amazing product.
Three years later, MySQL 8.0 was released, but (in my opinion) its adoption paled in comparison to how the industry adopted past versions from 3.23 through v4 and v5.
Why?
Because 5.7 was so great (why upgrade?), and the broader industry was changing in various ways.
Although 8.0 adoption was slow, MySQL and the industry kept changing, which means that `mysqld_exporter` had to keep up, but I don't think it did.
Consequently, Percona forked `mysqld_exporter` for [Percona Monitoring and Management (PMM)](https://www.percona.com/software/database-tools/percona-monitoring-and-management).

But Percona was more interested in PMM than `mysqld_exporter`, and I would know: I created PMM v1.0.
Fun fact: we (at Percona) did develop an open source MySQL monitor, but we never released it because, instead, we decided to use the existing open source solution: `mysqld_exporter`.
I opposed this change because I have never thought `mysqld_exporter` is well designed, and I think the scrape/pull model is inefficient and cumbersome for databases (especially at scale).
It took many years, but a friendly "I told you so": [Percona stopped using Prometheus](https://docs.percona.com/percona-monitoring-and-management/details/victoria-metrics.html).

MySQL monitors have languished for the last several years.
Today, no open source MySQL monitors is even remotely close to being a modern, cloud-ready, flexible solution for collecting MySQL metrics.
The fundamental reason is simple: no one has created a MySQL monitor _only for MySQL_.

`mysqld_exporter` was successful not because it's a good MySQL monitor (it's not), but because [Prometheus](https://prometheus.io/) is a great product.
Although I don't like that exporter, I really like Prometheus (and [Grafana](https://grafana.com/)).
The exporter was created for the Prometheus ecosystem, not for MySQL and not for a general audience.
That's fundamentally why its design and usability are flawed and limited _as a MySQL monitor_.
In other words: as a Prometheus exporter, it's a great exporter; but as a MySQL monitor, it's not a good tool.

This true for every MySQL monitor available: they're built for some other product or purpose, not _only for MySQL_.
For example, the [Datadog Agent for MySQL](https://docs.datadoghq.com/integrations/mysql/) is actually a pretty good MySQL monitor.
I'm impressed by the extensive list of metrics it collects and its flexibility.
However, it only works for Datadog&mdash;of course!

## Present

Collecting MySQL metrics is not easy because there are _a lot_ of MySQL metrics.
As a 20+ year old product, MySQL has grown and changed in many ways.
Today, `SHOW GLOBAL STATUS` is a mess.
Some of the output isn't metrics at all!
And InnoDB metrics?
Some tools still parse the text dump of `SHOW ENGINE INNODB STATUS`.
And what about the MySQL 8.0 terminology changes?

Moreover, the industry around MySQL has changed, too.
For example, where do you report the metrics?
SaaS metric and graphing platforms are increasingly common, like Datadog, Splunk (which acquired SignalFx), Chronosphere, and more.

Collecting MySQL metrics correctly and efficiently for a general audience is quite difficult.

## Future

I wrote [Blip](https://github.com/cashapp/blip) for MySQL and for the future.
That means several things, but for this blog post I'll highlight only two.

First, that means Blip works with any distro of MySQL 5.7 and newer.
(It probably works for 5.6, but that's not supported because 5.6 was EOL in February, 2021.)
From Oracle to Percona to Maria to AWS and everyone else: Blip doesn't care as long as whatever it connects to "speaks" MySQL.

Second, that means Blip was designed to be _easily_ updated and expanded without any core code changes.
This is possible because I gave it a plugin architecture around a central core.
The central core is, of course, collecting MySQL metrics.
Once the surrounding complexities are handled, the main job of _collecting metrics_ is invariant: execute some commands, filter and save the values.
In the last year or so since we've been battle-testing Blip where I work, no one has had to touch the core&mdash;it just works.
The really hard part is all the surrounding complexities...

Having written Blip, I'm pretty sure why no one did this years ago: it's really difficult to account for all the various ways and places people run MySQL.
But my career has given me a unique advantage: I've run MySQL in the most common ways and places.
For example, where I work we have two different MySQL fleets: Percona Server running on bare metal in data centers, and AWS Aurora in the cloud.
(We actually have more, but I'm keeping things simple for this blog post.)
There's almost nothing similar about those two except they're both MySQL under the hood.

So how does one program account for all the surrounding complexities?
With well-defined abstractions and plugins, which in [Go](https://go.dev/) are interfaces.
For example, one thing I cannot know is where users will _send_ metrics.
Obviously, everyone _collects_ metrics from MySQL (that's the central core mentioned above), but after that it's anyone's guess.
So in Blip, metrics reporting (sending) is implemented as "metric sinks", which are small plugins that send metrics somewhere, anywhere.
Blip ships with some default sinks (for things we use where I work), but it's easy for you to write your own sink to send metrics wherever.

Of course, it's all easier said than done, but now it's done in Blip.

There's a lot more I could say, but I already spent months writing the [Blip documentation](https://cashapp.github.io/blip/) to explain it all.

## Thank You

Blip took 6 months of focused developed, an additional 8 months of testing and documentation, and thousands of MySQL instances on bare metal and in the cloud.
All that time and all those resources were made possible by [Cash App](https://cash.app/) and [Square](https://squareup.com/)&mdash;both parts of [Block](https://www.block.xyz/), where I work.
And my colleagues who contributed significant code, testing, and feedback:

* Joy Nag
* Wenhui Sun
* Ian Oberst
* Prudhvi Dhulipalla
* Serj Sililian
* Jemiah Westerman
* Allan Liu
* Morgan Tocker
* Jash Lal

And Percona where, many years ago, I developed similar tools that gave me the background and experience that made designing Blip easier&mdash;and for carrying the torch of independent open source software that Blip reflects.
