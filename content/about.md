---
title: "About"
menu: main
summary: "Hack MySQL is the personal website of Daniel Nichter, author of the book Efficient MySQL Performance published by O'Reilly. His webiste explores MySQL, Go, and software design."
---

## Hack MySQL

Hack MySQL is my personal website about MySQL, the Go programming language, software design, and software engineering.

In 2004 while working at a data center, I decided to make MySQL the focus of my tech career.
For the last 20 years, I've worked with MySQL every day both professionally and personally.

In addition to MySQL, I specialize in software design, the Go programming language, and helping other software engineers learn and level up.
The latter is enabled by having 30+ years of total experience.
Prior to MySQL, I worked roles from network engineering to PC repair.

"Hack" in the name of this website refers to technical curiosity and cleverness&mdash;two elements of the hacker spirit.
Although computers and programming are commonplace today, decades ago the field was a frontier, wild and uncharted.

## Book

I am the author of _Efficient MySQL Performance_, published by O'Reilly.

<a href="https://oreil.ly/efficient-mysql-performance"><img class="my-book-cover" style="margin: unset;" src="/img/book/efficient-mysql-performance-cover.png"></a>

## Contact

Email "public" at this domain.

I am _zero social media_: no Facebook, no Twitter, no LinkedIn, no Instagram&mdash;nothing. Anyone with my name on social media is not me.

## Output

