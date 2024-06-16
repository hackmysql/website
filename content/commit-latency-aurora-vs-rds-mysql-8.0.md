---
type: "page"
date: "2023-01-02T20:18:00-05:00"
title: "COMMIT Latency: Aurora vs. RDS MySQL 8.0"
tags: ["mysql", "benchmarks", "aws", "aurora"]
comments: true
lastmod: "2023-02-18T13:35:00-05:00"
aliases:
  - /post/commit-latency-aurora-vs-rds-mysql-8.0/
disqus_url: "https://hackmysql.com/post/commit-latency-aurora-vs-rds-mysql-8.0/"
---

Let's examine `COMMIT` latency on Aurora v2 (MySQL 5.7) vs. Aurora v3 (MySQL 8.0) vs. RDS MySQL 8.0 2-AZ vs. RDS MySQL 8.0 3-AZ "cluster".

<!--more-->

## Why COMMIT Latency?

`COMMIT` is when MySQL incurs storage latency to make data changes durable.
Before that, reads and writes are ideally (but not always) in-memory operations.
Therefore, CPU and memory (and a few other concerns) affect query response time before `COMMIT`, but on `COMMIT` response time is largely a result of how fast the storage system can physically write and flush.
In the cloud, storage is usually network-backed, so `COMMIT` latency can be orders of magnitude higher than locally-attached SSDs&mdash;milliseconds versus microseconds.

<p class="note">
I use the term <em>latency</em> specifically because storage has true latency: delay inherent in a system.
Readers of <a href="https://oreil.ly/efficient-mysql-performance">my book</a> know that normally I use (and insist upon) the term <em>response time</em>, not latency, because response time is not a delay inherit in a system.
But COMMIT latency is true latency.
</p>

`COMMIT` latency is also important because it affects transaction throughput (transactions/second [TPS]).
Presuming negligible lock waits and intra-query delays (caused by the application), TPS is limited by how fast MySQL can finish the transaction on `COMMIT`.
For example, in the cloud a transaction might have these response times:

```sql
BEGIN      --  0 ms
SELECT ... --  5 ms
UPDATE ... --  1 ms
COMMIT     -- 20 ms (latency)
```

The `SELECT` and `UPDATE` take almost no time, but the `COMMIT` takes a full 20 milliseconds because it's writing and flushing to an EBS volume, for example.
Given that latency, the transaction is limited to about 50 TPS (1,000 ms / 20 ms = 50) per thread.
If, for example, you have 48 threads (clients), you'll get about 50 * 48 = 2,400 TPS.
Point being: if your application uses multi-statement transactions, `COMMIT` and TPS can be more important than individual query response time when the queries are fast but the storage is slow.

## Benchmarks

TL;DR: Aurora has the lowest (fastest) and most stable `COMMIT` latency.

<p class="note">Click charts for full-size PNG image.</p>

[![Aurora v2 COMMIT Latency scatter plot](/img/COMMIT-latency-Aurora-v2.svg)](/img/COMMIT-latency-Aurora-v2.png)

Min 574 _μs_ or 1.56 ms &rarr; Max 214 ms

[![Aurora v3 COMMIT Latency scatter plot](/img/COMMIT-latency-Aurora-v3.svg)](/img/COMMIT-latency-Aurora-v3.png)

Min 1.86 ms &rarr; Max 226 ms

[![Amazon RDS MySQL 8.0 2-AZ COMMIT Latency scatter plot](/img/COMMIT-latency-RDS-MySQL-8.0-2AZ.svg)](/img/COMMIT-latency-RDS-MySQL-8.0-2AZ.png)

Min: 4.08 ms &rarr; Max: 922 ms; 780 ms; 382 ms

[![Amazon RDS MySQL 8.0 3-AZ Cluster COMMIT Latency scatter plot](/img/COMMIT-latency-RDS-MySQL-8.0-3AZ-cluster.svg)](/img/COMMIT-latency-RDS-MySQL-8.0-3AZ-cluster.png)

Min 1.93 ms &rarr; Max 345 ms

<p class="note">Click charts for full-size PNG image.</p>

