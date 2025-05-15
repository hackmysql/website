---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Server Metrics and InnoDB"
weight: 5
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn about MySQL server metrics, especially InnoDB metrics:

<div class="intro">
MySQL metrics are closely related to MySQL performance—that’s obvious.
After all, the purpose of metrics in any system is to measure and report how the system is operating.
What’s not obvious is how they are related.
It’s not unreasonable if you currently see MySQL metrics as a black box with metrics inside that, in some way, indicate something about MySQL.

That view is not unreasonable (or uncommon) because MySQL metrics are often discussed but never taught.
Even in my career with MySQL, I have never read or heard an exposition of MySQL metrics—and I have worked with people who created them.
The lack of pedagogy for MySQL metrics is due to a false presumption that metrics do not require understanding or interpretation because their meaning is self-evident.
That presumption has a semblance of truth when considering a single metric in isolation, like `Threads_running`: the number of threads running—what more is there to know?
But isolation is the fallacy: MySQL performance is revealed through a spectrum of MySQL metrics.

Think of MySQL as a prism.
The application figuratively shines a workload into MySQL.
That workload physically interacts with MySQL and the hardware on which it runs.
Metrics are the spectrum revealed by the figurative refraction of the workload through MySQL, as depicted below.

![MySQL metrics as a prism](/img/book/mysql_metrics_prism.jpg)

In the physical sciences, this technique is called _spectrometry_: understanding matter through its interaction with light.
For MySQL, this is more than a clever analogy, it’s the actual relationship between MySQL metrics and MySQL server performance, and there are two proofs:

* When you shine a light through a real prism, the resulting color spectrum reveals properties of the light, not the prism. Likewise, when you run a workload on MySQL, the resulting metrics reveal properties of the workload, not MySQL.
* Given previous chapters, x—performance is directly attributable to workload: queries, data, and access patterns. Without a workload, all metric values are zero (generally speaking).

Viewed this way, MySQL metrics can be taught in a new light, and that is the focus of this chapter.

This analogy has another pedagogical utility: it separates MySQL metrics into _spectra_ (the plural of _spectrum_).
This is very useful because MySQL metrics are vast and unorganized (several hundred metrics strewn throughout MySQL), but effective teaching requires focus and organization.

A final note before we shine a light on MySQL: only a fraction of metrics are essential for understanding and analyzing MySQL server performance.
The relevance and importance of the remaining metrics varies widely:

* Some are noise
* Some are historical
* Some are disabled by default
* Some are very technically specific
* Some are only useful in specific cases
* Some are informational, not proper metrics
* Some are inscrutable by feeble mortal creatures

Long story short: MySQL metrics and what they really mean are not self-evident.

{{< book-excerpt-copyright c="Chapter 6" >}}
</div>

## Key Points

* MySQL performance has two sides: query performance and server performance
* Query performance is input; server performance is output
* Normal is whatever performance MySQL exhibits for your application on a typical day when everything is working properly
* Stability does not limit performance, it ensures that performance—at any level—is sustainable
* MySQL key performance indicators are: response time, errors, QPS, and threads running
* The field of metrics comprises six classes of metrics: response time, rate, utilization, wait, error, and access pattern
* Metric classes are related: rate increases utilization; utilization pushes back to decrease rate; high (maximum) utilization incurs wait; wait timeout incurs error
* _Resolution_ means the frequency at which metrics are collected and reported
* High resolution metrics (5 seconds or less) reveal important performance details that are lost in low resolution metrics
* Alert on what users experience (like response time) and objective limits
* Application issues (your application or another) are the most likely cause of slow MySQL performance
* MySQL performance is revealed through a spectrum of server metrics that are the figurative refraction of the workload through MySQL

## Pitfalls

* Seeing metrics as a reflection of MySQL rather than the workload
* Fixating on server metrics (ignoring query metrics and slow queries)
* Reporting all metrics (most aren't useful)
* Low resolution metrics (&gt; 10s)
* Charting metrics incorrectly (wrong aggregation or roll up)
* Using averages (except for hardware resources: CPU, RAM, disk, network)
* Alerting DBAs on replication lag (alert the application owners)
* Alerting on arbitrary thresholds or non-actionable events (pager fatigue and desensitization)

## Hack MySQL Articles

{{< path-articles path="metrics" >}}

## Additional Resources

<div class="note">
<b>Comprehensive Guide</b><br> 
If you're serious about learning this topic, you must read chapter 6 of <a href="https://www.amazon.com/Efficient-MySQL-Performance-Practices-Techniques/dp/1098105095/"><i>Efficient MySQL Performance</i></a>.
Even as of May 2025, it's still the only resource that explains all important MySQL server and InnoDB metrics <i>in depth</i>.
The Hack MySQL articles above are a small sample that demonstrate how much there is to learn and how deep the topic goes.
</div>

| Resource | Type | About |
|----------|------|-------|
|[Server Status Variables](https://dev.mysql.com/doc/refman/en/server-status-variables.html)|MySQL manual|The official but often terse description of MySQL server status variables. More of a reference than a guide to understanding them. There are more sources of metrics, but this is the main source.|
