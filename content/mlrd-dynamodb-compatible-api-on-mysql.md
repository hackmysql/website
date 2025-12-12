---
date: "2025-12-12T16:39:00-05:00"
title: "mlrd: DynamoDB-Compatible API on MySQL"
tags: ["mysql", "mlrd"]
comments: true
---

Introducing [`mlrd`](https://mlrd.tech/) ("mallard") to the world: a DynamoDB-compatible API on MySQL.
Crazy, but it works really well and I'm confident it will help a lot of business save a lot of money.
Here's why.

<!--more-->

## Preamble

Let me be clear about two things from the start:

1. `mlrd` is _not_ free open source; it's a commercial database tool.
Why, after 20 years of publishing free open source tools?
Two reasons.
First, because I have bills to pay, too.
Second, because you can _somewhat_ reverse engineer `mlrd`.
Emphasis on "somewhat" because a complete solution like `mlrd` is _a lot_ more difficult than it seems.

2. Amazon DynamoDB is a great database product.
It really is an engineering marvel.
If you're using it and happy with it (all aspects, from its costs to its single-vendor nature), then great!
Stop reading and keep using it.

## Problems and Progress

`mlrd` solves three problems:

1. DynamoDB costs can easily skyrocket out of control
2. Vendor lock-in
3. Data hostages

The first two are plain and obvious to anyone using DynamoDB beyond trivial tables.

The third was what kept me motivated and going while I programmed `mlrd` all by my lonesome: once you put _your data_ into DynamoDB, there is absolutely no way to get it back without paying AWS a little something.
DynamoDB holds your data hostage.

As someone practically born into the world of open source and the good/positive/legal computer hacker ethos, I couldn't ignore this.
And being a hacker, I tried to find a loophole, a trick, a hack&mdash;_some way_ to access data in DynamoDB without paying a single RCU.

I couldn't find one.[^1]

[^1]: My most clever idea: using errors to exfiltrate my data. Didn't work.

So I have to hand it to AWS: their DynamoDB billing is airtight.
And in their (AWS) defense, DynamoDB table dumps are relatively cheap: $0.10 per GB plus PITR costs.

But a hostage is hostage no matter how small the ransom demand.

`mlrd` doesn't just free the data hostages, it shatters the vendor lock-in, too.

For example, once you put `mlrd` between your app and DynamoDB, since `mlrd` speaks the DynamoDB protocol and knows all the DynamoDB nuances, you can _freely_ write items to MySQL as they're read or written in DynamoDB.
("Freely" means paying no extra RCUs or WCUs. If your MySQL is also on AWS, that could incur read/write costs.)

## Security Scanning

A really good practical example and use case that `mlrd` enables without breaking the bank is security scanning.

Some companies proactively scan data to make sure devs didn't accidentally store sensitive data, PII, and so on.
But how do you do this in DynamoDB without paying more RCUs or CDC costs?
In DynamoDB you cannot.

But with `mlrd` you can because, as noted above, `mlrd` gives you free access to your data.
Some companies will use `mlrd` for no other reason than to freely inspect their data.

`mlrd` can do a lot more than this, but as long as it's helping companies _make progress_, then all those hours spent talking to myself while coding it will be worth it.

## Costs

I don't know yet how `mlrd` will be priced, but as a private pico-sized corporation, I expect it will be miniscule compared to the [millions of dollars some companies pay for DynamoDB](https://www.uber.com/en-CA/blog/dynamodb-to-docstore-migration/).

The real question is: what does MySQL cost you?

If you're running bare metal, you're in luck!
Bare metal enterprise hardware plateaued a few years ago.
For example, years ago 32 cores and 256 GB RAM were common.
Today, I have a few 1U servers like that (and more powerful) in my basement, and they were cheap.

What would cost me $100,000/year on DynamoDB costs me _zero_&mdash;yeah, $0&mdash;to run in my basement.[^3]

[^3]: Unless you want to amortize a $2,000 server over 4 years, then it costs $500/year.

"Oh come on, Daniel! You know that DynamoDB is highly resilient and highly available! Your basement servers are just loud toys."[^2]

[^2]: I like the sound of a few 1U rack servers.

[Yeah, maybe.](https://dev.to/aws-builders/dynamodb-outage-why-multi-cloud-fails-startups-and-real-dr-wins-15cb)

You can't run your business from my basement, but you can literally bank on [PlanetScale](https://planetscale.com/). 
When you contact me to discuss `mlrd` in more detail, I'll show you PlanetScale + `mlrd` can be 40&ndash;60% cheaper than DynamoDB.

## Private Beta

Check out the 2 minute video at https://mlrd.tech.

No AI slop; just me, my laptop, and my servers.

If you/your company has these problems, get in touch and let's see if `mlrd` can help fix them.