## Observations

This post is intended for MySQL experts, so I'll let the four charts above speak for themselves.
However, I'll make a few points:

* It's no surprise that Aurora beats standard RDS for MySQL: the former was purpose-built for more efficient storage I/O.
You can find lots of resources published by Amazon about Aurora storage, so I won't repeat them here.

* Aurora v2 and v3 have similar `COMMIT` latency, but the v3 values are slightly higher and more variable.
For the minimum, v2 is very steady but v3 shows more variation, but the different is microseconds; both have a minimum of roughly 2 ms.
For the P99.9 and maximum, v2 values are tightly clustered in the 20-30 ms range with semi-regular spikes in the 60-70 ms range, but v3 is loosely clustered in the 20-30 ms range with semi-regular spikes around 100 ms.
I don't know if Aurora v2 and v3 have different storage servers (only Amazon would know), so the slight difference in numbers might be random performance differences inherit to multi-tenant (shared) hardware.

* The 574 _microsecond_ (μs) `COMMIT` latency observed on Aurora v2 is such a surprising outlier that I would dismiss it, especially since it's the only sub-millisecond measurement observed in tens of millions of `COMMIT`.
It might even be an error of some sort.

* RDS for MySQL 8.0 (2 AZ) has double the minimum `COMMIT` latency as Aurora: about 4 ms.
I suspect this is due to redo log flushing (and full page writes) and synchronous EBS writes to the second AZ&mdash;neither of which Aurora have because its storage is completely different.
4 ms isn't terrible; it's the P99.9 and max that are troublesome...

* RDS for MySQL 8.0 (2 AZ) has P99.9 and max `COMMIT` latency in the 50-100 ms range with random spikes all the way up to 922 ms.
The max value of 922 ms occurred only once.
The 2nd highest was 780 ms that also occurred only once.
The 3rd highest value was 382 ms, which was more representative of reoccurring max `COMMIT` latency.
No matter how you look at it, these values are troublesome.
Not knowing if a `COMMIT` will take 50 ms or _double_ (100 ms) or _maybe_ an unacceptable half-second (or more!) makes working with the database onerous for developers who need reliable write transaction throughput.

* RDS for MySQL 8.0 (3 AZ) "cluster" is an interesting product.
Amazon calls it ["multi-AZ clusters"](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/multi-az-db-clusters-concepts.html), but I think that's confusing for a couple reasons, so I call it 3-AZ "clusters".
If you're not familiar with this product (whatever you call it), read the link.
On the one hand, the locally-attached NVMe seem to help keep minimum `COMMIT` latency consistency low: about 2 ms, same as Aurora.
But the variability up to the P99.9 and max is terrible: widely scattered around 150 ms.
So the `COMMIT` might take 2 ms, or _75 times longer_, or somewhere in between.
Crazy.
My guess is that this is due to semi-sync replication, but more benchmarking of this product is needed to know for sure.

## Methodology

You're not going to recognize this methodology or benchmark run in general because I developed a new benchmark tool last year (2022) that I'll release later this year.
But for now, I'll dump some information how I obtained the values for the charts above so it's not all smoke and mirrors.

### Database

Configuration
: * Amazon default parameter group _plus_ binary logging with GTID
: * _Exception_: query cache disabled in Aurora v2 (AWS enables it by default)

Replication
: *  Async replication with binary logs and GTID from AWS us-east-1 to us-west-2
: * _Exception_: 3 AZ "cluster" uses semi-sync replication with GTID in us-east-1 only

Instance class
: db.r5.12xlarge (24 CPU; 48 vCPU; 384 GB RAM)
: Active/primary/writer in AWS us-east-1

Clients
: 48 total
: * 16 us-east-1a
: * 16 us-east-1b
: * 16 us-east-1c

### Schema

