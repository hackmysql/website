---
type: "page"
date: "2019-04-12T09:00:00-04:00"
title: "Path and Dimension Metrics"
subtitle: "Strategies for identifying and organizing data points"
tags: ["metrics", "monitoring", "time series"]
comments: true
---
The two most common strategies for identifying and organizing data points that comprise metric time series are _path_ and _dimension_. This post is geared towards engineers who have never been introduced to the subject. Implementing metrics from the ground up, or adding new metrics to an existing system, can be overwhelming in nontrivial systems. Understanding these two strategies simplifies one's efforts.

## Path-based Metrics

Path-based metrics are the historical norm:

```none
host.prod1.disk-free.sda
host.prod1.disk-free.sdc
host.prod2.disk-free.sda
host.prod2.disk-free.sdc
```

Data points are identified by a path like the fully qualified path name of a file: `/home/brian/success.log`. Also like a file, the data point name has a separator character, usually `.` or `/`. So the examples above have four parts: `host` (fixed), a hostname (variable), `disk-free` (fixed), a drive (variable). Data points, like files, are uniquely identified by their _full_ path. For example, file "success.log" is not unique because it can exist in any directory. Likewise, "disk-free.sda" is not unique because it can apply to any host.

Paths are usually hierarchical (like file paths). The path layout is broad on the left and narrows to the right. `host` is very broad: there can be thousands of hosts. By the end, we have a specific metric, and it could be made even more specific by appending `.mount.root` to report the free space of a specific mount point. Also, some parts of the path are fixed and other variables. There are no rules or standards, but repeating `fixed.variable` pairs are common.

Path-based metrics are aggregated in metric and monitoring systems like `MIN(host.*.disk-free.*)`: report the minimum free disk space on all hosts and all disks. Path-based metric systems allow wildcards and pattern matching against the variable parts, which is how one selects particular metric time series. Consequently, a consistent, well designed path layout is key to using path metrics effectively.

**Pro**
Path-based metrics are self-describing and easier to grasp for two reasons. First, they mimic file paths which almost anyone who uses a computer is familiar with. Second, they map one-to-one to metric time series (MTS): each path-based data point produces an MTS. With path-based metrics you know what you're getting: `host.prod1.disk-free.sda` reports sda free space on prod1.

**Con**
Ironically, the biggest challenge with path-based metrics is determining the path layout. It's inflexible and never quite right. It's important to know that upfront. In nontrivial real-world systems, there are too many variables to encode in a single path layout. For example, what happens when we run the API in another data center or availability zone (AZ)? We would like `az.us-west.host.prod1.disk-free.sda`, but since data points are identified by their full path, that data point creates a new and different MTS even though it reports the same thing (sda free space on prod1).

In my experience, that challenge is significant and frequent enough to avoid path-based metrics. If a system's metrics are _very_ well defined and stable, then a suitable path layout might be possible. Even then, the metrics will probably be used by other systems, so the rigidity of the path layout is likely to impose itself on other systems&mdash;it doesn't play well with others. Consequently, newer metric and monitoring systems do not use path-based metrics. For the last several years, the state of the art has been dimension-based metrics.

## Dimension-based Metrics

Dimension-based metrics apply N-many "dimensions" to a single, globally unique data point. The previous example metrics can be expressed like:

```json
disk-free: {      // data point
  host:  "prod1"  // dimension
  disk:  "sda"    // dimension
  value: "400g"
}
disk-free: {
  host:  "prod1"
  disk:  "sdb"
  value: "500g"
}
disk-free: {
  host:  "prod2"
  disk:  "sda"
  value: "300g"
}
disk-free: {
  host:  "prod2"
  disk:  "sdb"
  value: "1g"
}
```

That's only a visual representation of dimension-based metrics. In real code, they can be expressed in structs, objects, encodings (e.g. JSON), and protocol/wire formats.

