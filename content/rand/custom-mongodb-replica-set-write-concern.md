---
type: "page"
date: "2017-06-11"
title: "Custom MongoDB Replica Set Write Concern"
subtitle: "For data center-aware write acks"
tags: ["mongodb", "replica set", "write concern", "tag set"]
comments: true
---
One of the great things about MongoDB is [write concern](https://docs.mongodb.com/manual/reference/write-concern/):

> Write concern describes the level of acknowledgement requested from MongoDB for write operations to a standalone mongod or to replica sets or to sharded clusters.

Awesome! I want 1 write ack from any secondary in the primary DC so when the primary crashes we're guaranteed to have an up-to-date secondary in the primary DC ready to be elected primary. Here's my production MongoDB replica set:

![MonoDB Cluster](/img/mongodb-cluster.svg)

_All_ queries happen on the current primary. The secondaries in the primary DC are hot-standbys. The p0 (priority-zero) members in the disaster recovery (DR) DC vote but don't become primary in normal failover situations. (We fail over to the DR DC manually when a disaster takes the whole primary DC offline.)

Here's the problem: the MongoDB manual doesn't make it clear or obvious how to achieve what I want. The answer is a subtle and careful reading of three pages:

* [Write Concern](https://docs.mongodb.com/manual/reference/write-concern/)
* [Replica Set Configuration](https://docs.mongodb.com/manual/reference/replica-configuration/)
* [Configure Replica Set Tag Set](https://docs.mongodb.com/manual/tutorial/configure-replica-set-tag-sets/)

Here's the TL;DR, the relevant rs config options expressed in Ruby:

```ruby
rsConfig = {
  :settings => {
    :getLastErrorModes    => { :twoack => { "primary-dc" => 2 } },
    :getLastErrorDefaults => { :w => :twoack, :j => true, :wtimeout => 500 }
  }
}
```

Here's the long version for those of you reading this in bed after a frustrating and unfruitful day at work trying to decipher and piece this together from the MongoDB manual...

First, as you no doubt learned from reading [Write Concern](https://docs.mongodb.com/manual/reference/write-concern/), `w:` can take `<number>`, `"majority"`, or `<tag set>`. At first I thought `"majority"` was a good idea but here's the problem:

> Requests acknowledgement that write operations have propagated to the majority of voting nodes, including the primary.

The key is "including the primary": this means the primary and all the DR secondaries could ack the write, leaving the primary DC secondaries useless at failover if they happened not to receive the latest writes. In short: `"majority"` is not DC-aware. A custom write concern is required for DC-aware write acks.

[Configure Replica Set Tag Set](https://docs.mongodb.com/manual/tutorial/configure-replica-set-tag-sets/) tells me how to write a custom write concern with a tag set. The key point in that doc is:

> The numeric value in the custom *getLastErrorModes* write concern refers to the number of _unique_ tag values (in the associated replica set tag) required to satisfy the write concern.

Where "_unique_" is emphasized (the blockquote above clobbers it). At first my inclination was to [configure the rs member tags](https://docs.mongodb.com/manual/tutorial/configure-replica-set-tag-sets/#add-tag-sets-to-a-replica-set) like `tags = {"dc": "primary"}` and `tags = {"dc": "secondary"}`. Seems logical, right? But it doesn't work because the tag I care about, `"dc": "primary"`, is only 1 unique value. What's needed is:

```javascript
"primary-dc": "node-01"
"primary-dc": "node-02"
"primary-dc": "node-03"
"dr-dc":      "node-04"
"dr-dc":      "node-05"
"dr-dc":      "node-06"
```

One of those tags on each of the corresponding members. Now there are 3 unique values for `primary-dc`, so the custom write concern `{ :twoack => { "primary-dc" => 2 } }` means writes must be acked by at least 2 unique `primary-dc` values, and since that tag is only on primary DC members, it does what I want.

To be fair, this is pretty well and clearly documented [here](https://docs.mongodb.com/manual/tutorial/configure-replica-set-tag-sets/#custom-multi-datacenter-write-concerns). Problem is: the docs for [w: \<tag set\>](https://docs.mongodb.com/manual/reference/write-concern/#w-option) don't link there. And [here](https://docs.mongodb.com/manual/reference/write-concern/#replica-sets) doesn't even mention `w: <tag set>`.

OK so we have the custom write concern doc/tag set we need. How do we use it? This is done in the [rs config](https://docs.mongodb.com/manual/reference/replica-configuration/) with options `getLastErrorModes` and `getLastErrorDefaults` as shown in the Ruby snippet above. I read this whole page, or so I thought because I glossed right over these options because their names having nothing to do with their functions. Here's how I'd rename them:

```
getLastErrorModes    ->  extendedWriteConcern
getLastErrorDefaults ->  defaultWriteConcern
```

Or maybe "custom" instead of "extended". Either way, the first option lets you define a custom write concern which is done with replica set tags. And the second option lets you set the default write concern, in which you set `w:` to the custom write concern.

In general, I find the [MongoDB Manual](https://docs.mongodb.com/manual/) to be well-written and thorough. Good job to whoever is managing and doing that work!
