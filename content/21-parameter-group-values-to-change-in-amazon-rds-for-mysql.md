---
date: "2020-06-29T11:15:00-03:00"
title: "21 Parameter Group Values to Change in Amazon RDS for MySQL"
tags: ["mysql", "aws", "sysvar", "parameter-group"]
comments: true
aliases:
  - /post/21-parameter-group-values-to-change-in-amazon-rds-for-mysql/
disqus_url: "https://hackmysql.com/post/21-parameter-group-values-to-change-in-amazon-rds-for-mysql/"
params:
  path: cloud
---

[Amazon RDS for MySQL](https://aws.amazon.com/rds/mysql/) uses many default values for system variables, but it also sets a few "sys vars" with different values. As with any database, neither product (MySQL) nor provider (AWS) defaults can best suite all use cases. It's our responsibility to carefully review and set every important system variable. This is tedious and difficult, but I've done it for you.

Below are are 21 MySQL 5.7 system variables that I recommend changing by creating a new [parameter group](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html). This presumes new RDS instances; some of these sys vars cannot be changed easily after provisioning MySQL. This only applies to RDS for MySQL, _not_ Amazon Aurora.

For each of the 21 MySQL system variables, the MySQL 5.7 default is listed, followed by the Amazon RDS default, followed by my recommended value. For brevity, &dagger; = AWS does not specify a value, it defaults to the MySQL 5.7 default value.

## Binary Log

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | --------- |
| [binlog_cache_size](https://dev.mysql.com/doc/refman/5.7/en/replication-options-binary-log.html#sysvar_binlog_cache_size) | 32768 | 32768 | 512000 |
| [binlog_format](https://dev.mysql.com/doc/refman/5.7/en/replication-options-binary-log.html#sysvar_binlog_format) | ROW | MIXED | ROW |
| [binlog_row_image](https://dev.mysql.com/doc/refman/5.7/en/replication-options-binary-log.html#sysvar_binlog_row_image) | full | &dagger; | minimal |

`binlog_cache_size`:  The MySQL 5.7 (and AWS) default 32K is probably too low with row-based replication (RBR). With statement-based replication (SBR), you can delete a millions rows with a single binary log event: a single DELETE statement. But with RBR, you get a million binlog events. Consequently, `binlog_cache_size` can seriously impact performance because binlog changes that don't fit in memory are written to disk, which is very slow by comparison. Combine with `binlog_row_image = full` and 32K is almost guaranteed to be too small.

Monitor [binlog_cache_disk_use](https://dev.mysql.com/doc/refman/5.7/en/server-status-variables.html#statvar_Binlog_cache_disk_use) to know if this happens too frequently. "Too frequently" means "when it correlates with degraded performance". A value of 512K is a better start. This cache is allocated per connection, so don't increase it beyond what's measurably necessary.

`binlog_format`: Row-based replication (RBR) is the standard. Eight years ago (2012) when [High Performance MySQL, 3rd Edition](https://www.oreilly.com/library/view/high-performance-mysql/9781449332471/) was published, the consensus was,

> In theory, row-based replication is probably better all-around, and in practice it generally works fine for most people.

Today, RBR is proven and reliable; it is no longer theory. The session variable is dynamic, so it can be changed only when and where needed.

`binlog_row_image`: The MySQL 5.7 default `full` makes sense as a product default because it works for everything (e.g. binlog tailers), but `minimal` is a much better default for performance because it's better to replicate only what's needed. On write-intensive tables with BLOB columns, `minimal` can significantly increase replication throughput and avoid slow `binlog_cache_disk_use`.

## Character Set

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | --------- |
| [character_set_server](https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_character_set_server) | latin1 | &dagger; | utf8mb4 | ... |
| [init_connect](https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_init_connect) | &nbsp; | &dagger; | SET NAMES utf8mb4 | ... |
| [skip-character-set-client-handshake](https://dev.mysql.com/doc/refman/5.7/en/server-options.html#option_mysqld_character-set-client-handshake) | 0 | &dagger; | 1 | ... |

Welcome to the 21st century: we have emoji. In MySQL 8.0 the default is utf8mb4, so it's good planning for the future to set your 5.7 default to utf8mb4, too.

The latter two might be controversial because they effectively disregard the client and force utf8mb4. This somewhat extreme approach is reaction to character sets often being a point of confusion, and sometimes a point of pain if not handled properly. The confusion and pain result from MySQL having several "levels" of charsets (e.g. server vs. table) combined with different clients doing different things. End result: I have never met a DBA or software developer who knew with certainty how all the character sets were configured. But with this configuration we can be quite certain: it's all utf8mb4&mdash;just utf8mb4.

## GTID

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | --------- |
| [enforce_gtid_consistency](https://dev.mysql.com/doc/refman/5.7/en/replication-options-gtids.html#sysvar_enforce_gtid_consistency) | OFF | &dagger; | ON | ... |
| [gtid_mode](https://dev.mysql.com/doc/refman/5.7/en/replication-options-gtids.html#sysvar_gtid_mode) | OFF | OFF_PERMISSIVE | ON_PERMISSIVE | ... |

GTID-based replication is the standard. (Operationally, it's still a little rough in 5.7, but no one misses classic binlog file:pos coordinates.) Ideally, we would set `gtid_mode = ON`, but the manual says,

> Changes from one value to another can only be one step at a time.

Consequently, RDS fails to provision if `gtid_mode = ON`. Instead, set `gtid_mode = ON_PERMISSIVE` then immediately post-provision change to `ON`.

## InnoDB

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | --------- |
| [innodb_flush_log_at_trx_commit](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_flush_log_at_trx_commit) | 1 | &dagger; | 1 | ... |
| [innodb_flush_neighbors](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_flush_neighbors) | 1 | &dagger; | 0 | ... | 
| [innodb_log_buffer_size](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_log_buffer_size) | 16777216 | 8388608 | 16777216 | ... |
| [innodb_log_file_size](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_log_file_size) | 50331648 | 134217728 | 268435456 | ... |

`innodb_flush_log_at_trx_commit`: This variable is so important, it's worth explicitly settings to `1` to show that it was not overlooked. `innodb_flush_log_at_trx_commit = 1` is the "D" in [ACID](https://en.wikipedia.org/wiki/ACID). [High Performance MySQL, 3rd Edition](https://www.oreilly.com/library/view/high-performance-mysql/9781449332471/) said,

> Setting innodb_flush_log_at_trx_commit to anything other than 1 can cause you to lose transactions. However, you might find the other settings useful if you don't care about durability (the D in ACID).

`innodb_flush_neighbors`: Flushing dirty neighbor pages was a performance benefit with spinning disks. But with [AWS gp2 and io1](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html) (never use "magnetic" for RDS) we presume it's no longer needed. However, gp2 is not direct-attached storage, so we don't know for sure what affect this variable has.

`innodb_log_buffer_size`: The MySQL 5.7 default 16MB is the standard. Interestingly, the AWS default 8MB is the MySQL _5.6_ default. Perhaps this was an oversight?

`innodb_log_file_size`: The MySQL 5.7 default 48MB is almost certainly way too small. The AWS default 128MB is much better. But 256MB is an even better default and still probably too low. A proper value is difficult to compute. Percona had this to say:

* [Choosing proper innodb_log_file_size](https://www.percona.com/blog/2006/07/03/choosing-proper-innodb_log_file_size/)
* [What is a big innodb_log_file_size?](https://www.percona.com/blog/2016/05/31/what-is-a-big-innodb_log_file_size/)
* [How to Choose the MySQL innodb_log_file_size](https://www.percona.com/blog/2017/10/18/chose-mysql-innodb_log_file_size/)

TL;DR: there's no single, correct answer. I suggest starting at 256MB, measure and adjust as needed.

## Performance Schema

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | --------- |
| [performance_schema](https://dev.mysql.com/doc/refman/5.7/en/performance-schema-system-variables.html#sysvar_performance_schema) | ON | OFF | ON | ... |

The [Performance Schema](https://dev.mysql.com/doc/refman/5.7/en/performance-schema.html) is an incredibly important source of performance insights. It should always be enabled.

## Replication

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | --------- |
| [master-info-repository](https://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html#sysvar_master_info_repository) | FILE | TABLE | TABLE | ... |
| [relay_log_info_repository](https://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html#sysvar_relay_log_info_repository) | FILE | TABLE | TABLE | ... |
| [sync_master_info](https://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html#sysvar_sync_master_info) | 10000 |  &dagger; | 0 | ... |
| [sync_relay_log](https://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html#sysvar_sync_relay_log) | 10000 |  &dagger; | 0 | ... |
| [sync_relay_log_info](https://dev.mysql.com/doc/refman/5.7/en/replication-options-slave.html#sysvar_sync_relay_log_info) |  10000 |  &dagger; | 0 | ... |

Set these variables for [Crash-safe MySQL Replication]({{< ref "crash-safe-mysql-replication-a-visual-guide.md#gtid" >}}) and performance. `relay_log_recovery = ON` is also required, which is the non-modifiable AWS default.

## Time Zone

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | --------- |
| [time_zone](https://dev.mysql.com/doc/refman/5.7/en/server-system-variables.html#sysvar_time_zone) | SYSTEM | &dagger; | UTC | ... |

Like character sets, time zones can be a point of confusion and sometimes pain. Point in case: how do `TIMESTAMP` and `DATETIME` columns differ with respect to time zone? The best practice is to use UTC&mdash;and only UTC&mdash;with MySQL (or any database). Time zones are a presentation issue: do everything in UTC, and convert to a time zone immediately before and after user input/output.

## InnoDB IO Capacity

| Parameter         | MySQL 5.7 | AWS | Recommended |
| ----------------- | --------- | --- | ----------- |
| [innodb_io_capacity](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_io_capacity) | 200 | &dagger; | (See table below) |
| [innodb_io_capacity_max](https://dev.mysql.com/doc/refman/5.7/en/innodb-parameters.html#sysvar_innodb_io_capacity_max) | 2000&Dagger; | &dagger; | (See table below) |

<small>&Dagger; "If you specify an innodb_io_capacity setting at startup but do not specify a value for innodb_io_capacity_max, innodb_io_capacity_max defaults to twice the value of innodb_io_capacity, with a minimum value of 2000." https://dev.mysql.com/doc/refman/5.7/en/innodb-configuring-io-capacity.html</small>

I saved the most complicated for last: `innodb_io_capacity` and `innodb_io_capacity_max`. These system variables are important, but it might surprise you to know that there's little to no consensus on proper values. For example, [High Performance MySQL, 3rd Edition](https://www.oreilly.com/library/view/high-performance-mysql/9781449332471/) wrote,

> You can also increase the innodb_io_capacity option to between 2000 and 20000, depending on the IOPS your device can actually perform.

It said nothing about `innodb_io_capacity_max`. A little later, in 2015 [MySQL expert Aurimas Mikalauskas](https://www.speedemy.com/17-key-mysql-config-file-settings-mysql-5-7-proof/) wrote:

> Best solution – measure random write throughput of your storage and set innodb_io_capacity_max to the maximum you could achieve, and innodb_io_capacity to 50-75% of it, especially if your system is write-intensive.

In January 2019, [Saikat Banerjee, Database Specialist Solutions Architect at AWS](https://aws.amazon.com/blogs/database/best-practices-for-configuring-parameters-for-amazon-rds-for-mysql-part-1-parameters-related-to-performance/), wrote:

> For I/O-intensive systems, a value of 1,000 usually works. We don’t recommend an extreme value like 20,000 unless you have already proved that a lower value is not sufficient.

And more recently, in December 2109 [Yves Trudeau and Francisco Bordenave, MySQL experts at Percona](https://www.percona.com/blog/2019/12/18/give-love-to-your-ssds-reduce-innodb_io_capacity_max/), wrote:

> Simply overshooting the values of innodb_io_capacity and innodb_io_capacity_max is not optimal for performance.

Add to those MySQL manual section [14.8.8 Configuring InnoDB I/O Capacity](https://dev.mysql.com/doc/refman/5.7/en/innodb-configuring-io-capacity.html) which contains this gem:

> Ideally, keep [innodb_io_capacity] as low as practical, but not so low that background activities fall behind. If the value is too high, data is removed from the buffer pool and change buffer too quickly for caching to provide a significant benefit. 

_But wait, there's more!_

All information about InnoDB IO performance presumes direct-attached storage, unless explicitly stated otherwise; but [Amazon RDS storage](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html) uses Amazon EBS which is _not_ direct-attached storage and has two options: gp2 and io1. (There's a third option: magnetic. Never use magnetic for RDS.) Moreover, RDS storage IOPS scale with storage size, so if [storage auto scaling](https://aws.amazon.com/about-aws/whats-new/2019/06/rds-storage-auto-scaling/) is enabled, IOPS change.

<small>Side note: ["io1 is backed by solid-state drives (SSDs)"](https://aws.amazon.com/ebs/features/#SSD-backed_volumes_.28IOPS-intensive.29). I presume that "backed by" does _not_ mean direct-attached.</small>

Does information about InnoDB IO performance apply to RDS storage IOPS? To my knowledge, there's no authoritative answer. But to start, we can presume "yes" and treat RDS IOPS equal to direct-attached storage IOPS. Then we have to consider gp2 vs. io1.

<mark>I very highly recommend 1,000G (1TB) _max_ storage per RDS instance.</mark> 500G max is better, but I'm being generous. The reasons why are another topic, but for now let's limit the discussion to 1TB max.

| Storage | innodb_io_capacity | innodb_io_capacity_max |
| ------- | ------------------ | ---------------------- |
| gp2     | Base Performance <= 1500 | 3000 |
| io1     | 0.5 * innodb_io_capacity_max | Provision IOPS <= 5000 |

For gp2 storage up to 1000G (1TB), set `innodb_io_capacity` to base performance IOPS, up to 1500. Even though 1000G of storage provides 3000 IOPS base performance, there's no need to set `innodb_io_capacity` greater than 1500 unless measuring proves it's needed. And set `innodb_io_capacity_max = 3000` as a reasonable start; measure to prove that a higher value is needed. Overall, we're trying to ensure we utilize the RDS IOPS paid for without flushing so quickly that we negate the value of in-memory InnoDB buffer pool caching.

For io1, I suggest setting `innodb_io_capacity` to 50% of `innodb_io_capacity_max`, and set `innodb_io_capacity_max` to the provisioned IOPS, up to 5000. Again, we're trying to balance utilization of IOPS with InnoDB buffer pool caching.

The MySQL industry needs more research into InnoDB IO capacity tuning with Amazon RDS for MySQL.
