---
title: "Hack MySQL: 2005–2025"
summary: "Hack MySQL is the personal website of Daniel Nichter, author of the book Efficient MySQL Performance published by O'Reilly."
comments: false
---

Hack MySQL is an archive and a monument to [20 years]({{< ref "lessons-from-20-years-hacking-mysql-part-1" >}}) of work and contributions to what was&mdash;for the better part of 30 years&mdash;the world's most popular open source relational database: MySQL.

In 2025, I left my principal engineer role at Block (fka Square), where I had worked for 9 years.
Although the role was lucrative, I could see the corporate writing on the wall, so I quit on top and of my own accord.
Likewise, I could see the corporate writing on the wall for MySQL.

MySQL today is nothing like it was in the early- to mid-2000s, and it never will be again.
And that's okay.

I wouldn't change a thing about my career with MySQL.
It was _a lot_ of fun!
And now it's time to move on because, since I left Block, I've had a lot of time to think and you know what?
I still love databases&mdash;especially relational databases.

Now I'm learning Postgres, working on [`mlrd`](https://mlrd.tech/), and (of course) doing more with AI.

## Contributions

### &check; _Efficient MySQL Performance_

I wrote [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) for software engineers _using_ MySQL, not DBAs.
That's a huge audience; I bet users outnumber DBAs 1,000 to 1.
If a software engineer reads and applies everything in this book, I'm certain they will achieve amazing MySQL performance&mdash;a skill that will help propel their career.

### &check; Percona Toolkit

I'm commonly known in the MySQL industry for the 8 years I spent working on [Percona Toolkit (PT)](https://www.percona.com/software/database-tools/percona-toolkit).
Anyone remotely familiar with MySQL knows that PT is to MySQL as a mechanic's tools are to a car: indispensable and practically inseparable.
PT is so popular, I bet that every MySQL DBA in the world has used at least one PT tool.

### &check; Percona Cloud Tools

Not many will know or remember Percona Cloud Tools (PCT) because the project was shut down after 2 years of development.
PCT was the first commercial query metrics SaaS platform.
In short, it was [Datadog Deep Database Monitoring](https://www.datadoghq.com/dg/monitor/databases/) or [SolarWinds Database Performance Monitor](https://www.solarwinds.com/database-performance-monitor) (formerly VividCortex) but created years before these two.

### &check; Percona Monitoring &amp; Management

Many parts of PCT were turned into [Percona Monitoring and Management (PMM)](https://www.percona.com/software/database-tools/percona-monitoring-and-management) v1.0.
I worked on PMM during my final year at Percona.
Today, many years later, PMM is still a core Percona product, and a few (but not many) of my original v1.0 code contributions remain.

### &check; HackMySQL Tools

Years before Percona Toolkit, I got my start in the MySQL industry with this domain and a few tools: `mysqlreport`, `mysqlsla`, `mysqlsniffer`, and others.
These tools were retired a long time ago (replaced by PT and other products), but for several years they were the de facto standard in the industry.
Amazingly, this site still gets hits for these tools, which is why stub pages like [Archive / mysqlreport](../archive/mysqlreport/) exist: to let people know that whatever link they followed is seriously out of date.

### &check; HackMySQL Content

When my tools became obsolete, the content of this domain&mdash;the blog posts and pages&mdash;became the focus.
The current version of this site has only the last 6 years of content, but I've been writing here for almost 20 years (since 2005).
This is a niche site, but it has a few thousand visitors every month.
More importantly for me, many of the posts and pages here allow me to "write once, teach many" since I spend a good portion of my time training new engineers.

### &check; Finch
[Finch](https://github.com/square/finch) is my latest open source contribution: a modern MySQL benchmarking tool.
Like most long-time MySQL users, I've used sysbench for almost 20 years, but I needed (and wanted) a much easier and more flexible benchmark tool.
At work, I need to evaluate (benchmark) many different types of databases and workloads.
[COMMIT Latency: Aurora vs. RDS MySQL 8.0]({{< ref "commit-latency-aurora-vs-rds-mysql-8.0" >}}) is a good example.
I made Finch to make this work exceptionally easy so I could fiddle less with the tool and focus more on the business results.
Since I had the time, I spent 8 months polishing Finch into an incredibly powerful yet easy and flexible tool.

### &check; Blip

[Blip](https://github.com/cashapp/blip) is my second to latest open source contribution: the most advanced MySQL monitor ever written.
Check out the [Blip docs](https://cashapp.github.io/blip/).
I hope Blip will become the MySQL monitor that everyone uses.
That'll take a long time, so let's check back in a few years.

### &check; go-mysql

With [go-mysql](https://github.com/go-mysql/) I had hoped to create _the_ go-to project for MySQL-related Go modules.
Basically, I wanted to reproduce the PT modules in Go but with even better, more reusable interfaces.
But this project didn't take off&mdash;it's really difficult creating widely used reusable packages.
The best outcome was [go-mysql/hotswap-dsn-driver](https://github.com/go-mysql/hotswap-dsn-driver), which is novel and very useful.

### &check; Conference Presentations

Over the course of my career with MySQL, I have often presented at the yearly MySQL conference (which changed owners and names over the years).
For example, you can hear me drone on about [Efficient MySQL Performance at Percona Live 2022](https://www.youtube.com/watch?v=1C6thrnoGU0).

## Credits

This website uses:

* [GitHub Pages](https://pages.github.com/)
* [Hugo](https://gohugo.io/)
* [Ionicons](https://ionic.io/ionicons)

The bird on the cover of my book and in the upper-left of each page is a [crested barbet](https://en.wikipedia.org/wiki/Crested_barbet) (_Trachyphonus vaillantii_) drawn by Karen Montgomery, based on a black and white engraving from _English Cyclopaedia_.

## Contact

Email "public" at this domain.

I am _zero social media_: no Facebook, no Twitter, no LinkedIn, no Instagram&mdash;nothing. Anyone with my name on social media is not me.

<hr>

All content on this website (except where cited or linked) is original work written and edited by me, Daniel Nichter, and represents only my thoughts and opinions, never my employers past, present, or future.
