---
type: "page"
date: "2019-12-15"
title: "Fixing Ghosted GTIDs"
subtitle: "When MySQL GTID auto-positioning fails"
tags: ["mysql", "replication", "gtid", "auto-pos"]
comments: true
aliases:
  - /post/fixing-ghosted-gtids/
disqus_url: "https://hackmysql.com/post/fixing-ghosted-gtids/"
---

[MySQL auto-positioning](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids-auto-positioning.html) is an integral part of replication with GTID, but it's neither required nor guaranteed to work. It's possible to enable GTIDs but disable auto-positioning, and it's possible that one MySQL instance cannot auto-position on another even when GTIDs are used. The former (GTID on but auto-pos off) is an issue for another time. The latter is the topic of this post: when MySQL GTID auto-positioning fails&mdash;and how to fix it.

Quick background: I recently fixed a handful of clusters (running MySQL 5.6) which had one or more replica with `Master_Auto_Position=OFF`, but all using GTIDs. Worse, some replicas could not auto-pos on other replicas, breaking with this error in `SHOW SLAVE STATUS` when `CHANGE MASTER TO MASTER_AUTO_POSITION=1` was attempted:

> Last_IO_Error: Got fatal error 1236 from master when reading data from binary log: 'The slave is connecting using CHANGE MASTER TO MASTER_AUTO_POSITION = 1, but the master has purged binary logs containing GTIDs that the slave requires.'

