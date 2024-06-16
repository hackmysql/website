---
date: "2017-08-20T11:20:00-07:00"
title: "How To Test the Database"
subtitle: "It's important but not special"
tags: ["software design", "testing", "database"]
aliases:
  - /post/how-to-test-the-database/
---

"How do I test the database?" is a question I've been asked by colleagues many times. There's a good, clean solution, but let's first step back from what seems to be the problem to unpack why "testing the database" is not special (but nonetheless important). In other words: colleagues don't ask, "How do I test such-and-such package?", because that's common and well understood. The question about testing the database implies that the database is a special beast that, if not treated properly, will devour the developer in their sleep.

## Challenges

### External System

One reason testing the database seems difficult is because it's an external system. The developer probably has an instance running on their laptop, but what about the CI system, staging, and production? Staging and prod presumably already have database instances, so the real challenge is programmatically setting up and tearing down a database in the test suites. The answer is: sandbox. [MySQL Sandbox](https://mysqlsandbox.net/) is a great example. In general, there are four solutions:

1. Preexisting sandbox solution (like MySQL Sandbox)
1. Roll your own sandbox with scripting (e.g. Bash) and the database binaries
1. Spin up db instances in the cloud (e.g. Amazon RDS, Google Cloud SQL, etc.)
1. If using a hosted CI solution, see if they offer database instances

It can be a lot of upfront work, but if set up well it's usually not much to maintain going forward, and the benefits more than surpass the initial effort. It's even possible (and sometimes necessary) to test against multiple versions of the database. So set up for multiple db versions and variations. You'll thank yourself later.

### Code-Database Separation

A second reason testing the database seems difficult is less about the database and more about the code that uses the database. The problem arises when the code under test makes a database call:

![Database Call](/img/db-call.svg)

This mélange is very common and tends to works ok when kept this simple, but there are issues and a better way. The primary issue is: what is being tested? Presumably the function logic, but implicitly and indirectly the complete database access is being tested, too. By "complete" I mean the code calling the database, the query, the database itself, and the data from (or to) the database. When there's a bug in this function, it could be related to database access, or function logic given the data, or both due to concurrency, race conditions, database locking, database transactions, etc. (We'll explore this later.) Consequently, function logic and database access are tightly coupled, and tight coupling is usually poor software design. So what's a better way?

## A Better Way

Put aside databases for a moment, and let's think about programs and data flow:

![Data In, Data Out](/img/data-in-data-out.svg)

