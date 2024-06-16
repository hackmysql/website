---
date: "2021-09-02T18:11:00-04:00"
title: "MySQL LRU Flushing and I/O Capacity"
tags: ["mysql", "innodb", "lru-flushing", "io-capacity"]
comments: true
aliases:
  - /post/mysql-lru-flushing-io-capacity/
disqus_url: "https://hackmysql.com/post/mysql-lru-flushing-io-capacity/"
---

InnoDB background LRU list flushing is _not_ limited by [`innodb_io_capcity`](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html#sysvar_innodb_io_capacity) or [`innodb_io_capacity_max`](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html#sysvar_innodb_io_capacity_max).
I'll prove it in this blog post, but since MySQL experts disagree (or don't know for sure), I'd like you to prove me wrong.
This is not an intro; you'll need to know all the InnoDB details wrt page flushing.

<!--more-->

## Setup

Running <em>8.0.26-debug MySQL Community Server - GPL - Debug</em> on Ubuntu 21.04 (via Docker).


my.cnf:

```ini
[mysqld]

#
# Super low IO caps
#
innodb-io-capacity=200
innodb-io-capacity-max=400

#
# One page cleaner and double than default LRU scan depth
# One "pc" ensures that all IO is due to the one pc
#
innodb_page_cleaners=1
innodb_lru_scan_depth=2048

#
# Big log so checkpoint age is not an issue
# Little to no adapative/flush list flushing
#
innodb_log_file_size=128M

#
# Disable stuff we don't need/avoid extra writes
#
innodb-flush-sync=0
innodb-doublewrite=0
skip-log-bin
skip-innodb-adaptive-hash-index

#
# I like metrics
#
innodb_monitor_enable=module_buffer,module_log,module_trx
```

InnoDB buffer pool size is default: 128M.

