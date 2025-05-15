---
type: "page"
date: "2022-05-21T15:10:00-04:00"
title: "NewDB: Fate of an Open Source Database"
tags: ["open-source", "philosophy", "business"]
comments: true
aliases:
  - /post/newdb/
disqus_url: "https://hackmysql.com/post/newdb/"
---

Recently, I've had several discussions with engineers, industry experts, and business people of various titles and functions (from sales to CEO) about the fate of a new open source database.
It's not MySQL, and I won't name the real database because it doesn't matter for the purpose of this post.
But to make writing and communication more clear, let's call the database "NewDB" and the business "New Corp."

This blog post is a think piece on how New Corp. can win the market with NewDB by remaining true to its open source origins _and_ build a profitable business.

## Ground Work

First, I think we all agree that "open source is not a business model".
Now that that is settled, let's also agree that a business founded on (or built around) an open source product _must make profit_.
Some people disagree: they think that sullies the purity of open source.
But open source software engineers have bills to pay, too.
And if the company doesn't make a profit&mdash;not just revenue, but _profit_ to weather financial storms&mdash;then it will eventually cease to exist, and so too might its open source product.
Yes, capitalism can sully the purity of free, open source software, but it can also amplify it if practiced with principle and integrity.
(And if we're going to be jaded, I'd argue that it's really a lack of principle and integrity that leads businesses to abuse capitalism to the point of giving the latter a bad reputation.
But let's move on.)

But who pays?
I think businesses should pay more&mdash;a lot more&mdash;for open source software that they use to make profit.
Individuals don't have to worry: open source should always be free for individuals, which is so deeply rooted in the notion of open source that it's almost never stated explicitly.

Therefore, the ground work and starting point for all the rest is that we can have a free open source product _and also_ a for-profit business to build and support it.
The two are not mutually exclusive, but the balance is difficult to strike.

## The Moat

The first and perhaps most pressing question at New Corp. is "If we're giving away NewDB for free, then what's our competitive advantage&mdash;our moat?"
It's true that anyone (person or business) can fork NewDB or learn from its source code to make a newer, better database.
But I think the history of successful databases disproves that worry: it's very difficult and time-consuming to create a new database, and even more difficult to get businesses to trust and use it.
There are several open source relational databases, but MySQL and PostgreSQL dominate the market.
Granted, those two took away significant market share from Oracle and Microsoft, but that supports the case for open source: a scrappy little database like MySQL took over the world (web 2.0, at least) even though the incumbents had every opportunity to "steal" its secrets and reclaim their lost market share.
But [The Innovator's Dilemma](https://claytonchristensen.com/books/the-innovators-dilemma/) teaches us why the incumbents did not.
And for those who don't know the history of MySQL: Oracle bought Sun to acquire Java, not MySQL.

If New Corp. spends its time, energy, and money fending of real or imagined competitors, they'll lose focus and lose the market.
Instead, New Corp. must build a moat that's too deep and wide for competitors to cross.
For open source software, a moat is created by its _usefulness_ and _priority_.

### Usefulness

The more useful NewDB is to users, the deeper and wider its moat.

This is one way in which MySQL won: its replication was stupid-simple and easy, and that made it tremendously useful.
Was it technically good or rigorous?
Maybe not; but it was easy, it worked, and it got the job done&mdash;it provided _value_, and that's ultimately what customers purchase: value.
Users expect a certain degree of technical correctness and proficiency because, without them, a product is not "enterprise-ready".
But the bar is pretty low, in my opinion, because engineers are often under pressure from the business to "ship it".
Therefore, a database doesn't have to be the best (in technical terms), it has to be the most useful.

Usefulness requires daily practice of the statement,

> There are no facts inside the building.<br>&mdash;Steve Blank

What's useful is decided and driven by customers, not New Corp.
Let me put a very fine point on it: executives, managers, and marketing must _not_ drive development because they are inside the building, and figuratively they _are_ the building.
I realize that setting direction is a core function of those three, but the difference is that they must keep New Corp. focused on real customers and their needs, not concocting strategies to increase business metrics and appease investors.
Doing the latter is a loss of focus on the product and customers, and _that_&mdash;not free open source software&mdash;is what gives competitors an opportunity.
It's easy to steal customers from a company that doesn't care about them.

Side note: I grant one exception for sales people: since you don't work on NewDB, you can focus on wining new businesses as long as you do so only if NewDB is in the customer's best interest and will help them succeed.
If not, then abide by your principle and integrity: tell the customer that NewDB isn't a fit, and suggest a better alternative.
You might not make a sale today, but you'll earn their respect and they will return with cash and contract in hand when they need NewDB.

Open source products backed by companies always start of by focusing on usefulness because there's zero chance of success if the product isn't useful.
But that focus begins to wane as the business grows and the original technical founders delegate responsibilities to executives and managers and, at the same time, task them with growing the business.
To accomplish the latter (growing the business), the executives and managers might insist on various business-focused strategies and directions.
The important question to ask is "How does this benefit users?"
If the answer is not clear and logical, it might grow the business at the expense of decreasing the moat.

Another risk I see is that, early on, the open source product can't decide for whom it wants to be useful.
Attempting to be useful to everyone, it winds up being useful to no one.
MySQL, for example, never strayed much from being a relational, OLTP database.
That was (and still is) why it's profoundly useful.

### Priority

The more New Corp. prioritizes development of open source NewDB, the deeper and wider its moat.

The free open source edition of NewDB must always be the first priority of New Corp.&mdash;let's call this the "community edition".
This does not preclude an enterprise edition, but it does strongly require that the enterprise edition _not_ be the focus of development.
For simplicity, I'll speak in terms of community vs. enterprise, but in the next section I'll challenge the whole notion of an enterprise edition.

This is especially true when executives, sales, or marketing try to prioritize enterprise features, thereby neglecting or excluding the community edition.
These business people might do so in the name of prioritizing enterprise users since they are generating revenue, but it must be remembered that free users of the community edition created the market for and confidence in NewDB on which the enterprise edition is built.
Open source is and must remain the foundation; on top of that, the business can build a skyscraper with enterprise user revenue.
To prioritize it otherwise is to build castles in the sky.

In practice, prioritizing open source (the community edition) _first and foremost_ means planning and developing it _first and foremost_.
This doesn't not preclude enterprise features; it means that work common to both is done in community first, then ported to enterprise.
Never the reverse.
But to illustrate the reverse, it would look like:

* Releasing a bug fix in enterprise first, then later in community
* Developing a feature in enterprise first, then later porting to community
* Having a roadmap or development plan for enterprise but not community
* Releasing enterprise versions ahead of community (major, minor, or patch releases)

One or more of those four examples would indicate that New Corp. is not prioritizing open source NewDB and would raise doubts about whether New Corp. is actually a legitimate open source company or merely using open source as a sales and marketing ploy.
Such ploys drain the moat and invite competitors.

To further clarify, here are major areas of product development and how I think a legitimate open source company should handle them to prioritize open source and win the market by creating an impassible moat when combined with product usefulness:

Bug fixes
: Prioritize bug fixes (based on verification and severity) and actually fix and release them quickly.
It's ok to require users to provide a reproducible case, but also help users if the bug seems obvious or easy to reproduce.
Bugs are the responsibility of New Corp.; don't make them the responsibility of users.
Never fix a bug only in the enterprise edition unless it only affects an enterprise edition feature.

Feature fixes
: Prioritize feature fixes (based on usefulness and severity) and release them quickly.
At the very least, explain why a feature fix is not prioritized (or rejected).
(A "feature fix" is a change to a feature because it's not quite right [but also not wrong, which would make it a bug]; it's a continual pain point for users.)
Never fix a feature only in the enterprise edition unless it only affects an enterprise edition feature.

New features
: Continually plan and develop new features based on user needs.
It's ok to reject bespoke user feature requests that wouldn't benefit NewDB and all users as a whole.
No sales-driven development: developing new (or change existing features) so sales has something new to sell.
(Sales-driven development is a particularly bad sign for open source.)

Performance
: Continually improve core performance.
Address "small" systems and data as well as high-end systems.
(Developers usually start with small systems.)
Never fix a performance issue only in the enterprise edition unless it only affects an enterprise edition feature.
Also encourage third parties to help on this front because experienced engineers trust independent benchmarks the most.

Documentation
: Prioritize documentation (hire a professional technical writer) and strive to make the NewDB docs _the definitive and indispensable source_ for users, DBAs, and experts alike.
Ensure the docs are updated frequently, continually.
Clearly separate docs for enterprise features; do not mix community and enterprise docs.

Issue tracking
: Use public issue tracking.
Allow users to make their issues private only if they wish.
When issues are de-prioritized or rejected, explain why.
Track upcoming releases and constituent issues in the public issue tracker, too, so users can see what's in the pipeline.
Use the same issue tracker for enterprise features, but perhaps make those issues private by default since they're from customers and your customer list is private (or, allow customers to set a default visibility for their issues).

Community
: Plan and host community events if budgets allow.
Support and attend related events by others.
Have community forms and a Slack channel, but it's ok not to let users take advantage of these by treating them as a "free DBA".
It's ok to redirect such users to your paid support options.
Never present enterprise features at community events; don't even mention them unless asked.

Tooling
: If budgets allow, develop and improve open source external tooling for the most common user, DBA, and operational tasks.
Only do this if truly committed to making tools that are designed from real-world usage and experience.
Otherwise, it's better to let other individuals and companies develop (and support) tools.
In this case, support those individuals/companies because they're valuable: free development.

When open source NewDB is the first priority and work in all areas happens _first_ in the community edition, users will notice and become loyal to and advocates for the product&mdash;even when the product goes through hard times (and it will).
Both MySQL and PostgreSQL achieved this, and for more than 20 years much larger, more powerful corporations couldn't stop them from winning the relational database market.

If had a to philosophize why this (in the previous paragraph) occurs, I would argue that open source creates a sense of reciprocity that proprietary software never can.
For example, MySQL was a valuable gift to the world&mdash;free of charge.
While many companies didn't pay for it (but should have), countless engineers have chosen MySQL despite its quirks or shortcomings.
And while their choosing and using MySQL doesn't generate revenue, it's a form of giving back (reciprocity) by strengthening the community and ecosystem around it such that it becomes bigger, stronger, and better&mdash;both MySQL and its community.
For many engineers like myself, MySQL became a good career, allowing me to repay my college loans, for example.
If NewDB can achieve this, then New Corp. will be successful, too.

## End of the Enterprise

"Enterprise" editions and features strike me as pre-cloud and pre-open source thinking.
It harkens back to web 1.0 (or older) when big enterprises like IBM and Oracle ruled the market.
But web 2.0, open source, and the cloud have become mainstream.
Enterprise is irrelevant in today's fast-paced, digital-native market.
Speed and flexibility are paramount&mdash;increasingly so when every new business idea seems to spawn a handful of copycats.

What if there was only one "edition" of NewDB and it had _all_ features?
That immediately solves the prioritization problem, so we're off to a good start.

But without enterprise features to sell, what does New Corp. sell and compete on?
I think the answer is found in the change from products to services that has also become mainstream.

### Product and Service

It's probably more lucrative for New Corp. to offer NewDB as a _service_: a cloud-based SasS offering that requires a paid subscription (or some other payment model).
Let's call this "NewDB Service".

But the problem is: NewDB was released as an open source _product_: a standalone program that users can run wherever they like.
How can New Corp. build its product but also offer it as a service, without the latter undercutting the former in terms of usefulness and priority for product users?
To extend the analogy: how can New Corp. build a moat around NewDB _and_ a toll bridge over it to NewDB Service?

This concern is the modern-day cloud-based equivalent of enterprise undercutting community.
Therefore, the solution is roughly the same as previously stated: ensure that the _product_ remains the first priority of all development.
But there's more to it than that.

The community vs. enterprise debate centers on _functionality_: what enterprise can do that community cannot.
Enterprise sells something community cannot have or do&mdash;unless community users re-implement the functionality, which is possible but nontrivial (most database development is nontrivial).
I would argue that this makes community users feel neglected or, perhaps, cheated since (to repeat) "free users of the community edition created the market for and confidence in NewDB".

But the product vs. service debate can center on _operations_: how NewDB is operated in the cloud.
New Corp. could make clear that NewDB is designed only for cloud environments: on-demand, elastic compute and storage, auto-scaling, containerization, and so forth.
(Granted, a user with bare metal on-premise might meet these requirements, but it's unlikely.)
Then New Corp. can prioritize NewDB development for the cloud and equally serve both purposes: open source product and the paid-for service of that product.
This works especially well when there are no "enterprise" features: it's all the same database.

<p class="note">
Compete on cloud operations, not product features.
</p>

This is an opportunity for New Corp. because database _operations_ are "undifferentiated heavy lifting": exactly the kind of stuff that businesses prefer to buy rather than build.
It also helps New Corp. corner the DBaaS market for NewDB before the cloud providers attempt to (like AWS EKS and others).
Lastly, and perhaps most importantly, without enterprise features it truly avoids any vendor lock-in: NewDB Service users know that they can stop using NewDB Service but continue running NewDB on their own without any loss of functionality.
In my opinion, that is a huge win and value to users that will reduce (or eliminate) hesitancy to using NewDB Service.

I think this approach is uniquely suited to NewDB and other databases like it that are operationally complex and practically require the cloud.
It's a tough sell for MySQL, for example, because it's a single binary.
Granted, operating MySQL (or any database) requires [a lot of work](/eng/database-operations-manual/), but NewDB requires an order of magnitude more work than MySQL (but it's worth it to avoid sharding).

### NewDB Service

NewDB Service will, of course, have its own propriety code for web apps and so forth.
That's ok because NewDB Service is not open source; it does not preclude NewDB (the database) from being open source.
In my opinion, this difference is widely understood and accepted: free open source product, but proprietary service.
But this only works as long as New Corp. does not build something into the open source product that is only useful for its proprietary service&mdash;that would violate [usefulness](#usefulness) and [priority](#priority).

What stops other companies from offering their own NewDB Service?
Not much except for expense and expertise, but that is also true of the product.
But New Corp. has an unfair advantage: they make NewDB, so presumably they know best how to operate it.
Presuming New Corp. executes NewDB Service adeptly and fairly, there would be little reason for users to chose another company.
Other companies will attempt to undercut NewDB Service on price, but let them: focus on being the premium service that people want to use, not the cheap service they can afford to use.

And lest it not be said: New Corp. must never "weaponize" open source NewDB to thwart a NewDB Service competitor.
That would violate [usefulness](#usefulness) and [priority](#priority) and the trust of its users and customers.

### Who's VPC?

I think it would be best that New Corp. only run NewDB Service in cloud accounts and VPCs owned by the customer.
For example, [Buildkite](https://buildkite.com/cash) works this way.
Although this is more complex for NewDB Service at the start, it has the long-term benefit of avoiding all types of compliance requirements.
It also means New Corp. can charge only for its service and let the cloud provider bill the customer for their cloud account.
Lastly, and perhaps most importantly, it again avoids vendor lock-in: if a NewDB Service customer stops using the service, New Corp. simply disconnects and removes their pieces, and the customer retains their NewDB databases in their cloud account&mdash;but now they're responsible for operations.

## Support and Consulting

Corner the support and consulting market before Percona, Pythian, and other companies do.
These companies have proven that support and consulting alone are enough to sustain a business and employ hundreds of people.
They also have outsized impact in the market because, being independent third parties, users listen to and trust them.

They'll probably enter the support and consulting market for NewDB regardless of what New Corp. does, but if New Corp. takes this market first and does an outstanding job, it'll be more difficult for other companies to steal customers.
Plus, New Corp. has the unfair advantage of making NewDB, so customers know that New Corp. has the engineers to solve or explain every problem.

## Final Thoughts

I approach most long-term, strategic thinking and decision making by attempting to imagine myself in the future looking back at a long, successful history.
(I think that if you want to be successful, you have to be able to clearly envision future success.
If not, then it's like a ship on a long voyage without a destination.)
In this case, given where the industry seems to be going&mdash;databases built for scale out on cloud, containers, orchestration&mdash;I see NewDB winning by creating a strong open source community and ecosystem, bolstered by NewDB Service for a majority of customers who don't want to operate it themselves&mdash;which is understandable because database operations are complex.
While some business people might argue that open source NewDB is, in this case, a waste of time and money (they'd rather a pure commercial service like [SingleStore](https://www.singlestore.com/)), I think open source has proven that only it has the power to change the world.
_The internet is built on open source._
If you want to make some money and fade into history, then prioritize a commercial service; don't feign open source.
But if you want to change the world and make history, then build a true open source database and company.