Programs are largely "data in, data out". Data (input) is passed to a function (or some block of code) which acts on the data and returns other data (output). Of course, there's a lot more to code than this (mutating data, storing data, transferring data, etc.), but when it comes to databases this is usually what's happening. (_Usually_, but not always, which we'll explore later.)

Therefore: <mark>separate data from logic, where "data" entails all code necessary to fetch or store the data.</mark>

![Testing Data In, Data Out](/img/testing-data-in-data-out.svg)

The image above illustrates a better way to test "Some Function" by factoring out the "Database Call" and, instead, passing input data into the function and testing its output data. The input data is, of course, whatever the "Database Call" call would fetch. This requires more work to create real or mock input data, but the benefits outweigh the effort.

One benefit is: testing the function is faster (no database call) and cleaner. By "cleaner" I mean that the test tests only whatever the function is supposed to do. If there's a bug in the function, it cannot be database-related. This makes the function easier to understand, reasonable about, fix, and maintain. Your future self and future coworkers will thank you!

A second benefit is: we can test edge conditions and bad data. Databases usually contain and enforce good data, so trying to coerce a database to contain and return bad data for the sake of testing adds extra work to an already tedious process. But without the database, we're free to pass in a dumpster fire of input data and see how the poor 'ol function copes.

Strangely, the real world is neither perfect nor ideal, so this clean separation isn't always possible, but it remains nevertheless the goal.

## But Wait, There's More!

The data-logic separation goes beyond databases. For example, another testing challenge developers ask me about is testing system commands. Let's imagine a program need to work with `ifconfig`. So the program needs to

1. Run `ifconfig` to get its output
1. Parse the output
1. Do something with the parsed output

The end goal is #3, so often there will be one function which does #3 by also doing #1 and #2. This is more challenging to test than a database because `ifconfig` output differs, and the path to the binary can differ, too. Controlling all this in a test when it's all lumped into one function is usually not possible. The solution is the same: separate the data and the logic.

In this example, #1 is akin to the database. It's an external system that yields data. So isolate that code. Have a function or package or something that does nothing more than run `ifconfig` and return its _raw_ output. Then have a second function or package that takes output from #1 (i.e. raw `ifconfig` output) as input, parses it, and returns a data structure. Finally, a third func/pkg takes that data structure as input and does whatever #3 is supposed to do. The 2nd and 3rd funcs/pkgs will be easy to test. Testing the fun/pkg that actually runs `ifconfig` can be tricky if it has to work on a wide spectrum of systems, but the challenge is nonetheless tractable.

## Testing the Database, For Real

At some point we should test complete database access. Redrawing the previous image (above):

![Testing the Database](/img/testing-the-database.svg)

For dev and CI, the database is a sandbox instance. For stage and production it's a stable instance. In all cases, the database should be _real_. For example, if MySQL, then "real" means actually running `mysqld`. I stress "real" for two reasons.

### Myriad Aspects

First, even simple data stores like [Redis](https://redis.io/) are subtle and nuanced in non-obvious ways. Relational databases like MySQL and feature-rich document stores like MongoDB have myriad aspects that affect the code under test:

* Locking (table, row; collection, document)
* Transactions
* Transaction isolation levels
* Concurrency, in general and wrt locking and transactions
* "Strict modes"
* Data transformations and conversions (e.g. character sets)
* Character sets
* Deprecated features and syntax
* Differences between versions
* Bugs in the database
* Connection timeouts and limits

And more. There's no way for a test to simulate those aspects of the database, which is why it's important to test the database for real. But as we've been discussing, _only_ the database access should be tested: load test data into the db, test the function that fetches that data, and make sure the function returns the correct data.

More challenging but still possible is to test the code while inducing some of the database aspects listed above. For example, after loading test data into the db, the test could make a separate connection to the db and lock all the rows, then call the code under test to see if it times out properly.

### Please Do Not Wrap the Database Driver

Second reason I stress "real": _please, do not wrap the database driver_. Do not attempt to escape the extra work of setting up sandbox instances and dealing with the myriad aspects of a real database by wrapping the database client driver so that you can pass code under test a mock driver that simulates database access. This is a pretty extreme measure, so if you haven't seen it, it's like:

![Database Driver Wrapper](/img/db-driver-wrapper.svg)

At top, you have only the database driver with, for example, two methods: `Connect()` and `Query()`. At bottom, you have what strives to be a transparent wrapper, `MyDriver`, around the real driver. `MyDriver` has the same methods at `DbDriver` (not shown), so its code is mostly:

```go
func (my *MyDriver) Connect() {
    return my.realDriver.Connect()
}

func (my *MyDriver) Query() {
    return my.realDriver.Query()
}
```

Why do this? The intent is to define an interface that `MyDriver` implements, then pass around the interface type (instead of the low-level `DbDriver` type) which allows us to have a `MockDriver` for testing. Good intention but, in my humble opinion, 1) its _way_ more work and trouble than it's worth especially because 2) there's a better, more clean design.

> But what about one of my favorite adages: "Most problems in software can be solved by one more layer of abstraction."? Yes, this is one more layer of abstraction, but that adage doesn't mean "abstract whatever, wherever."

Take a look at the [Go SQL driver](https://golang.org/pkg/database/sql/). Wrapping that fully is a lot of work, and getting it right (i.e. not introducing bugs in the wrapper), is a lot of work. All that work when we don't even need the wrapper. Going back to `GetData()` (above), that method (with a better name) is or should be part of a package or component that provides higher-level, domain-specific functionality. Let's pretend it's a [repository](https://msdn.microsoft.com/en-us/library/ff649690.aspx):

```go
type DataRepo interface {
    GetData()
}

//
// Implementations of DataRepo
//

type MySQLDataRepo struct {}
type FileDataRepo  struct {}
type MockDataRepo  struct {}
```

That's all very generic and poorly named, but you get the point. `MySQLDataRepo` uses the low-level driver whereas the other implementations do not. To test the database for real, we test `MySQLDataRepo`.

## When the Database Isn't Data

Earlier I mentioned "Programs are largely "data in, data out". ... when it comes to databases this is usually what's happening. (_Usually_, but not always, which we'll explore later.)". Let's explore this now.

Apart from its data, a database is just another service, and as such it needs to be configured. For example: replication. So what if we need to programmatically configure and enable replication? In that case, we need a service.

![Data, Logic, Service](/img/data-logic-service.svg)

We've talked extensively about data and logic; a third broad category is "service". Almost everything in a program is one of these three, so it's a helpful way to think about and breakdown a program from a _very_ high level. In other words, we ask: "Is this a matter of data, logic, or service?" A service, as its name implies, provides some kind of service, i.e. it _does_ something. A service is defined by what it _does_, whereas data is defined by its structure and content (i.e. the data itself), and logic is defined by its rules, flow control, etc. (I'm glossing a lot since this blog post is already pretty long.)

Therefore, when MySQL is being treated as a service (and not a source of data), create a new service in the code like:

```
type MySQLConfigurator interface {
    EnableReplication()
}

//
// Implementations of MySQLConfigurator
//

type RealMySQLConfigurator struct {}
type MockMySQLConfigurator struct {}
```

Again, poorly named but you get the point. `RealMySQLConfigurator` would actually connect to MySQL and attempt to do whatever, whereas `MockMySQLConfigurator` can be used to test code that uses a `MySQLConfigurator` because that code, being cleanly separated and unconcerned with implementation details, doesn't need a real MySQL instance. This also allows us to simulate service failures in `MockMySQLConfigurator`, which is typically very difficult with a real database.

## Conclusion

There are good, clean solutions for testing the database. If the database is a source of data (the usual case), factor out data access (e.g. [repository](https://msdn.microsoft.com/en-us/library/ff649690.aspx)). If the database is being treated as a service, create a service class/package/component that exposes service abilities and hides the implementation details (e.g. actually reconfiguring the database).

As with most software design and development, a clean solution is a matter of separating the "parts", concerns, roles, and responsibilities. One way to help do this from a very high level is thinking of software in terms of data, logic, and services. When code mixes these too much&mdash;for example, a function that handles both data (access) and logic on that data&mdash;you'll know it because it will feel difficult to test. That feeling is "code push-back", or "the code pushing back" (or "code smell"). Don't ignore it; there's a better way, as hopefully this post began to demonstrate.
