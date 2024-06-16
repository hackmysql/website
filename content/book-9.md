---
type: "page"
date: "2022-09-16T16:01:00-04:00"
title: "How Not to Use MySQL"
subtitle: "Chapter 9"
tags: ["mysql", "antipatterns", "book", "efficient-mysql-performance"]
comments: true
aliases:
  - /post/book-9/
disqus_url: "https://hackmysql.com/post/book-9/"
---

Chapter 9 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) changed in development. Originally, it was a chapter titled "Not MySQL", as in "how not to use MySQL." But we (O'Reilly and I) pulled the chapter, and the current chapter 9 in print is "Other Challenges": an important laundry list of other challenges engineers using MySQL must be aware of and address. This blog post is a sketch of the unwritten chapter 9: how not to use MySQL.

<!--more-->

<p class="note">
This blog post is the tenth of eleven: one for the preface and ten for each chapter of my book <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a>.
The full list is <a href="/tags/efficient-mysql-performance/">tags/efficient-mysql-performance</a>.
</p>

## MySQL Is Too Good

MySQL is a paragon of an OLTP data store: SQL, relational, transactional, row locking, MVCC, ACID, and of course: _fast_.
It's incredibly good at what it is and does.

But perhaps it's _too_ good at what does because it's used for all sorts of others purposes.
Why?
Because it works surprisingly well for other purposes.
It's like a hammer, wrench, drill, and screwdriver all in one.

Long ago, there weren't many viable options.
But in the last 10 years, there's been an explosion of data stores.
More importantly, there's also been a change in the industry mindset towards polyglot data being the norm.
That means using the best data store for the job, not simply the most ubiquitous data store&mdash;which was MySQL for a long time.

If you need a MySQL expert to say that it's ok not to use MySQL and, instead, better to use another data store, here it is:

<mark>_It's ok not to use MySQL; use another data store that's purpose-built or better suited to the data model._</mark>

## Rule of Thumb: Structured and Relational

As a rule of thumb, MySQL is best for data that is structured and relational.
That shouldn't be a surprise because it's an SQL database, and "structured" is the "S" in SQL.
And SQL is the query language developed on top of E. F. Codd's relational model.
Granted, some say that SQL isn't true to the relational model, but for our purposes it doesn't matter: SQL (and relational) won.

Note that "OLTP" or even just "transactional" are not part of the rule of thumb.
Yes, MySQL is an OLTP-optimized data store, but a workload dominated by point SELECTs is still a good use case even though it's barely OLTP or transactional in the full sense of these two terms.

_Structured_ and _relational_ are very closely related, but they can come apart.
For example, a document store can have relations within the data, but documents don't have a fixed structured&mdash;that's why NoSQL/document stores are so useful: flexible "structure".
On the other hand, a key-value store like DynamoDB requires a somewhat fixed structure in terms of partition key and secondary indexes, but it doesn't really have relations.

When data has a known structure, and there are relations among the structured data, MySQL is able to figure out how to efficiently access data for an infinite number of queries.
To state it directly: rigid data allows flexible queries.
For example, DynamoDB does _not_ have flexible queries: you must use either the partition key or one of the few secondary indexes, and you can't join tables.
The data is very flexible (dump anything you want in DynamoDB), but the queries are not.
But for that trade-off, you get extremely fast data access and horizontal scalability.
The reverse is true for MySQL.
The data structure is not flexible, but the queries are very flexible (with reasonable indexes) because MySQL figures out how to access data for a query based on the fixed structure&mdash;and, of course, you can join tables any way you want (and MySQL can, too).

MySQL is fundamentally a relational data store.
Almost every thing about it&mdash;internally and externally&mdash;is designed and optimized to be a relational data store.
Consequently, that's the best use case for MySQL: structured and relational data.

## How Not to Use MySQL

MySQL works for the following uses cases (sometimes quite well), but none of them exhibit structured and relational data.
As such, to some degree they work against MySQL.

### Cache

Caches are usually ephemeral: in-memory only.
But MySQL is durable by default.
That durability is fundamentally at odds with (and wasted overhead compared to) in-memory caching.

Caches are not meant to be transactional or relational.
They're usually far simpler, like key-value or everything [Redis](https://redis.io/) can do.
But MySQL is inherently transactional and relational, and all the "machinery" to make those two happens is (again) at odds with caching.

Although the InnoDB buffer pool acts like an in-memory cache, you should never think of it as that.
If you read [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance) it will be clear why: pages in the buffer pool are doing _a lot_ more than simply caching data.

Instead, use a real cache like [memcached](https://memcached.org/) or [Redis](https://redis.io/).

### Queue

Queues are meant for fast-moving, transient data.
Some queues are durable, others are not.
And typically the only access pattern to a queue is "Give me N messages"&mdash;one doesn't query a queue.

What really makes MySQL a poor queue is that every query in MySQL must go through the full process of being a transaction in a relational database.
So whereas a queue just wants to quickly input and output a little message, MySQL says "Wait. Hold on... Let's treat this query with the full dignity of an ACID transaction... We gotta start a transaction, establish a consistent snapshot of the _whole_ database, check and acquire locks, insert the row, update the page, possibly split or merge the index tree, commit the transaction, wait for the binary logs, add a dirty page to the lists, and..." on and on.
It's like you want to drive to the grocery story for almond milk, but you fly across the world to a store that doesn't have almond milk, so they order it for you, and meanwhile you rent a hotel in that foreign land and wait until it arrives, then you fly back home.
Weird and ridiculous.
So don't use MySQL as a queue.

### OLAP

MySQL is an OLTP database.
OLTP != OLAP.

MySQL is a teapot; don't use it to boil the ocean.
Use a real OLAP data store.

### Big data store

A somewhat common question I get from developers is how much data MySQL can store.
The quick _technical_ answer is 64 TB, but see [15.22 InnoDB Limits](https://dev.mysql.com/doc/refman/8.0/en/innodb-limits.html).
The more realistic answer is (as I write in chapter 5 my book):

>4 TB: For exceptionally optimized queries and access patterns, mid- to high-end hardware is sufficient for acceptable performance, but operations might take slightly longer than acceptable.

Yes, MySQL can store 64 TB, but you're going to run into serious problems long before that.
For example, how long do you think it'll take to do an `ALTER` or online schema migration (OSC) on 10 TB?
A very long time on a busy production database.
Then there's the issue of working set size: how big is that vs. how much RAM you can afford?

All that said, I manage a few databases around 7 TB.
(Where I work, we use microservices, so we have thousands of databases, but most are kept small.)
But these work because it's mostly cold, infrequently accessed data.
If you want to store _and_ access tens of terabytes, you need a different data store than MySQL, especially depending on other access patterns.
MySQL can do it, but it's not ideal.

### Document store

I'll tell you a secret: I dislike and discourage the use of [the JSON data type](https://dev.mysql.com/doc/refman/8.0/en/json.html).
I'm not against storing JSON blobs in `BLOB` columns even though that begins to treat MySQL like an object store (like Amazon S3).
But using the JSON column type for document-like access is patently not what MySQL is designed for.
We know this because there are purpose-built document stores like [MongoDB](https://www.mongodb.com/) and [Amazon DocumentDB](https://aws.amazon.com/documentdb/) (based on the former), and they're nothing like MySQL.
For one thing, true document stores don't use SQL.
As a result, SQL syntax for document access is a hacky kludge&mdash;especially compared to the query language of true document stores.

Document stores scale horizontally.
That's partly why they were (somewhat derisively) called "web scale" many years ago.
If your data is document-oriented, you'll have a better query language _and_ built-in horizontal scalability by using a true document store.
Remember: it's ok not to use MySQL.

### Key-value store

Admittedly, MySQL works pretty well as a key-value store when a table has only a primary key because, as a clustered index in the InnoDB buffer pool, this is the fastest access possible.
MySQL is blazing fast at single table primary key lookups.
If this is one access pattern among others, and otherwise the data is structured and relational, then it's ok: it's simply an efficient point lookup; it's not surreptitiously treating MySQL as a key-value store.

The problem and suboptimal use case occurs when this type of access is intentional: using point lookups for key-value access because the former happen to be blazing fast.
The problem is, again, that every query in MySQL is a transaction that incurs all the transactional, relational overhead.

But more importantly, like using MySQL for a document store, you don't get horizontal scalability for free.
You would if you used a true key-value store like DynamoDB or [ScyllaiDB](https://www.scylladb.com/).

### Programming language

Long ago (and still in some corners of the relational database world), it was common to put stored procedures in the database.
[PL/SQL](https://en.wikipedia.org/wiki/PL/SQL) for example.
But the various problems with this are now readily found in books.
For one thing, it's difficult to unit test code in a stored procedure, which is especially bad given that the code is very important: it messes with data at the source of truth (the database).

In my experience, this is not common in MySQL even though it has [stored procedures](https://dev.mysql.com/doc/refman/8.0/en/create-procedure.html).
So let's keep it this way: don't hide important code in MySQL.
Keep all code with your application code, unit tested, and in Git (or whatever VCS you use).

Plus, code inside MySQL doesn't scale well.
Why burden the one writable MySQL instance with running such code when your application probably scales out horizontally through Kubernetes?

## Chapter 9 in Print: Other Challenges

This is a very quick "part 2" of this blog post.
For completeness, I'll list the sections of chapter 9 in print with a one-liner about the importance of this "other challenge".

|Section Title|One-liner Point|
|-------------|---------------|
|Split-brain Is the Greatest Risk|A moment of split-brain can create an avalanche of inconsistent data|
|Data Drift Is Real but Invisible|Inconsistent data tends to spread and become more inconsistent|
|Don’t Trust an ORM|ORM libraries are optimized for developers, not databases|
|Schemas Always Change|You will need [pt-online-schema-change](https://docs.percona.com/percona-toolkit/pt-online-schema-change.html) or [gh-ost](https://github.com/github/gh-ost)|
|MySQL Extends Standard SQL|MySQL has quirks and surprises; expect them|
|Noisy Neighbors|Other programs steal system resources and inadvertently hurt MySQL performance|
|Applications Do Not Fail Gracefully|Practice chaos engineering to test the mettle of your application|
|High Performance MySQL Is Difficult|MySQL performance becomes easier with time and experience, but it's always challenging|
