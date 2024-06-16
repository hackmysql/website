---
date: "2024-03-24T17:00:00-04:00"
title: "The Fallacy of Small Functions"
tags: ["software design", "John Ousterhout"]
aliases:
  - /post/fallacy-of-small-functions/
---

Decades of computer programming advice, best practices, and books have taught that small functions are good.
That's misleading at best and counterproductive at worst: increasing complexity rather than reducing it.

For brevity, I'm going to say things are false or wrong without explaining because you already have a _fantastic_ explanation:  [_A Philosophy of Software Design_](https://web.stanford.edu/~ouster/cgi-bin/book.php) by John Ousterhout.
Everything I'm arguing here is explained in that book.

Here's an example of bad design:

```go
func serviceName(cluster rds.DBCluster) string {
	ret := serviceNameFromTag(cluster.TagList)
	if ret != "" {
		return ret
	}
 
	return serviceNameFromID(cluster.DBClusterIdentifier)
}
 
func serviceNameFromTag(tags []*rds.Tag) string {
	for _, tag := range tags {
		if strings.ToLower(tag.Key) == "service" {
			return tag.Value
		}
	}
 
	return ""
}
 
func serviceNameFromID(clusterID string) string {
	lastDash := strings.LastIndex(clusterID, "-")
	if lastDash == -1 {
		return clusterID
	}
 
	if lastDash < len(clusterID)-1 {
		suffix := clusterID[lastDash+1:]
		if _, err := strconv.Atoi(suffix); err != nil {
			return clusterID
		}
	}
 
	return clusterID[0:lastDash]
}
```
<p class="figure"><b>Example 1</b>: Three small functions (bad design)</p>

<mark>The main philosophical (and practical) problem with the three functions in example 1 is that they're all _shallow_: they don't do much.</mark>
But let's put philosophy aside for the moment and critique more practical points.

Some engineers will argue that the code above in example 1 is well designed because each function is small and does one thing.
They might even cite the "S" in [SOLID](https://www.freecodecamp.org/news/solid-principles-explained-in-plain-english): single responsibility.
But they're wrong: small functions are not inherently good software design.

What about "do one thing"?
`serviceName` doesn't: it starts by calling the second function, `serviceNameFromTag`.
And if that returns an empty string, it calls the third function `serviceNameFromID`.
So `serviceName` _itself_ does nothing: it just calls other functions.
That raises the question: what does `serviceName` _itself_ do? what is its responsibly?
Calling other functions isn't a responsibility, it's just... a program.
All programs are functions calling functions.

Another problem with relying on the fallacy that small functions are good design is that it often leads programmers to _not_ write code comments.
They argue that "If the functions are small and do one thing, they're self-describing&mdash;no code comments necessary!"
They're wrong again: code is what we want the computer to do but it does not explain _why_.

Furthermore, the programmer who wrote these functions failed to realize that the direction of thought in _writing_ the code cannot be followed by other programmers _reading_ the code.
The writer starts with a singular problem: p = "I need to get the service name from the databases cluster name."
They arrive at a three-part solution: q, r, s.

|Writer|Readers|
|------|-------|
|p &rarr; q, r, s|q, r, s &rarr; ? 😕 |

Problem is: the writer assumes that readers can from start from the solution and arrive back at the original problem.
Readers cannot.
For example, a reader cannot tell in example 1 if the other two functions serve a purpose other than being called by the first.
Is it valid / acceptable / intended that the program calls `serviceNameFromTag` or `serviceNameFromID` directly?
Nobody knows; even the original author will eventually forget.

---

Here's the same code but written with better design as a single function:

```go
// serviceName returns the service name of the given cluster so we can look up
// the service from the database cluster name. The db cluster should be tagged
// with the service name (service=name). If not, it's parsed from the database
// cluster name by dropping the "-nnn" cluster number suffix. It always returns
// a non-empty value (because a database cluster name can't be empty).
func serviceName(cluster rds.DBCluster) string {
	// Return name from service tag
	for _, tag := range cluster.TagList {
		if strings.ToLower(tag.Key) == "service" {
			return tag.Value
		}
	}
 
	// No tag; parse service name from cluster ID. This happens becuase there
    // are some legacy databases that aren't tagged. In the future, we should
    // probably make this an error to force us to finish tagging evertything.
    //
    // Db cluster name should be like "foo-001". So we find the last "-" and
    // return everything before that. But legacy databases might not conform,
    // so we handle stuff like "foo" and "foo-v2".
	clusterID := cluster.DBClusterIdentifier 
	lastDash := strings.LastIndex(clusterID, "-")
	if lastDash == -1 {
		return clusterID
	}
	if lastDash < len(clusterID)-1 {
		suffix := clusterID[lastDash+1:]
		if _, err := strconv.Atoi(suffix); err != nil {
			return clusterID
		}
	}
 
	return clusterID[0:lastDash]
}
```
<p class="figure"><b>Example 2</b>: One function, deep abstraction (good design)</p>

Example 2 is better design because function `serviceName` is _deep_ and correctly code commented.
Instead of grokking 3 small but uncommented functions, readers now have a single function that explains both what _and why_ in the comments.
For example, the previous code (example 1) doesn't mention the special case: legacy clusters that don't have standard tags or follow the naming schema.

Deep doesn't mean big; it means the implementation does more relative to its interface.
The interface here is the function signature, which is about as small and simple as it gets: one input arg, one return value.
The _implementation_ of that small, simple interface is _deep_ because it handles (and hides) several cases: the normal case (tag) and special.
The function does a lot, relatively speaking (it's a pretty simple example).

It's deep but not complex because readers can understand the problem alongside its implementation.

|Writer|Readers|
|------|-------|
|p &rarr;<br>// p<br>q |&nbsp;<br>// p<br>q|

Now that readers know _what_ the code is supposed to do (and _why_), they can more easily question _how_ (implementation) and more safely modify it (presuming it already has good test coverage).
For example, why use `strings.LastIndex` rather than a regex to truncate the "-nnn"?
Then you don't have to check for it; just truncate and return.

<br>

Small functions are not inherently good software design.
They're not inherently bad, either.
And since big functions are usually problematic, we concluded that function size is not a good guide to better software design.

When you read [_A Philosophy of Software Design_](https://web.stanford.edu/~ouster/cgi-bin/book.php) you'll learn a better and much more effective guide: reducing (or eliminating) complexity with deep abstractions&mdash;and appropriately written code comments.
