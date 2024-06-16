---
date: "2018-12-16T13:00:00-03:00"
title: "Go Channel Red Flags"
tags: ["golang", "channels", "sender-closer", "design pattern"]
lastMod: "2024-06-04T15:54:00-04:00"
aliases:
  - /post/three-golang-channel-red-flags/
---

## More Than One close()

When reviewing code that uses channels, first thing I do is search for `close()` on every channel. More than one `close()` is red flag because, unless all uses of the channel are carefully written and tested, it can lead to a panic on close of closed channel. It can also lead to strange behavior or subtle bugs because the code that didn't close the channel isn't aware the channel is closed, so send and receive on the closed channel don't have the intended effect.

Ideally, there is one and only one `close()` of a channel. Although code paths leading to that one `close()` can be numerous (e.g. app stops by OS signal, or controlled user shutdown, or handling a fatal error, etc.), it's a lot easier to reasonable about and test, especially if a bug still causes a panic on close of closed channel. Design-wise, this is a type of "single responsibility": it makes it clear which code is responsible for closing the channel.

## Channel Used to Send and Receive

Go supports `recvFoo <- fooChan` and `fooChan <- sendFoo`, but this is not commonly done, in my experience. I consider this a red flag because it's like a network connection: it requires a communication protocol and flow control. Unless those are clearly designed, a bidirectional channel can lead to elusive bugs. Therefore, we need answers to protocol questions like:

* Request and response (like HTTP)?
* Async with no ack? (i.e. fire and forget)
* Async with ack? If yes, how are out-of-order acks handled?
* Initial handshake? (in some protocols, the server initiates the handshake after the client connects)
* Which end closes the channel and when?
* Half-open "connection" handling? (one end goes away unexpectedly)

I think the legitimate use cases for bidirectional Go channels are rare.

## Channel Used for Communication and Coordination

Using a channel for communication and coordination is usually a red flag. Communication is the well known Go adage: [Share Memory By Communicating](https://blog.golang.org/share-memory-by-communicating). Coordination (aka synchronization) is handling concurrency, multiple goroutines, etc. (e.g. [Go Concurrency Patterns: Pipelines and cancellation](https://blog.golang.org/pipelines) and the links at the end).

There is a use case for communication and coordination, which I'll cover next, but in general mixing the two is often a sign that the purpose of the channel is not clear, which leads to bugs and panics. For example, if the channel is closed before communication is done, the program will panic sending on a closed channel. Or, receivers might block unexpectedly and silently deadlock the program (if there are no recv timeouts).

Since channels are lightweight, use more to keep their purpose clear. I often used `doneChan chan interface{}` as a coordination channel for lower-level code to signal that it is done (`defer close(doneChan)`). This signal is effectively broadcast to N-many higher-level code "listeners":

```go
switch {
case <-doneChan:
    // lower-level code is done
default:
    // it's still running
}
```

All code checking `doneChan` like that will be notified when the lower-level code is done. This is how [Context.Done()](https://golang.org/pkg/context/#Context) is used. The reverse works, too: high-level code makes and passes `stopChan chan interface{}` to N-many lower-level code, then the high-level code closes `stopChan` to stop all the lower-level code. This is [Context](https://golang.org/pkg/context/) in general. Channels like these are pure coordination; their purpose is clear. They are not conflated like `stopChan chan bool` and doing `stopChan <- true`: does this communicate that the receiver should stop, or that the sender has stopped?

By contrast, pure communication channels like `primeNumbers chan int` are very clear and [intention-revealing](http://www.cs.uakron.edu/~chanc/CS490/SeniorSeminar2012/Lecture%202%20-%20Program%20Style/programming%20style.pdf). It is not (or should not) be used to coordinate goroutines like `stopChan`.

However, as mentioned earlier, there is a use case for both communication and coordination: the sender-closer pattern:

```go
// https://blog.golang.org/pipelines
func gen(nums ...int) <-chan int {
    out := make(chan int, len(nums))
    for _, n := range nums {
        out <- n
    }
    close(out)
    return out
}
```

The returned channel, `out`, is closed when done so that the caller knows there are no more numbers. That example illustrates the point, but it's not the best choice in general. Let's look closer at the sender-closer pattern.

### Sender-Closer Pattern

If the example above was real code, it would be better without the channel:

```go
func gen(nums ...int) []int {
    n := make([]int, len(nums))
    copy(n, nums)
    return n
}
```

Return a slice of int, not a chan. The code is simpler, probably a lot faster, and much easier to test. The last point is key: testing. To test if the return value is correct is trivial. But to test `chan int` requires the test to drain the channel into a slice, then test that slice. In short: `chan int` is overkill in this and most cases like this.

The sender-closer pattern is best used when at least one of the following is true:

1. High cost of each value, _or_
1. High number and size of values

If the cost of fetching each value is high (e.g. slow network request, expensive database query, etc.), then it's best to fetch them only as need and when needed. The channel size is effectively a prefetch buffer: zero (non-buffered) if the cost is low and we can fetch in near real-time, on-demand; or > 0 if the cost is high and we want to fetch a few in advance to ensure the caller/receiver doesn't wait too long. This approach is more useful when combined with a coordination channel to allow the caller/receiver to stop early. In that case, we avoid fetching costly values that won't be used.

Or, if the number and size of values is very high, then it's best to stream via the channel than attempt large memory allocations. "Large memory" is relative to the app, hardware, frequency of use, etc.

The sender-closer pattern is practically required if both are true: many, large, costly values. A perfect example is [FileParser.Events()](https://godoc.org/github.com/go-mysql/slowlog#FileParser.Events) which parses a MySQL slow query log. Parsing is slow (costly) and there can be several gigabytes of events. Streaming events via a channel is the only feasible solution. And the docs are clear: "The channel is closed when there are no more events."
