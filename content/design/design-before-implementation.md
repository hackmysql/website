---
date: "2017-08-01"
lastMod: "2024-06-05T11:51:00-04:00"
title: "Design Before Implementation"
subtitle: "Why great software design requires form before function"
tags: ["software design"]
aliases:
  - /post/design-before-implementation/
---

Like most software engineers, I review my colleagues' code. I rarely provide feedback on implementation details because developers rarely choose obviously bad implementations. I focus my attention on design rather than implementation for one simple reason: implementation details are easy to change when software is well designed. Or, from the business perspective, design is the most costly aspect of software to change, so I review for great and therefore cost-effective design.

"Design" in this context is a broad; let me clarify. By "design" I mean the "boundaries", or "contours", or "seams" of any part that uses or is used by another part. Here, "part" is also broad, meaning everything from a single function (usually the smallest part of software), to a class, to a package, to the highest conceptual levels of the system (e.g. two APIs or services in a distributed system). Therefore, we can say: _software design concerns the delineation and interaction of software parts_.

Let's consider the classic antithesis: [spaghetti code](https://en.wikipedia.org/wiki/Spaghetti_code). It's probably safe to say that we've all experienced this kind of painful software. At first it's difficult to articulate why it's painful, we just feel that the code is messy and difficult to work with. The reason is blurred or nonexistent lines between the parts or, in the extreme, having no delineated parts in the first place. (The extreme is usually not the case. Most developers manage to break down code into package, classes, and functions at the least.) If the spaghetti code works, it's difficult to reproach because the traditional argument is "function before form", but I think great software design requires the opposite: form before function&mdash;design before implementation.


As stated above, design concerns the delineation and interaction of software parts. As such, it creates logical separations. A [bulkhead](https://en.wikipedia.org/wiki/Bulkhead_(partition)) is a useful analogy. Software design concerns the creation and placements of bulkheads. The purpose of bulkheads are to isolate parts of a ship, so that when the Romulans blast a hole through the ship, the whole crew isn't blown out into space, only the unfortunate crew members in affected decks and sections (presuming they weren't first vaporized by the disruptor). Software is a starship and logical bulkheads should exist between every part for two reasons.

First, logical bulkheads delineate the parts. It seems silly but most programs and programmers cannot delineate the parts of a program or system. Let me switch the analogy to a car. When I say "alternator", every mechanic knows exactly and precisely the part. The same is true for every part of a car, even parts that are tightly couple to other parts: piston, piston ring, crank, cam shaft, master brake cylinder, break lines, rotors, calipers, lower control arms, anti-sway bar, exhaust manifold, catalytic converter, muffler, fuel pump, fuel rail, fuel rail pressure release valve, fuel injectors, evaporative gas return (EGR) line, etc.

If we designed cars like we designed software, we would have to empty the gasoline and drain the coolant in order to change the oil. That's completely absurd, yet to change the "software oil" often requires similar absurdities because the software is poorly design, i.e. poorly delineated.
<mark>The first goal of software design is delineating the parts.</mark>

<p class="note">
Delineating the parts of software yields further benefits. Since these benefits are outside the scope of this article, I'll just throw them out there for the curious to ponder: purpose, placement, and responsibility. Thinking of an alternator again, being delineate is necessary but not sufficient; it has a purpose, a particular placement (physically), and a responsibility. These three aspects explain the existence of an alternator. If any of the three was missing, a car wouldn't have an alternator. For example, electric cars (like a Tesla) don't have a fuel pump because, obviously, it serves no purpose. The part is delineated but lacks purpose in an electric car, thus it doesn't exist.
</p>

Second, logical bulkheads allow implementation to vary without affecting adjacent parts. There are two parts to this because delineating a part requires defining its external or public API _and_ its internal implementation of that API.

Earlier I said: _software design concerns the delineation and interaction of software parts_. We've addressed delineation; here, it's the public API of a part that determines and defines its interaction with other parts. This is a large subject about which books have been written, so I want to focus on something much smaller: the importance of being able to vary implementation.

One truth that's often not sufficiently factored into software development is: **everything changes**. Requirements, features, bugs, data sizes, protocols, dependencies, etc.&mdash;like a living organism, software is constantly changing. The only time it ceases to change is when it's dead. This creates a tension: on the one hand, we want well delineated parts, but on the other hand everything changes. How can we be delineated _and_ fluid?

Experience teaches us that _what_ a part does (part of its delineation) changes far less frequently than _how_ it does whatever it does (its implementation). To use an alternator again: the "what" of an alternator has been more or less constant for decades: convert mechanical energy to electrical energy. _How_ this is done can vary as long as the "what" is achieved. For example, an alternator could actually be a very strong, fast mouse inside running in a wheel that's generating the electrical current. The engine and battery don't care or know _how_ (the mouse), only _what_.

Similarly, well delineated software parts establish _what_ by their public APIs. A part can do _this_ (its "what"), and exposing only that it's free to hide and vary its implementation (its _how_) behind the bulkhead of its public API. As a result, the implementation becomes a less important detail because it can be changed without affecting adjacent software parts. But by contrast, changing the public API of a part is difficult because it modifies the delineation of the part and all adjacent parts&mdash;it moves the bulkheads.

That's the long explanation. The shorter explanation is this: when reviewing code, first I want to ensure that _all_ parts of the software are well bounded (delineated) and understood. When that is true, the implementation of those parts can vary with little effort, and I know they will; but delineations (and their attendant aspects: purpose, placement, and responsibility) are costly to change once put into production.