The two main features of dimension-based metrics are the data point name and the dimensions attached to it. The data point name stands alone and is implicitly globally unique. It should be a simple but descriptive noun for the data it measures: disk-free, 5m-load, net-util, http-500, connected-clients, etc. (I like "this-format", but "this_format" or "thisFormat" or any other format is fine; just be consistent.) The name should be globally unique. For example, do not have two "net-util" data points where one has a value in Mbps and the other in % utilization. Think of two different names instead.

Dimension-based metrics are uniquely identified by name, not dimensions. That seems wrong at first, but the difference that makes it right is this: metric time series are uniquely identified by dimensions. Whereas path-based metrics couple data point name and MTS, dimension-based metrics decouple these. The decoupling is the purpose and power and dimension-based metrics.

The example dimension-based metrics above create four metric time series because the dimensions&mdash;`host` and `disk`&mdash;have different values. Whereas the data point is the same for all (`disk-free`), an MTS is created for each unique combination of dimension values: "prod1, sda", "prod1, sdb", "prod2, sda", "prod2, sdb". You can think of dimensions as columns in a unique index. All dimensions are used, even if other data points don't specify them. For example, if we add `az: "us-west"` to the last data point, then the unique combination of dimension values becomes:

* prod1, sda, NULL
* prod1, sdb, NULL
* prod2, sda, NULL
* prod2, sdb, us-west

Where `NULL` (or `nil`, if you prefer) is an undefined value.

The `value` is not a dimension, it's the data point value for that dimension. There is often a `ts` field, too. In real code, the dimensions are probably a map, not mixed in with the real value and metavalues.

Dimension-based metrics are not hierarchical. The namespace is flat and global in every system I've seen. Aggregation and querying by metric and monitoring systems varies widely (querying dimension-based metrics in one system can be nothing like another system), but the gist is (pseudo-SQL):

```sql
SELECT MIN(disk-free) WHERE host=* AND disk=*
```

**Pro** Dimension-based metrics solve the challenges of path-based metrics. Adding new dimensions is easy and doesn't create a new data point, although it does create a new MTS. This flexibility is the primary benefit of dimension-based metrics, and it's significant because metrics, like code, tend to change often over time.

**Con** The biggest challenge with dimension-based metrics is being judicious with dimensions. Engineers are tempted to add a lot of dimensions because in the code it's just another key-value pair. That's fine for the source, but it complicates the sink (where metrics data is sent, stored, aggregated, queried, and visualized in charts). And if the sink is a paid service like [SignalFx](https://www.signalfx.com/), it can be a costly challenge.

Dimension-based metrics are the modern norm. I'm not aware of any new metric or monitoring systems within the last several years that use path-based metrics. Today, dimensions-based metrics are the best choice.

## MTS Explosion

Both strategies are susceptible to an "MTS explosion": programmatically creating new metric time series by using a random or unbounded value in the path or dimensions. For example, a request UUID is added to the "http500" metric for tracing and debugging:

```none
app.myAPI.host.prod1.http500.request-id.24cffc51-b82e-431e-a3ac-f3e3f3133915
```

```json
http500: {
  app:       "myAPI"
  host:      "prod1"
  requestId: "24cffc51-b82e-431e-a3ac-f3e3f3133915"
}
```

In the first case, `app.myAPI.host.prod1.http500.request-id.*` generates countless data points and MTS. There is no solution (i.e. a way to encode the request ID with the data point) because path-based metrics tightly couple data point and MTS.

In the second case, the `requestId` generates countless dimensions (but still only one data point). The solution depends on the metric systems (source and sink). Some systems allow non-dimensional key-value pairs (tags, labels, attributes&mdash;terms vary); this is what `requestId` should be.

MTS explosions are common. Expect them to happen, but try hard to avoid them because in large environments that pay for hosted metrics, MTS explosions can be very expensive.
Including any kind of randomly generated ID or value in the metric path or dimensions is a telltale sign of an impending MTS explosion.
