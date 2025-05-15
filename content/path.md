---
type: path
date: "2025-04-21"
title: "An Efficient Path to Learn MySQL Performance"
tags: ["mysql", "conference", "video", "slides"]
params:
  dontFeed: true
---

## Conference Presentations 

|Video|Slides|
|-----|------|
|MySQL Performance for Application Developers @ MySQL and HeatWave Summit 2025<sup>&dagger;</sup>|[mysql-summit-2025.pdf](/mysql-summit-2025.pdf)|
|MySQL Performance for Developers @ Percona Live 2023<sup>&dagger;</sup>|[PL23.pdf](/PL23.pdf)|
|[Efficient MySQL Performance @ Percona Live 2022](https://www.youtube.com/watch?v=1C6thrnoGU0)|[PL22.pdf](/PL22.pdf)|
|[Efficient MySQL Performance @ FOSDEM 2022](https://archive.fosdem.org/2022/schedule/event/efficient_mysql/)|-|

<p>&dagger; Video recording not available</p>

## What Is the Path?

The path is an ordered sequence of MySQL topics to learn in order to understand and improve MySQL performance.
It's shown to the left (or below on small screens): start by learning topic 1 (query response time), then proceed topic by topic until the end, topic 9 (cloud performance).

A path is important for the same reason people don't typically learn calculus before algebra: certain topics are foundational, and topics build upon topics.
Moreover, any sufficiently complex subject contains a vast jungle (or maze) of topics, and it's usually not self-evident where one should start or where they should go next.
The end goal might not even be clear, which leaves one wandering or adrift.

MySQL performance is no different: it's a vast and complex maze of topics.
Over [20 years hacking MySQL]({{< ref "lessons-from-20-years-hacking-mysql-part-1" >}}), I watched programmers learn MySQL performance in an almost haphazard manner&mdash;myself included.
Even though I was surrounded by MySQL experts, I learned MySQL performance mostly by wandering until I had covered _all_ topics&mdash;like solving a maze by taking _all_ paths.
That works, but it's the least efficient method.

I wrote _Efficient MySQL Performance_ to teach programmers MySQL performance.
The keyword is _teach_.
Most technical books I've read don't teach, they just provide information.
Here's an analogy to explain the different:

* Teaching is like a list of ingredient, a recipe, and an experienced chef who guides you
* Providing information is like a list of ingredients

If you have no idea how to bake a cake, then a list of ingredients is still very helpful.

_Efficient MySQL Performance_ guides you along the path.
It distills 20 years of experience into 344 pages.
It _teaches_ you MySQL performance from foundation (query response time) to the cloud.

But many people don't read books.
That's okay&mdash;I don't either for certain subjects.
When we don't need to go deep on a subject, just a path and some pointers are helpful.
That's what the path is on this website.

## Page Structure

Each page along the path has the same structure:

Context
: Why learn this topic?
What does it have to do with MySQL performance?
How does it related to other topics?
The context answers these question.
At least read the context, key points, and pitfalls.

Key Points
: A bullet list of the most important ideas and knowledge for the topic.
At the very least, professional application developer working with MySQL need to know these points.
But more study is required to fully understand some of the points.

Pitfalls
: Common or high-risk problems to avoid.
Like key points, professionals should at least know these pitfalls.

Hack MySQL Articles
: Pages on this website related to the topic.
These pages are unordered and vary in technical depth.
They don't teach the topic, they supplement it with special information not found elsewhere.

Additional Resources
: Other books, blogs, videos, and so forth related to the topic.
These resources are curated: they're accurate and from credible sources.
If there's a relevant section in the MySQL manual, it's listed first.
Like the pages on this website, these resources don't teach the topic, they supplement it.
