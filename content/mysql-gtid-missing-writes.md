---
type: "page"
date: "2020-05-31"
title: "Missing Writes with MySQL GTID"
tags: ["mysql", "replication", "gtid"]
comments: true
aliases:
  - /post/mysql-gtid-missing-writes/
disqus_url: "https://hackmysql.com/post/mysql-gtid-missing-writes/"
---

[GTID-based replication](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids.html) makes managing replication topology easy: just [CHANGE MASTER](https://dev.mysql.com/doc/refman/8.0/en/change-master-to.html) to any node and voilà. It [doesn't always work]({{< ref "fixing-ghosted-gtids.md " >}}), but for the most part it does. That's great, but it can hide a serious problem: missing writes. Even when MySQL GTID-based replication says, "OK, sure!", which is most of the time, you should double check it.

<!--more-->

The problem begins when one MySQL node crashes and we fail over to another node. Every MySQL DBA should know that MySQL replication is asynchronous by default. Semi-sync replication requires explicit setup. Consequently, async replication means writes can and will be lost if not replicated before a crash.

Also important to remember: _[crash-safe replication]({{< ref "crash-safe-mysql-replication-a-visual-guide.md" >}}) only applies to MySQL crashes, not OS or hardware crashes_. MySQL can't be held responsible if the data center suddenly loses power.

Let's consider two diagrams below. The top one shows node 1 (active/writable) replicating to node 2 (or "node 2 is replicating _from_ node 1", if you prefer). Node 2 has not yet fetched node 1 writes 5 and 6. Write 5 is in flight, but not in node 2's relay log yet. Writes 3 and 4 are in the rely log, but 3 is being executed and 4 is being written, so neither are in node 2's binary logs yet. Everyone's happy.

![GTID Missing Writes](/img/gtid_missing_writes.svg)

Then node 1 crashes (maybe the server caught fire _just a little_) and comes back online. Thanks to GTID-based replication, you can easily make node 1 replicate from the new active node: node 2. But there's a problem: node 1 has two more writes than node 2: writes 5 and 6 (green) that never replicated to node 2 before node 1 combusted.

<mark>MySQL GTID only cares if the _replica_ is missing writes.</mark>

From the MySQL manual [17.1.3.3 GTID Auto-Positioning](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids-auto-positioning.html):

> The master responds by sending all transactions recorded in its binary log whose GTID is not included in the GTID set sent by the slave. ... sending the transactions with GTIDs that the slave is missing, and skipping the transactions that were in the GTID set sent by the slave. ... This exchange ensures that the master only sends the transactions with a GTID that the slave has not already received or committed.

Normally, replicas are behind and need to catch up, i.e. they are _misssing_ transactions. That's why the focus is on "GTID that the slave has not already received or committed".

Node 1 is not missing writes with respect to node 2; it has _more_ writes. In other words, node 2 has less writes than node 1, but again: MySQL GTID only cares if the _replica_ is missing writes, and node 2 is not the replica.

The insidious part of the problem is: you may never know and it may never cause a problem. Node 2 writes 5 and 6 (magenta) may or may not conflict with node 1 writes 5 and 6 (green). If they do, you'll know: replication will break on node 1. If they don't, you'll have unknown data drift which may or may not become a problem over time. (As far as I know, [pt-table-checksum](https://www.percona.com/doc/percona-toolkit/LATEST/pt-table-checksum.html) is still the only tool that can detect data drift.)

### But Should You?

When I said, "you can easily make node 1 replicate from the new active node: node 2", I glossed over a very important question: _Should you_ make node 1 replicate from node 2 after a non-MySQL crash? The safe answer is _no_.

The safe course of action is to rebuild node 1 (from a backup or clone from another node). But it _might_ be safe to replicate, and rebuilding can be slow (during which the cluster has reduced redundancy). These two realities combine to make the answer "yes", sometimes. In this case, you need to check for missing writes...

### Detecting Missing Writes with GTID

If you run the Bash script below on nodes 1 and 2 after the crash (bottom diagram) it will exit 1 and report that node 1 has more writes and that node 2 is missing writes `node1:5-6` (where `node1` is its UUID).

```bash
#!/bin/bash

DESCRIPTION="Exit 0 if node1 writes <= node2 writes."

set -eu

usage() {
  echo "usage: $0 [options] node1 node2"
  echo "      ${DESCRIPTION}"             1>&2
  echo "      -h      Print this help"    1>&2
  exit $1
}

while getopts "a" opt; do
  case "$opt" in
    h) usage 0 ;;
    *) usage 1 ;;
  esac
done

node1="$1"
node2="$2"

mysql -h $node1 -sse "SELECT @@hostname, @@server_uuid"
mysql -h $node2 -sse "SELECT @@hostname, @@server_uuid"

node1writes=$(mysql -h $node1 -sse "SELECT @@global.gtid_executed")
node2writes=$(mysql -h $node2 -sse "SELECT @@global.gtid_executed")

is_subset=$(mysql -h $node2 -sse "SELECT GTID_SUBSET('$node1writes', '$node2writes')")

if [[ "$is_subset" != "1" ]]; then
  missing_writes=$(mysql -h $node2 -sse "SELECT GTID_SUBTRACT('$node1writes', '$node2writes')")
  echo "$node1 has more writes than $node2, DO NOT REPLICATE!" >&2
  echo "$node2 is missing writes: $missing_writes" >&2
  exit 1
fi

echo "OK, $node1 writes are a subset of $node2 writes"
```

Read about the [GTID functions](https://dev.mysql.com/doc/refman/8.0/en/gtid-functions.html).

### Having More Writes

The last paragraph of [17.1.3.3 GTID Auto-Positioning](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids-auto-positioning.html) talks about the opposite problem: post-crash, node 2 having more node 1 writes than node 1 has in its own binary logs. In other words, node 1 is missing some of its own writes. As the paragraph notes, this can happen if `sync_binlog=1` is _not_ set.

As noted in the [GTID section of Crash-safe MySQL Replication]({{< ref "crash-safe-mysql-replication-a-visual-guide.md#gtid" >}}), `sync_binlog=1` is required (as is `innodb_flush_log_at_trx_commit=1`). Without these, we can have a case where, in the top diagram, node 1 write 6 (green) replicates and is applied by node 2 before it's persisted in node 1's binary logs. Then when node 1 replicates from node 2, we run into this problem: node 1 doesn't have it's own write 6 but node 2 does.

## Takeaway

If you use GTID replication, be careful when restarting replication on a crashed MySQL instance that was previously active (writable). The safest course of action is rebuilding the crashed instance. But if rebuild time compels you not to, be sure to check that all writes (transactions identified by GTID set) from the crashed instance were executed on the new active instance. If so, then it should be safe to replicate, but also run [pt-table-checksum](https://www.percona.com/doc/percona-toolkit/LATEST/pt-table-checksum.html) to verify.
