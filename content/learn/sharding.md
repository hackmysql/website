---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Sharding"
weight: 4
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn about sharding MySQL:

<div class="intro">
On a single instance of MySQL, performance depends on queries, data, access patterns, and hardware.
When direct and indirect query optimization—assiduously applied—no longer deliver acceptable performance, you have reached the relative limit of single-instance MySQL performance for the application workload.
To surpass that relative limit, you must divide the application workload across multiple instances of MySQL to achieve MySQL at scale.

_Sharding_ a database is the common and widely used technique of _scaling out_ (or, _horizontal scaling_): increasing performance by distributing the workload across multiple databases.
(By contrast, _scaling up_, or _vertical scaling_, increases performance by increasing hardware capacity.)
Sharding divides one database into many databases.
Each database is a shard, and each shard is typically stored on a separate MySQL instance running on separate hardware.
Shards are physically separate but logically the same (very large) database.

MySQL at scale requires sharding.
I’m going to repeat that sentence several times in this chapter because it’s a fact that engineers hesitate to accept.
Why?
Because sharding is not an intrinsic feature or capability of MySQL.
Consequently, sharding is complex and entirely application-specific, which means there’s no easy solution.
But don’t be discouraged: sharding is a solved problem.
Engineers have been scaling out MySQL for decades.

{{< book-excerpt-copyright c="Chapter 5" >}}
</div>

## Key Points

* MySQL scales out by sharding
* Sharding divides one database into many databases
* A single database does not scale primarily because the combination of queries, data, and access patterns—the application workload—significantly outpace the speed and capacity of single-server hardware
* It’s significantly easier to manage many small databases (shards) than one huge database—pebbles, not boulders
* Data is shared (divided) by a shard key, which you must choose carefully
* The shard key is used with a sharding strategy to map data (by shard key) to shards
* The most common sharding strategies are hash (a hashing algorithm), range, and lookup (directory)
* Sharding creates new challenges that must be addressed

## Pitfalls

* Not planning ahead: will you need to shard MySQL in the next 1&ndash;4 years?
* Not having a good sharding key
* Underestimating the operational complexity of sharding
* Choosing a poor sharding algorithm/strategy
* Having hot spots (or hot shards)
* Not solving for high availability (does the application still work if _only one_ shard fails?)
* Not considering another technology or paradigm to avoid sharding

## Hack MySQL Articles

{{< path-articles path="shard" >}}