That error, while accurate, isn't helpful because it doesn't say _which_ GTIDs are missing. According to the [MySQL manual](https://dev.mysql.com/doc/refman/5.7/en/replication-gtids-auto-positioning.html), as of 5.7 the missing GTIDs are logged in the master's error. (In my opinion, that's the wrong place to log them. The error happens on the replica, so the missing GTIDs should be logged on the replica.) But I was fixing 5.6 instances, so the missing GTIDs weren't logged anywhere. Here's a little script that uses `GTID_SUBTRACT()` to print the missing GTIDs if the first node (arg) cannot auto-position on the second:

```bash
#!/bin/bash

DESCRIPTION="Exit 0 if node1 can auto-position on node2."

set -eu

usage() {
  echo "usage: $0 [options] node1 node2"
  echo "      ${DESCRIPTION}"                                           1>&2
  echo "      -a      Enable auto-pos if node1 can auto-post on node2 " 1>&2
  echo "      -h      Print this help"                                  1>&2
  exit $1
}

ENABLE_AUTO_POS=""

while getopts "a" opt; do
  case "$opt" in
    a) ENABLE_AUTO_POS="yes"
       shift
       ;;
    h) usage 0 ;;
    *) usage 1 ;;
  esac
done

node1="$1"
node2="$2"

gtid_purged=$(mysql -h $node2 -sse "SELECT @@global.gtid_purged")
gtid_missing=$(mysql -h $node1 -sse "SELECT GTID_SUBTRACT('$gtid_purged', @@global.gtid_executed)")

if [[ "$gtid_missing" ]]; then
  echo "$node1 cannot auto-position on $node2, missing GTID sets $gtid_missing" >&2
  exit 1
fi

if [[ $ENABLE_AUTO_POS ]]; then
  echo "OK, $node1 can auto-position on $node2, enabling..."
  mysql -h $node1 -e "STOP SLAVE; CHANGE MASTER TO MASTER_AUTO_POSITION=1; START SLAVE;"
  sleep 1
  mysql -h $node1 -e "SHOW SLAVE STATUS\G"
  echo "Auto-position enabled on $node1. Verify replica is running in output above."
else
  echo "OK, $node1 can auto-position on $node2. Use option -a to enable, or execute:"
  echo "    mysql -h $node1 -e \"STOP SLAVE; CHANGE MASTER TO MASTER_AUTO_POSITION=1; START SLAVE;\""
  echo "    mysql -h $node1 -e \"SHOW SLAVE STATUS\G\""
fi
```

Let's say we want `node2` to replicate from `node1` with auto-positioning. `SHOW SLAVE STATUS` on each node reports the following `Executed_Gtid_Set` values:

```
node1: 7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052064794-5054955706

node2: 7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052104638-5054955706
```

Can `node2` replicate from `node1` with auto-pos? (In other words, can't `node2` auto-pos on `node1`?) The answer is "no", and the script above would print:

> node2 cannot auto-position on node1, missing GTID sets 7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052064794-5052104637"

GTID sets can be overwhelming to humans because they're large, long sets. (See [MySQL bug #92836](https://bugs.mysql.com/bug.php?id=92836).) Let's highlight the difference in the GTIDs sets above:

node1: 7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052<mark>064794</mark>-5054955706

node2: 7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052<mark>104638</mark>-5054955706

The first part of node2's GTID is greater (104638 > 064794) which means node2 has _less_ GTIDs than node1. If that sounds confusing, here's why: GTIDs are sequentially numbered transactions. Let's simplify:

node1: 1-10

node2: 5-10 

node1 has ten transactions: 1 through 10. node2 has only six transactions: 5 through 10; it's missing transactions 1 through 4

The real node2 above is missing transactions 5052064794 through 5052104637, as the script would print. Consequently, when node2 attempts to auto-position on node1, it tries to fetch the missing GTIDs from node1 but fails because node1 has already purged them from its binary logs. This causes replication error "Last_IO_Error: Got fatal error 1236 from master ..." on node2.

## Ghosted GTIDs

Here's the strange thing: why is node2 missing GTIDs at the start or middle of the set? Using the simplified sets again, how did node2 execute transactions 5-10 but miss 1-4? Presumably, if node2 is identical to node1 despite missing GTIDs 1-4 (which you can verify with [pt-table-checksum](https://www.percona.com/doc/percona-toolkit/LATEST/pt-table-checksum.html)), then node2 either has the changes from 1-4 or those changes were overwritten by 5-10. I don't know how or why this situation arises (probably due to cloning new replicas to replace failed ones in combination with purging binary logs), but I call these types of missing and nonrecoverable GTIDS "ghosted GTIDs".

Before showing how to fix ghosted GTIDs, it's *extremely important* to decided if it's safe to ignore the missing GTIDs. If unsure, or if the one node is not already replicating from the other, err on the side of caution and re-clone the node. Don't risk messing around with GTID sets unless you're sure. If one node is replicating from the other, use [pt-table-checksum](https://www.percona.com/doc/percona-toolkit/LATEST/pt-table-checksum.html) to verify that they're in sync and identical. If true, then the fix is safe.

## The Fix

GTIDs are stored in binary logs because these (bin logs) are the only official, source-of-truth record of changes. (Configure MySQL with `sync_binlog = 1`!) Consequently, bin logs and global variables `gtid_purged` and `gtid_executed` are linked. To fix ghosted GTIDs, we need to rewrite `gtid_executed` which means we need to `RESET MASTER` to purge the binary logs. In effect, we're telling MySQL to forget the past and let us rewrite history.

***WARNING***: `RESET MASTER` breaks downstream replicas!

Because of that warning, the first step is to isolate the node to fix. Continuing the example above, this means isolating node2 so that nothing replicates from it. For example, if node3 was replicating from node2, we would need to make node3 replicate from node1, else the fix on node2 would break node3 and we would have to re-clone node3 after fixing node2.

Once the node to fix is isolated (it's a standalone replica with nothing replicating from it), execute:

```sql
-- All on replica to fix...

STOP SLAVE;

-- Be sure replication has stopped applying changes
-- (usually instantaneous unless SQL thread is very busy)

SHOW SLAVE STATUS\G

-- Copy-paste full value of Executed_Gtid_Set to a text editor

RESET MASTER;
SET GLOBAL gtid_executed='<see below>'

CHANGE MASTER TO MASTER_AUTO_POSITION=1;

RESET SLAVE; -- forget position because we're about to auto-position...

START SLAVE;

SHOW SLAVE STATUS\G

-- Verify replication is OK
```

`<see below>` is the copy-pasted value from `Executed_Gtid_Set` rewritten to include the missing GTID sets. For example, from node2 we copy-paste `7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052104638-5054955706` which has three parts:

```js
server UUID  = 7b07bfca-d4d9-11e5-b97a-fe46eb913463
first trx ID = 5052104638
last trx ID  = 5054955706
```

The missing GTID set is `7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052064794-5052104637`, also three parts:

```js
server UUDID      = 7b07bfca-d4d9-11e5-b97a-fe46eb913463
missing trx begin = 5052064794
missing trx end   = 5052104637
```

The rewritten GTID set is `server UUID:missing trx begin-last trx ID`, which is `7b07bfca-d4d9-11e5-b97a-fe46eb913463:5052064794-5054955706`. Be sure to rewrite the GTID sets for all server UUIDs with missing GTIDs. This example shows only one server UUID, but there can be many, even for server UUIDs that no longer exist.

Before rewriting history, node2 started with transaction (trx) ID 5,052,104,638. But node1 has earlier transactions that it can't send to node2 because they're already purged from the binary logs on node1. So we rewrote node2's history to match node1's history: node2 starts with trx ID 5,052,064,794, same as node1. Now when node2 attempts to auto-pos on node1, there won't be any missing GTIDs because they start with the same trx ID.