```sql
CREATE TABLE customers (
  id		bigint NOT NULL AUTO_INCREMENT,
  c_token	varbinary(255) NOT NULL,
  country	char(3) NOT NULL,
  c1 		varchar(20) DEFAULT NULL,
  c2 		varchar(50) DEFAULT NULL,
  c3 		varchar(255) DEFAULT NULL,
  b1 		tinyint NOT NULL,
  created_at	timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at	timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (c_token),
  KEY (country)
) ENGINE=InnoDB

CREATE TABLE balances (
  id 		bigint NOT NULL AUTO_INCREMENT,
  b_token	varbinary(255) NOT NULL,
  c_token 	varbinary(255) NOT NULL,
  version 	int NOT NULL DEFAULT '0',
  cents 	bigint NOT NULL,
  currency	varbinary(3) NOT NULL,
  c1		varchar(50) NOT NULL,
  c2		varchar(120) DEFAULT NULL,
  b1 		tinyint NOT NULL,
  created_at	timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at	timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (b_token),
  KEY (c_token)
) ENGINE=InnoDB

CREATE TABLE xfers (
  id		bigint NOT NULL AUTO_INCREMENT,
  x_token	varchar(255) NOT NULL,
  cents 	bigint NOT NULL,
  currency 	varbinary(3) NOT NULL,
  s_token 	varchar(255) NOT NULL,
  r_token 	varchar(255) NOT NULL,
  version    int unsigned NOT NULL DEFAULT '0',
  c1		varchar(50) DEFAULT NULL,
  c2		varchar(255) DEFAULT NULL,
  c3 		varchar(30) DEFAULT NULL,
  t1 		timestamp NULL DEFAULT NULL,
  t2 		timestamp NULL DEFAULT NULL,
  t3 		timestamp NULL DEFAULT NULL,
  b1 		tinyint NOT NULL,
  b2 		tinyint NOT NULL,
  created_at	timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at	timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY (x_token),
  KEY (s_token, t1),
  KEY (r_token, t1),
  KEY (created_at)
) ENGINE=InnoDB
```


### Transaction

This is _not_&mdash;I repeat: _not_&mdash;how money is transferred in real-world systems.
This is a fake transaction designed to stress MySQL in various ways. 

```
BEGIN

-- Select random customer and one of their balances (from cust/bal)
SELECT c_token, country FROM customers WHERE id=@id
SELECT b_token FROM balances WHERE c_token=@from_cust LIMIT 1

-- Select another random customer and their balance in the same country (to cust/bal)
SELECT c_token FROM customers WHERE id BETWEEN @id_1000 AND @PREV AND country=@country LIMIT 1
SELECT b_token FROM balances WHERE c_token=@to_cust LIMIT 1

-- Start new transfer between customers
INSERT INTO xfers VALUES (NULL, @x_token, 100, 'USD', @from_bal, @to_bal, 1, @c1, @c2, @c3, NOW(), NULL, NULL, 1, 0, NOW(), NOW()) -- 6

-- Lock then debit from customer balance
SELECT id, version FROM balances WHERE b_token=@from_bal FOR UPDATE
UPDATE balances SET cents=cents-100, version=version+1 WHERE id=@from_id

-- Lock then credit to customer balance
SELECT id, version FROM balances WHERE b_token=@to_bal FOR UPDATE
UPDATE balances SET cents=cents+100, version=version+1 WHERE id=@to_id

-- Finish transfer
UPDATE xfers SET t2=NOW(), c3='DONE' WHERE id=@xfer_id

COMMIT
```

### Data Sizes

|&nbsp;|customers|balances|xfers|
|------|---------|---------|-----|
|**Rows**|500,000,000|1.5 billion (3x per cust.)|~2 billion|
|**Data Size**|200 GB|700 GB|1.0 TB|

### Data Access

Uniform random 100M customers between IDs 250,000,000 and 500,000,000.

## Thank You

In this blog post I focus on only `COMMIT` latency on four Amazon products, but I did over 20 benchmarks recently on all Amazon products for MySQL.
Benchmarks like these are not cheap.
Thank you to my employer for making this work possible:

<a href="https://cash.app" style="color:black; text-decoration: none"><img src="/img/icon-square-cash.svg" width="40px" style="display:inline; vertical-align:middle;" alt="Cash App logo">&nbsp;&nbsp;Cash App</a>
