---
type: "page"
date: "2022-10-15T16:31:00-04:00"
title: "Is MySQL in the Cloud the End of the DBA?"
subtitle: "Chapter 10"
tags: ["mysql", "cloud", "dba", "business", "philosophy", "book", "efficient-mysql-performance"]
comments: true
aliases:
  - /post/book-10/
disqus_url: "https://hackmysql.com/post/book-10/"
series: "Behind the Book"
params:
  path: cloud
---

No, I don't think so.
But it is does change our profession and have important implications for software engineers using (not managing) MySQL.

<!--more-->

<p class="note">
This blog post is the eleventh of eleven: one for the preface and ten for each chapter of my book <a href="https://oreil.ly/efficient-mysql-performance"><i>Efficient MySQL Performance</i></a>.
The full list is <a href="/tags/efficient-mysql-performance/">tags/efficient-mysql-performance</a>.
</p>

Several years ago, I was at a local meetup hosted by Oracle.
The redoubtable Kenny Gryp was there.
But what I recall most was a conversation with another DBA whom I'm not well acquainted, so forgive me whoever you are that I have since forgotten your name.
But I remember what you said in response to me saying that I think MySQL needs more DBAs: you said no because the cloud is taking over MySQL administration.

Years later, I see this playing out: it's extremely difficult to hire an experienced MySQL DBA; instead, we hire good software engineers (sometimes right out of college) and train them to operate a preexisting MySQL fleet, and we don't expect them to "go deep" on MySQL&mdash;we certainly don't expect them to become MySQL experts.

The independent<sup>\*</sup> MySQL experts that exist today are the last of our kind.
We're a dying breed.
And that's ok.

<small>
<sup>&ast;</sup><i>Independent</i> means using MySQL, not developing it.
Of course, Oracle will continue to hire and train engineers to develop MySQL, and they'll be experts in their area of development, but I'm talking about DBAs: people managing MySQL and publicly writing and presenting about it&mdash;people who choose to go deep and become experts, not people hired to become experts.
</small>

That's ok because, today, MySQL DBA work is less about MySQL and more about everything around MySQL: storage, compute, security, compliance, data platform, applications, and software engineers.
Of course, there are new developments, ongoing bugs, and all the usual things for which some number of independent experts will exist to surface and solve for the wider industry.
But all things considered, with a standard setup MySQL itself _just works_.

And this is where the cloud comes in because no DBA honestly wants to operate MySQL on a bare metal fleet.
Yes, it's really cool and technical&mdash;makes you feel special.
But unless you're in a stable (or very slow changing) environment, you'll spend too much time chasing hardware changes and issues.
Like our personal electronic devices, enterprise hardware changes pretty frequently because sales people need newer, shiner things to sell.
Those 5 TB enterprise-grade SSDs in your rack server with the ideal combination of BIOS, firmware, and kernel that help MySQL perform so well?
Can't buy 'em any longer.
Also, the latest BIOS changes fan speed management, which affects CPU temperature, which affects CPU clock speed, which wreaks havoc on query response time.
And when testing the backup power panel causes both of them to fail, your eyes turn skyward...

As I write in chapter 10 of [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance), the cloud runs MySQL but it doesn't replace the need for DBA work:

![Cloud DBA Work](/img/cloud-dba-work.png)

Although the number of checks under "You" is double the number under "Cloud", the five checks under the latter are important because they handle all the low-level work (especially hardware) that can be simultaneously the most burdensome and the least impactful.
The five cloud checks have different implications depending on your relation to MySQL:

* **DBA**
  * The cloud lets DBAs focus on providing a better user experience with respect to the checks under "DBA".
For example, better server and query metrics to help users (software engineers) understand how the application affects MySQL and its performance.
This is how our profession has changed: instead of wrestling with MySQL at a low level, we can work with software engineers at a high level to understand and utilize MySQL more efficiently.
This is especially important in the cloud where "big hardware" is quite expensive, or pay-per-usage can run amuck.<br><br>
* **Software Engineer**
  * The cloud will run MySQL for you, but that's not the same as managing it.
You'll quickly find that the cloud still leaves a lot of DBA work for you (or your DBA) to do.
In the world of MySQL, online schema change (running `ALTER` statements without blocking any queries) is a common need that no cloud solves.
So if you're new to MySQL in the cloud, be aware and don't be surprised: you'll need to do a fair bit more work to make MySQL in the cloud truly production-ready&mdash;presuming you care about things like security and disaster recovery (DR).

In time, I think cloud providers will earn more checks.
For example, Amazon has solutions for server metrics, query metrics, DR, and HA; but, frankly, I don't think they're good enough yet to earn a check under "Cloud".
For example, one thing that really annoys me about Amazon RDS and Aurora: when you set up cross-region replication for DR, Amazon does not monitor or alert you if replication stops due to an issue on their side&mdash;and they certainly don't fix it, either.
That annoys me because, in this case, replication is _their_ product feature, so they should monitor and ensure it continues to work.
But it can and will fail silently unless you know to monitor and fix it yourself.
And even then, because it's something they set up on their side, I have had cases where I couldn't fix it from my side.
And if you're still not convinced: I've also had a case where AWS said replication was setup according to their API, but MySQL was not configured for replication&mdash;a clear and serious bug on the AWS side, for which there is currently no easy fix.
_Caveat emptor_.

MySQL in the cloud is improving, which means the traditional DBA will focus less on running MySQL and more on helping software engineers use MySQL efficiently.
This is one reason why I wrote [_Efficient MySQL Performance_](https://oreil.ly/efficient-mysql-performance): for software engineers using MySQL, not DBAs, because the latter have won the proverbial war: MySQL runs appreciable parts of the world, and it _just works_.
But relational databases are complex, which obscures the path to what software engineers need most from MySQL: performance.

But the cloud doesn't care about MySQL performance.
Whether fast or slow, it'll bill you all the same.
That's why the cloud will never be the end of the DBA.
And it's also why we come full circle to the first sentence of my book:

![First sentence of Efficient MySQL Performance](/img/first-sentence.png)