Use [sysbench](https://github.com/akopytov/sysbench) to create a table with one million rows.

A silly little Go program to report IOPS and page flush rates:

```go
package main

import (
    "context"
    "database/sql"
    "log"
    "time"

    _ "github.com/go-sql-driver/mysql"
)

func main() {
    db, err := sql.Open("mysql", "root:test@tcp(127.0.0.1:3306)/")
    if err != nil {
        log.Fatal(err)
    }
    if err := db.Ping(); err != nil {
        log.Fatal(err)
    }

    q := "SELECT name, count FROM information_schema.innodb_metrics WHERE name IN ('os_data_reads','os_data_writes','buffer_flush_adaptive_total_pages','buffer_LRU_batch_flush_total_pages','buffer_flush_background_total_pages')"
    var pr, pw, pl, plru, pbg int

    t := time.NewTicker(1 * time.Second)
    for range t.C {
        var reads, writes, list, lru, bg int
        rows, err := db.QueryContext(context.Background(), q)
        if err != nil {
            log.Fatal(err)
        }
        for rows.Next() {
            var name string
            var val int
            if err := rows.Scan(&name, &val); err != nil {
                log.Fatal(err)
            }
            switch name {
            case "os_data_reads":
                reads = val
            case "os_data_writes":
                writes = val
            case "buffer_flush_adaptive_total_pages":
                list = val
            case "buffer_LRU_batch_flush_total_pages":
                lru = val
            case "buffer_flush_background_total_pages":
                bg = val
            default:
                log.Fatalf("unknown var %s", name)
            }
        }
        rows.Close()

        log.Printf("read = %4d  write = %4d | list = %4d  LRU = %4d  bg = %4d",
            reads-pr, writes-pw, list-pl, lru-plru, bg-pbg)

        pr = reads
        pw = writes
        pl = list
        plru = lru
        pbg = bg
    }
}
```

## Few Free Pages but Many Dirty Pages

Since the page cleaners are _background_ threads, you normally can't disable them.
But with a debug build of MySQL, you can:

```sql
SET GLOBAL innodb_page_cleaner_disabled_debug=1;
```

This proof would be nearly impossible without that switch because, normally, the page cleaners will keep free pages at or near [`innodb_lru_scan_depth`](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html#sysvar_innodb_lru_scan_depth), which means you can't cause big LRU flushes.

But with the page cleaner disabled (normally, there are 4 page cleaners by default, by see my.cnf above: I configured only 1 page cleaner for this proof), you can nearly fill the buffer pool with unflushed dirty pages:

```
mysql> UPDATE sbtest2 SET c='a' WHERE id < 500000;
Query OK, 400000 rows affected (36.11 sec)
Rows matched: 499999  Changed: 400000  Warnings: 0
```

The query doesn't matter.
What matters is that it creates many dirty pages:

```
mysql> SELECT name, count FROM innodb_metrics WHERE name LIKE 'buffer_pool_pages_%';
+-------------------------+-------+
| name                    | count |
+-------------------------+-------+
| buffer_pool_pages_total |  8192 |
| buffer_pool_pages_misc  |     0 |
| buffer_pool_pages_data  |  8128 |
| buffer_pool_pages_dirty |  5685 |
| buffer_pool_pages_free  |    64 |
+-------------------------+-------+
```

This is the weird situation needed to prove that LRU flushing does not use I/O capacities: significantly more dirty pages and LRU scan depth than max I/O, but almost no free pages to make LRU flushing kick in and work at peak rate.
And that's the crux of the test: is the peak rate of LRU flushing `innodb_io_capacity_max` or `innodb_lru_scan_depth`?
If it's the former (`innodb_io_capacity_max`), then LRU flushing will proceed in batches of (roughly) that many pages, especially since `innodb_flush_sync = 0`.
But if it's the latter (`innodb_lru_scan_depth`), then LRU flushing will proceed in a batch of (roughly) that many pages, which is greater than max I/O capacity.

## LRU Flush Greater Than Max I/O Capacity

Run the Go program (above), enable MySQL debugging/tracking, then enable the page cleaner:

```
mysql> SET GLOBAL DEBUG='d:t:i:o,/tmp/mysqld.trace:F:L';
Query OK, 0 rows affected (0.00 sec)

mysql> SET GLOBAL innodb_page_cleaner_disabled_debug=0;
Query OK, 0 rows affected (0.06 sec)
```

The trace file confirms:

```
# grep 'flush 0' mysqld.trace
 ?file:  1986: ib_buf: flush 0 completed, 1178 pages
 ?file:  1986: ib_buf: flush 0 completed, 0 pages
```

"flush 0" is LRU flushing. ("flush 1", not shown, is adaptive/LSN/flush list flushing.)

Also in the trace file:

```
 ?file:  1998: ib_buf: flush completed, from flush_list 122 pages, from LRU_list 1178 pages
```

The rates from the Go program match perfectly, affirming the trace data through other metrics:

```none
2021/09/02 14:09:49 read =    0  write =    0 | list =    0  LRU =    0  bg =    0
2021/09/02 14:09:50 read =    0  write =    0 | list =    0  LRU =    0  bg =    0
2021/09/02 14:09:51 read =    0  write =    0 | list =    0  LRU =    0  bg =    0
2021/09/02 14:09:52 read =    0  write = 1300 | list =  122  LRU = 1178  bg =    0
2021/09/02 14:09:53 read =    0  write =    1 | list =    0  LRU =    0  bg =    0
2021/09/02 14:09:54 read =    0  write =  200 | list =    0  LRU =    0  bg =  200
2021/09/02 14:09:55 read =    0  write =  201 | list =    0  LRU =    0  bg =  200
2021/09/02 14:09:56 read =    0  write =  201 | list =    0  LRU =    0  bg =  200
```

First 3 lines were before the page cleaner was re-enabled: zero activity.

Fourth line is the proof: 1,178 pages flushed at 1,3000 write IOPS.

In the latter lines, the configured background flush rate is observed: 200.

## Quick Source Code Analysis

Background page flushing happens in `storage/innobase/buf/buf0flu.cc`.

Flushing (both list and LRU) starts in function `pc_flush_slot()`:

```cpp
2979     /* Flush pages from end of LRU if required */
2980     slot->n_flushed_lru = buf_flush_LRU_list(buf_pool);
2981 
2982     lru_tm = ut_time_monotonic_ms() - lru_tm;
2983     lru_pass++;
2984 
2985     if (!page_cleaner->is_running) {
2986       slot->n_flushed_list = 0;
2987       goto finish;
2988     }
2989 
2990     /* Flush pages from flush_list if required */
2991     if (page_cleaner->requested) {
2992       list_tm = ut_time_monotonic_ms();
2993 
2994       slot->succeeded_list =
2995           buf_flush_do_batch(buf_pool, BUF_FLUSH_LIST, slot->n_pages_requested,
2996                              page_cleaner->lsn_limit, &slot->n_flushed_list);
2997 
2998       list_tm = ut_time_monotonic_ms() - list_tm;
2999       list_pass++;
3000     } else {
3001       slot->n_flushed_list = 0;
3002       slot->succeeded_list = true;
3003     }
```

(Line numbers added.)

In function `buf_flush_LRU_list()`:

```cpp
2267   /* Currently one of page_cleaners is the only thread
       that can trigger an LRU flush at the same time.
       So, it is not possible that a batch triggered during
       last iteration is still running, */
2271   buf_flush_do_batch(buf_pool, BUF_FLUSH_LRU, scan_depth, 0, &n_flushed);
```

And there it is: `scan_depth`.
If you continue following the code, you'll see that nothing attenuates `scan_depth` (the argument changes changes; ironically, in some functions the argument is `min` and in others it's `max`&mdash;MySQL source code is veritable jungle).

## I/O Capacity Max

As expected and understood by everyone in the rarefied world of InnoDB internals, the adaptive flushing algorithm uses and limits flush list flushing to [`innodb_io_capcity`](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html#sysvar_innodb_io_capacity) or [`innodb_io_capacity_max`](https://dev.mysql.com/doc/refman/8.0/en/innodb-parameters.html#sysvar_innodb_io_capacity_max).

Back in `pc_flush_slot()`:

```cpp
2994       slot->succeeded_list =
2995           buf_flush_do_batch(buf_pool, BUF_FLUSH_LIST, slot->n_pages_requested,
2996                              page_cleaner->lsn_limit, &slot->n_flushed_list);
```

Argument `slot->n_pages_requested` is set by the adaptive flushing algorithm.
And you'll notice it's the same lower-level function call that LRU flushing uses: `buf_flush_do_batch()`.

## Quick Historical Analysis

Is LRU flushing supposed to be limited by configured I/O capacity?
Was it ever?
If yes, when did it stop?
Down the rabbit hole of history!

In function `buf_flush_LRU_list_batch()`:

```cpp
1832   /* We keep track of all flushes happening as part of LRU
       flush. When estimating the desired rate at which flush_list
       should be flushed, we factor in this value. */
1835   buf_lru_flush_page_count += count;
```

That code comment is very old and it's wrong: we do _not_ keep track of this any longer&mdash;we haven't for a very long time.
`buf_lru_flush_page_count` is not used anywhere: it's incremented here, but never used.

This variable was last used in 5.5.
As of 5.6, it stopped being used (aside from being incremented).
A single page cleaner thread was introduced in 5.6 (and expanded to multiple page cleaner threads in 5.7), so this makes some sense: if LRU flush was ever supposed to be limited or capped by I/O capacity, this functionality was lost in the big page cleaner implementation from 5.5 to 5.6.

The related MySQL worklogs are:

* [WL#5579: Add 'page_cleaner' a separate thread to flush dirty pages](https://dev.mysql.com/worklog/task/?id=5579)
* [WL#5580: changes to LRU flushing](https://dev.mysql.com/worklog/task/?id=5580)
* [WL#6642: InnoDB: multiple page_cleaner threads](https://dev.mysql.com/worklog/task/?id=6642)

## Why Nobody Notices or Cares

Default LRU scan depth is 1024 which is less than the default I/O max capacity 2000.
With 4 page cleaners by default, that's 4 * 1024 = 4,096 LRU page flushes max.
But this is _very unlikely_, perhaps impossible because the buffer pool starts with free pages and the page cleaners maintain free pages.
As shown in section [Few Free Pages but Many Dirty Pages]({{< ref "#few-free-pages-but-many-dirty-pages" >}}), it's quite difficult to get MySQL/InnoDB into a state where there are very few free pages but a significant number of dirty pages.
The whole point of page flushing is to avoid this.
(That's not the _whole_ point, but you know what I mean.)

Moreover, the general best practice is to reduce `innodb_lru_scan_depth`, especially when there are many buffer pool instances.
Let's say we reduce it to 512, then 512 * 4 = 2,048 LRU page flushes max, which is essentially the default max I/O capacity.
Moreover again, the max I/O capacity is likely to be higher on mid- to high-end hardware.

It's difficult to imagine a real application workload that would cause the LRU flushing rate to be noticed, let alone a problem in terms of exceeding the configured max I/O rate.
Nevertheless, this blog post proves that LRU flushing does not use and is not limited by `innodb_io_capcity` or `innodb_io_capacity_max`; instead, it flushes up to `innodb_lru_scan_depth` pages per page cleaner thread, but it is very unlikely&mdash;almost impossible&mdash;that this would cause any noticeable or problematic background I/O usage.
