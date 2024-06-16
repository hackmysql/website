---
type: "page"
date: "2023-11-06T09:00:00-05:00"
title: "The Future of MySQL Schema Change: Spirit"
tags: ["mysql", "pt-osc", "gh-ost", "Spirit"]
comments: true
aliases:
  - /post/future-of-mysql-schema-change-spirit/
disqus_url: "https://hackmysql.com/post/future-of-mysql-schema-change-spirit/"
---

Using pt-online-schema or gh-ost?
Of course you are; everyone in the MySQL industry does.
But now there's a new online schema change tool that will obsolete these two: [Spirit](https://github.com/cashapp/spirit) by renowned MySQL expert Morgan Tocker.

<!--more-->

But first, why Spirit? Why a new online schema change (OSC) tool?
Size and speed: pt-online-schema (pt-osc) and gh-ost can alter a 1 TB table in reasonable time: maybe a week or so depending on the server.
But a 2 TB table?
You could be waiting quite awhile.

In 2023 and beyond, that's no longer reasonable.
The MySQL industry needs an OSC tool capable of far greater size and speed.
I want an OSC tool that can handle **10 TB in 5 days**.

Neither pt-osc nor gh-ost can do that&mdash;not even close!
Here's what the difference looks like (drawn to scale):

![Spirit runway: 15TB](/img/spirit_runway.svg)

I want _significantly_ more runway from an OSC tool.
Although 10 TB was my challenge, we engineer conservatively so that 15 TB is feasible, too.

Spirit meets and exceeds the challenge: we've seen it alter 10 TB in 3.75 days (90 hours).

Morgan Tocker wrote and [released Spirit on October 23, 2023](https://code.cash.app/more-resilient-schema-changes-at-scale) as free open source software built for the MySQL industry.
Read his two-part release announcement for more details.


[Spirit](https://github.com/cashapp/spirit) is a new online schema change tool that, I expect, will serve the MySQL industry for the next 10 years.
As the original author of pt-online-schema-change (which has served the industry for the last 12 years), I encourage you to put pt-osc to rest and use (and contribute to) Spirit instead.
