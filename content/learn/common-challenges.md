---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Common Challenges"
weight: 8
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn about common challenges when using MySQL:

<div class="intro">
This chapter is a short but important laundry list of common MySQL challenges and how to mitigate them.
These challenges don’t fit into other chapters because most are not directly related to performance.
But don’t underestimate them: the first two challenges, for example, can ruin a database.
More importantly, these challenges are not special cases that only happen when the stars align and The Fates conspire to ruin your day.
These are common challenges.
Take them seriously, and expect to face them.

{{< book-excerpt-copyright c="Chapter 9" >}}
</div>

## Key Points

* Split-brain occurs when two or more MySQL instances in the same replication topology are written to
* Split-brain is a detriment to data integrity&mdash;the data can no longer be trusted
* Data drift occurs when a replica becomes out of sync with the source
* Data drift is real but the origin of the drift is virtually impossible to pinpoint
* Data drift can be detected with pt-table-checksum
* ORMs can generate very poor queries and overall performance
* Schemas always change, so an online schema change (OSC) tool is must-have
* There are three popular OSC tools: pt-online-schema-change, gh-ost, and Spirit
* MySQL has non-standard SQL statements, options, and clauses
* Applications do not fail gracefully by default; it takes effort to fail gracefully
* High performance MySQL is difficult

## Pitfalls

* Not taking into account the key points above

## Hack MySQL Articles

{{< path-articles path="common" >}}

## Additional Resources

| Resource | Type | About |
|----------|------|-------|
|[InnoDB and Online DDL](https://dev.mysql.com/doc/refman/en/innodb-online-ddl.html)|MySQL manual|Since schema changes are routine for developers, it's important to understand how MySQL (and InnoDB) handle them because there are many edge cases depending on the specific type of change.|
|[Spirit](https://github.com/block/spirit)|Open source tool|The fastest, most advanced online schema change (OSC) change tool available.|
|[gh-ost](https://github.com/github/gh-ost)|Open source tool|The predecessor of Spirit. Both are solid tools, but use Spirit if possible.|
|[pt-table-checksum](https://docs.percona.com/percona-toolkit/pt-table-checksum.html)|Open source tool|Still the only tool that can detection data drift on replicas|

<div class="note">
<b>pt-online-schema-change</b><br>
Before gh-ost and Spirit, pt-online-schema-change (pt-osc) was the de facto standard tool.
It's still widely used and referenced today, but as the author of pt-osc I strongly advise that you use Spirit instead.
The only reason to use pt-osc is for rare (and risky) edge cases that Spirit (and usually gh-ost) do not support for good reason.
</div>
