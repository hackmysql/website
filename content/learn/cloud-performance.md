---
type: "path"
date: "2025-05-15T06:47:00-07:00"
title: "Cloud Performance"
weight: 9
tags: ["mysql"]
params:
  dontFeed: true
---

## Context

This is why you need to learn about the reality of using MySQL in the cloud:

<div class="intro">
MySQL in the cloud is fundamentally the same MySQL that you know and love (or know and tolerate).
In the cloud, best practices and techniques are not only true but <i>eminently</i> true because cloud providers charge for every byte and millisecond of work.
Performance is money in the cloud.

I wish it were as simple as "optimize the workload and you’re done", but MySQL in the cloud raises unique considerations.
The goal is to know and mitigate these cloud considerations so that you can focus on MySQL, not the cloud.
After all, the cloud is nothing special: behind the proverbial curtain, it’s physical servers in a data center running programs like MySQL.

{{< book-excerpt-copyright c="Chapter 10" >}}
</div>

## Key Points

* Code and feature compatibility of MySQL varies in the cloud
* Your due diligence is to know any code or feature incompatibilities compared to open-source MySQL
* MySQL can be partially or fully managed, depending on cloud provider or third-party company
* Network latency over wide-area networks increases query response time by tens or hundreds of milliseconds
* Data for MySQL in the cloud is usually stored on network-attached storage
* Network-attached storage has single-digit millisecond latency, which is equivalent to a spinning disk
* The cloud charges for everything, and costs can (and often do) go over budget
* Cloud providers offer discounts; don’t pay full price

## Pitfalls

* Believing cloud vendor claims at face value
* Not doing your own research and benchmarks in the cloud
* Surprising cloud spend: not carefully calculating costs ahead of time
* Slower than expected cloud performance, especially long tail latency
* "Managed" database solution still needs a lot of user management
* Cloud provider is slow to detect and fail over a failed MySQL instance
* Not having `SUPER` privileges in MySQL

## Hack MySQL Articles

{{< path-articles path="cloud" >}}

## Additional Resources

| Resource | Type | About |
|----------|------|-------|
| [Which Cloud Provider Performs Better for My MySQL Workload?](https://www.percona.com/blog/which-cloud-provider-performs-better-for-my-mysql-workload/) by Ananias Tsalouchidis @ Percona|Article|It's important to read as many independent cloud benchmarks and comparisons as possible, like this one|
| [Maximizing Performance of AWS RDS for MySQL with Dedicated Log Volumes](https://www.percona.com/blog/maximizing-performance-of-aws-rds-for-mysql-with-dedicated-log-volumes/) by Kedar Vaijanapurkar @ Percona|Article|It's also important to learn about new cloud features because the vendors do make improvements, like this one|