Andy Grove wrote about _activity_ versus _output_ in [High Output Management](https://www.goodreads.com/book/show/324750.High_Output_Management).
I am driven by (and have a healthy obsession with) _output_ that contributes value to other people.
I'm happiest at work when building tools and services that help others work more efficiently.
And fortunately I've had many opportunities to do that in my career:

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

### &check; Etre

[Etre](https://github.com/square/etre) is a small but mighty service: an API for tracking assets with user-defined labels.
My colleagues and I developed it at Square to track MySQL nodes and associated metadata (as labels).
Other back end services query Etre to find particular database nodes.
There are other solutions for tracking assets with metadata, but Etre is simpler to use and operate&mdash;it _just works_.

### &check; Spin Cycle

Unlike Etre, [Spin Cycle](https://github.com/square/spincycle) is large and necessarily complex.
My colleagues and I developed it at Square to coordinate doing A + B + C + ... = Z, where Z was the back end product we needed to create by calling many different back end systems&mdash;everything from REST and gRPC APIs owned by other teams, to remote system commands via `rce-agent`.
This was years before workflow services like [Temporal](https://temporal.io/).
But even today, I'm not sure a workflow service would work for various reasons that don't matter here.
Spin Cycle is a powerful, reliable, and reusable workhorse that coordinates most of the Square database fleet at impressive scale.

### &check; square/rce-agent

[rce-agent](https://github.com/square/rce-agent) is a highly secure remote command execution (RCE) client-server developed by me and my colleagues at Square.
At a fintech company, even `ssh` isn't secure enough, so this little but important service takes RCE security to the extreme.

### &check; go-test/deep

Used by over 20,000 (!) other projects, [go-test/deep](https://github.com/go-test/deep) is a surprisingly popular little package, probably because it makes Go testing so much easier, which is why I developed it.
It's a tiny, single function package, but the internal complexity is 🤯 because it requires plumbing nearly the full depth of Go reflection.

### &check; go-mysql

With [go-mysql](https://github.com/go-mysql/) I had hoped to create _the_ go-to project for MySQL-related Go modules.
Basically, I wanted to reproduce the PT modules in Go but with even better, more reusable interfaces.
But this project didn't take off&mdash;it's really difficult creating widely used reusable packages.
The best outcome was [go-mysql/hotswap-dsn-driver](https://github.com/go-mysql/hotswap-dsn-driver), which is novel and very useful.

### &check; go-metrics

[go-metrics](https://github.com/daniel-nichter/go-metrics) is a beautifully designed metric package for counters, gauges, and histograms.
It's also [rigorously researched and implemented](../eng/percentiles/).
However, it's not popular, probably because engineers use whatever metrics package is already in use and rarely shop around for a better one.
Maybe some day more engineers will discover and use it.

### &check; go-cmd

[go-cmd](https://github.com/go-cmd/cmd) wraps [Go os/exec](https://pkg.go.dev/os/exec) to provide all the little (but important) details that the low-level Go package doesn't provide.
It has garnered a decent user base and many contributors, but it's a nice, so I don't expect it to be wildly popular.
Regardless, it provides a lot of value by handling a lot of fine details with respect to correctly running (and terminating) external commands.

### &check; Square Query Metrics

When I joined Square in 2016, my first project was to create an internal query metrics system like Datadog Deep Database Monitoring or SolarWinds Database Performance Monitor (formerly VividCortex).
For various reasons, neither PMM nor VividCortex worked for Square at that time.
But I had developed or helped develop most query metric tools in the MySQL industry, so it took me only 3 months (with the help of an intern) to develop the internal query metrics system that Square still uses today.
In the years since, it has provided countless value to hundreds (perhaps thousands) of engineers and saved Square a lot of money (because commercial products are expensive at scale).

### &check; Cash DBA Team

In 2021, I switch from Square to Cash (both a part of Block) to bootstrap a new Cash DBA team.
After 5 years on the Square DBA team, I was no longer needed for a good reason: I successfully helped build that team and infrastructure up and out to the point where they were successful without me.
Then I switch to Cash and did the same in two years: a new manager and a handful of engineers who successfully manage the Cash database fleet without me.
I'm still at Cash, but currently I work on various aspects of the whole Cash data strategy.

### &check; Conference Presentations

Over the course of my career with MySQL, I have often presented at the yearly MySQL conference (which changed owners and names over the years).
For example, you can hear me drone on about [Efficient MySQL Performance at Percona Live 2022](https://www.youtube.com/watch?v=1C6thrnoGU0).

### &check; BA Philosophy

I have a bachelors degree in philosophy.
As it turns out, logic and reason are quite useful with databases and software engineering.
And in a business sense, being able to reason and communicate _very_ clearly about large, complex issues is a super power.
At work, a large part of my job is bring clarity and focus to projects, questions, and issues; and this helps engineers work efficiently and happily by knowing what they're doing and why.

### &check; MA French

I have a masters degree in French.
Never mind why.
Like my BA in philosophy, my MA in French taught me how to work hard&mdash;really hard&mdash;and how to teach others.
As any graduate student knows, graduate studies require a lot more work than undergraduate studies.
The same is true in business the more one's career advances.
And as some graduate students know, teaching others is its own field of study: pedagogy.
In my graduate program, I took a course on pedagogy and taught several French classes (as the full "professor of record", not a TA).
Now I teach MySQL, software engineering, and related subjects, but the pedagogical principles are the same.

### &check; _French in the History of Wyoming_

I consider my masters thesis as one of my greatest accomplishments and contributions to the world: [_French influences in the history of Wyoming from La Salle to Arland_](https://www.proquest.com/docview/1015630697/A8A688E8294745E1PQ/1).
Years later, I adapted it for a book called _French in the History of Wyoming_ that I hope to have published.
Since I don't have a Ph.D. in history, it's difficult to find a publisher even though I am absolutely certain the material is qualified because the work was vetted and approved by five professors (three of whom from prestigious schools: Yale, Harvard, and Stanford).
But since isn't computer-related, I won't digress on this web site.

## Credits

This website uses:

* [GitHub Pages](https://pages.github.com/)
* [Hugo](https://gohugo.io/)
* [Ionicons](https://ionic.io/ionicons)

The bird on the cover of my book and in the upper-left of each page is a [crested barbet](https://en.wikipedia.org/wiki/Crested_barbet) (_Trachyphonus vaillantii_) drawn by Karen Montgomery, based on a black and white engraving from _English Cyclopaedia_.

<hr>

_No AI was used to write or edit text on this website_.
All content on this website (except where cited or linked) is original work written and edited by me, Daniel Nichter, and represents only my thoughts and opinions, never my employers past, present, or future.
