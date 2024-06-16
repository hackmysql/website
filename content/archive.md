---
title: "Archive"
summary: "The HackMySQL archives"
aliases:
  - /mysqlreport
  - /mysqlreportdoc
  - /mysqlsla
  - /mysqlsla_guide
  - /mysqlsniffer
  - /mysqlidxchk
  - /archive/mysqlreport
  - /archive/mysqlsla
  - /archive/mysqlsniffer
  - /archive/mysqlidxchk
  - /case1
  - /case2
  - /case3
  - /case4
  - /case5
  - /nontech
  - /tools
---

<style>
button#focus {display:none; visibility:hidden;}
nav#toc {display: none;}
h1 {margin:0.5rem 0;}
.post-meta {display:none}
</style>

<div class="left-icon" style="border: 3px solid hotpink; border-radius: 15px; padding:1rem;">
<img class="ion" src="/img/ionicons/alert-circle-outline.svg">
Redirected from another link?
That link points to something archived.
Rather than leaving you stranded on a 404 page, this archive provides alternatives.</p>
</div>

## Tools

The <a href="https://github.com/daniel-nichter/hackmysql.com/tree/master">original tools</a> I wrote (circa 2004&ndash;2008) are deprecated, unmaintained, and unsupported.
Use an alternative tool.

|Original Tool|Alternatives|
|-------------|------------|
|mysqlreport  |[pt-summary](https://docs.percona.com/percona-toolkit/pt-mysql-summary.html)  |
|mysqlsla     |[pt-query-digest](https://docs.percona.com/percona-toolkit/pt-query-digest.html), [PMM](https://www.percona.com/software/database-tools/percona-monitoring-and-management), and vendor-specific solutions|
|mysqlidxchk  |[`sys.schema_unused_indexes`](https://dev.mysql.com/doc/refman/en/sys-schema-unused-indexes.html)|
|mysqlsniffer |[Wireshark](https://www.wireshark.org/docs/dfref/m/mysql.html)|

## Case Studies

In addition to tools, I wrote a number of case studies that are now too out of date to reprint:

* case1/ Indexing Basic MySQL Queries
* case2/ Table Design and MySQL Index Details
* case3/ MySQL ORDER BY With LIMIT and ANALYZE
* case4/ How To Index For Joins With MySQL
* case5/ How To Look At MySQL Joins and More ORDER BY With LIMIT

Instead, read my book: [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance).
It's up to date, covers the same topics (in chapter 2), and teaches a lot more.

## Pages

* nontech/ Non-technical Guide to Isolating Slow MySQL Queries
* joinrows/ JOIN Rows Produced vs. Rows Read

Sorry to repeat myself but, read my book: [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance).
Original guides and other content on this website are captured in book, which is far more comprehensive and up to date.

## CPAN Modules

All CPAN modules I created are obsolete and unmaintained.
The alternative is to find or rewrite the module as a <a href="https://pkg.go.dev/">Go package</a>.
Let Perl rest in peace; it had a long and productive life.
Use Go instead.
