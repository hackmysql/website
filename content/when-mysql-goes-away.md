---
date: "2018-07-22T18:00:00-03:00"
title: "When MySQL Goes Away"
subtitle: "Handling MySQL errors with go-mysql/errors"
tags: ["mysql", "errors", "golang"]
comments: true
aliases:
  - /post/when-mysql-goes-away/
disqus_url: "https://hackmysql.com/post/when-mysql-goes-away/"
---

Handling MySQL errors in Go is not easy. There are _a lot_ of [MySQL server error codes](https://dev.mysql.com/doc/refman/5.7/en/error-messages-server.html), and the [Go MySQL driver](https://github.com/go-sql-driver/mysql) as its own errors, and Go [database/sql](https://golang.org/pkg/database/sql/) has its own errors, and errors can bubble up from other packages, like [net.OpError](https://golang.org/pkg/net/#OpError). Consequently, Go programs tend not to handle errors. Instead, they simply report errors:

```go
err := db.Query(...).Scan(&v)
if err != nil {
   return err
}
```

And then the error is logged or reported somewhere. This is as poor as it common, and it's extremely common. A robust program handles the error: retry the query if possible; or report a more specific error; else, report the unhandled error. But robust MySQL error handling in Go requires very specific knowledge and experience that is beyond the reasonable purview of app developers.

I created [go-mysql/errors](https://github.com/go-mysql/errors) to make robust error handling easier. The key word is "easier" not "easy" because in the course of writing this package I rediscovered how weird MySQL error handling in Go can be, and that is what we explore in this blog post.

## Scope

First, we must narrow the scope. We cannot and should not handle _all_ errors. In my experience, well-behaved production apps do not encounter 99% of MySQL errors. The 1% of errors encountered are:

* Connection-related
* MySQL is read-only
* Duplicate key error

From bottom to top, starting with duplicate (dupe) key errors. This could be the subject of a separate blog post, so I won't go into much detail here. In short, an application should be designed to handle dupe key errors. This requires clear design around the primary key and secondary indexes of every table, and considering when/where/why duplicate data could exist, and finally: what to do about it. Sometimes, duplicate data is not an error but expected, part of normal operation. In that case, [ErrDupeKey](https://godoc.org/github.com/go-mysql/errors#pkg-variables) is not really an error. A robust application handles duplicate key errors.

MySQL being read-only often indicates a transient operation, like a failover, that is changing which MySQL instance is active/primary/writable. Presuming MySQL is supposed to be writable, [ErrReadOnly](https://godoc.org/github.com/go-mysql/errors#pkg-variables) is more signal than error, the signal being: "Wait and retry." Every non-clustering high availability solution for MySQL (that I'm aware of) requires toggling read-only for operations. Consequently, `ErrReadOnly` is very common in production. However, apps do not always handle it because you need to know the specific MySQL error code &mdash; I don't even remember it and I've been using MySQL for almost 15 years! Another gotcha: there are _two_ MySQL error codes that mean "read-only". With [go-mysql/errors](https://godoc.org/github.com/go-mysql/errors) they are both reported as `ErrReadOnly`, which I find to be a lot easier to remember.

When MySQL "goes away" (becomes unavailable) [1], it's anyone's guess which error results or whether it's actually a MySQL error and not something else. A robust application must know and handle the error, usually by waiting and retrying. Sometimes, telling the user to try again is acceptable. Other times, it can cause user anxiety if, for example, the user is sending money. In this case, the application must retry if MySQL "goes away" which, like read-only, is very common in production for high availability operations. [CanRetry](https://godoc.org/github.com/go-mysql/errors#CanRetry) simplifies this: it returns true for all MySQL connection- and query-related errors, including `ErrReadOnly`. It presumes MySQL should and will be online soon.

<small>[1] "MySQL has gone away" is wording from [Perl DBD::mysql](http://search.cpan.org/~capttofu/DBD-mysql-4.046/lib/DBD/mysql.pm). I use it here jokingly because it's anthropomorphic, as if MySQL took a vacation or something.</small>

Connection errors are the focus because the [Go MySQL driver](https://github.com/go-sql-driver/mysql) handles them in ways you might not expect but need to know. Let's make MySQL "go away" and see what happens...

## Error Cases

As of Go 1.9 we have [sql.Conn](https://golang.org/pkg/database/sql/#Conn), but go1.9 is less than one year old as of this writing, so it's unlikely the world has done a mass migration from `sql.DB` to `sql.Conn`. Therefore, let's start with [sql.DB](https://golang.org/pkg/database/sql/#DB) and look at `sql.Conn` later. All the examples in this section use `sql.DB`, like:

```go
db, err := sql.Open("mysql", "user:password@/dbname")
if err := db.QueryRow("SELECT connection_id()").Scan(&id); err != nil {
```

`db` is a `sql.DB` connection pool managed by the driver, [go-sql-driver/mysql](https://github.com/go-sql-driver/mysql) and [database/sql](https://golang.org/pkg/database/sql/).

For each error case below, a table is given: the first column is the [go-mysql/errors error variable](https://godoc.org/github.com/go-mysql/errors#pkg-variables) that function [Error](https://godoc.org/github.com/go-mysql/errors#Error) returns; the second column is the default Go error string and data type. The default errors are varied. The `go-mysql/errors` are easier to use and more consistent.

#### When MySQL Is Offline

| go-mysql/errors | Default Error String (Type) |
| --------------- | ------- |
| `ErrCannotConnect` | "dial tcp \<host\>:\<port\>: connect: connection refused" (`*net.OpError`) |
| `ErrCannotConnect` | "dial unix \<socket>\: connect: no such file or directory" (`*net.OpError`) |


When MySQL is offline (i.e. not running or unreachable for any reason), it's a network error. If MySQL was offline before any use of the `sql.DB`, this is the only error. For example, if an app comes online before MySQL does, the app will get `ErrCannotConnect` errors. But probably more common is the next error case...

#### When MySQL Goes Away

| go-mysql/errors | Default Error String (Type) |
| --------------- | ------- |
| `ErrConnLost` | "invalid connection" (`error`) |

If MySQL was online and the `sql.DB` had successfully connected and executed anything, then MySQL goes offline, it's a generic "invalid connection" error. `ErrConnLost` makes this more clear: the app was connected to MySQL, but now it's not.

"Why was the connection lost?", is a common question app developers want the driver to answer, but it cannot because the cause/reason is outside the driver. In other words: the driver doesn't know. Here are some possible reasons:

* MySQL was stopped manually by a human
* MySQL was stopped automatically by tooling
* MySQL crashed
* OS crashed
* Hardware crashed
* Network switch crashed
* Data center crashed (it happens!)
* Human error
* Machine error

MySQL could be perfectly fine, but the salient fact for the app is: the MySQL connection has been lost. The app should try to reconnect (in a controlled manner; don't cause a [thundering herd](https://en.wikipedia.org/wiki/Thundering_herd_problem)).

#### When MySQL Shuts Down

| go-mysql/errors | Default Error String (Type) |
| --------------- | ------- |
| `ErrConnLost` | "Error 1053: Server shutdown in progress" (`*mysql.MySQLError`) |

MySQL returns a specific error code when shutting down: 1053. My experience has been that most people don't know this and even fewer handle it. Even the driver does not handle it, which means it does not mark the connection invalid. This will be explained later in section "Dead Connection Pool". The end result will be a lost connection, hence `ErrConnLost`.

#### When The Connection Is Killed

| go-mysql/errors | Default Error String (Type) |
| --------------- | ------- |
| `ErrConnLost` | "invalid connection" (`error`) |

Tools, query snipers, DBAs, etc. can [KILL](https://dev.mysql.com/doc/refman/8.0/en/kill.html) connections, which causes a generic "invalid connection" error. Currently, there is no way to tell that the connection was killed with `KILL` versus MySQL going offline for other reasons mentioned above. All the driver knows is that the connection was lost, hence `ErrConnLost`.

`KILL` is the same as `KILL CONNECTION`.

#### When The Query Is Killed

| go-mysql/errors | Default Error String (Type) |
| --------------- | ------- |
| `ErrQueryKilled` | "Error 1317: Query execution was interrupted" (`*mysql.MySQLError`) |

`KILL QUERY` causes a specific error code (1317), but I think the default error message (above) is a little vague because "interrupted" implies that the interrupted thing will resume after the interruption. It's like, "We interrupt this program to bring you breaking news...", implies that the program will resume after the breaking new. The query will _not_ resume; the app must re-execute the query. This error does not affect the transaction, so the app does not need to roll back. Only the one query that gets this error was killed. Previous queries and their results, the transaction, and the connection are all ok.

## Dead Connection Pool (DCP)

When MySQL goes offline, there will be N number of `ErrConnLost` errors, where N = [MaxOpenConns](https://golang.org/pkg/database/sql/#DB.SetMaxOpenConns), followed by `ErrCannotConnect` errors until MySQL is back online.

Understanding DCP behavior is important. If N = 100 and MySQL goes offline, the app will get at most 100 `ErrConnLost`, then `ErrCannotConnect`. ("At most" because the driver only opens connections as needed. If N = 100 but only 50 connections were needed, then only 50 `ErrConnLost`.) This happens because the driver does not automatically retry lost (invalid) connections. First, it marks the connection "invalid" and returns an error. Later, when the invalid connection is reused, the driver tries to reconnect and that's when it returns `ErrCannotConnect`. This means apps will produce a flurry of `ErrConnLost` overlapping with some `ErrCannotConnect` until the connection pool is dead: all connections are marked invalid.

_Exception_: the driver does not handle "Error 1053: Server shutdown in progress", so it does not mark the connection invalid. Consequently, this error does not account toward N `ErrConnLost` errors. For example, with N = 1 the errors are:

1. `ErrConnLost` ("Error 1053: Server shutdown in progress")
2. `ErrConnLost` ("invalid connection")
3. `ErrCannotConnect`

There is no `ErrServerShutdown` because it's not actionable: by the time the app receives error 1053, the connection is already lost.

## sql.Conn (go1.9+)

| go-mysql/errors | Default Error String (Type) |
| --------------- | ------- |
| `ErrConnLost` | "driver: bad connection" (`driver.ErrBadConn`) |

[sql.Conn](https://golang.org/pkg/database/sql/#Conn) returns "driver: bad connection" after "invalid connection". For a `sql.Conn`, when MySQL goes away the errors are:

1. `ErrConnLost` ("invalid connection")
2. `ErrConnLost` ("driver: bad connection")
3. `ErrCannotConnect` or reconnect if MySQL is online

This changes DCP behavior for apps using `sql.Conn`: there will be N * 2 number of `ErrConnLost` errors before `ErrCannotConnect` errors.

More importantly: "driver: bad connection" does not always mean MySQL is offline; it can be a false-positive error. For example, on `KILL`:

| sql.DB | sql.Conn |
| ------ | -------- |
| `ErrConnLost` ("invalid connection") | `ErrConnLost` ("invalid connection") |
| Query OK | `ErrConnLost` ("driver: bad connection") |
| &nbsp; | Query OK |

The first error is the same and expected because we killed the connection. `sql.DB` recovers immediately ("Query OK"), but `sql.Conn` returns a second error before reconnecting and executing the query. The second error is false-positive&mdash;MySQL is online&mdash;but there is no way for an app to determine this. All an app can and should do is retry.

## Conclusion

Handling, rather than simply reporting, MySQL errors in Go is not trivial. Error cases, dead connection pool behavior, and `sql.Conn` described here give a sense of the complexities. If you're curious, look at the [source code](https://github.com/go-mysql/errors/blob/master/errors.go) for the all the details. If you're a developer using Go and MySQL, [go-mysql/errors](https://github.com/go-mysql/errors) will greatly simplify and improve MySQL error handling. It provides more than shown here; check out the [documentation](https://godoc.org/github.com/go-mysql/errors).
