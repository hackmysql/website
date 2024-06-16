---
date: "2019-03-25T11:00:00-04:00"
title: "Go Error Types"
lastMod: "2024-06-04T15:54:00-04:00"
tags: ["golang", "errors"]
aliases:
  - /post/three-golang-error-types/
---

This is not a post about Go error handling, it's a post about Go error "types": three different ways to construct and use the built-in [error interface type](https://pkg.go.dev/builtin#error). `error` is deceptively simple. When used in the ways described here, it allows us to design meaningful errors and error handling in large Go programs. Errors should be first-class citizens because when things break (and they always do), errors are the first&mdash;and often only&mdash;information we have. So make them great.

## Error Message

The most basic, and maybe most common, error is something like:

```go
if err := CheckDatabase(); err != nil {
    return fmt.Errorf("database check failed: %s", err)
}
```

The caller probably logs/prints the returned `error`, an error message like "database check failed: replication lag = 100s, expected < 1s". <mark>This type of error is completely defined by its error message string. Code should not inspect the message or make any decisions based on it because it's dynamic for two reasons.</mark> The first reason is `%s", err`: `CheckDatabase()` can return different errors, and maybe it calls functions which returns errors which it returns. The point is: there's an unknown call stack of functions returning error strings, so the final error message is highly variable. Second reason: different developers tweak and change the error message. Some day, a developer might change "database check failed:" to "CheckDatabase error:". That's fine; it doesn't affect the end result. For these two reasons, no code should rely on the content or wording of the error message. It's merely a message that should be reported to the user.

Error messages are simple but powerful. They are the nuts and bolts of most Go code because, ultimately, a human needs to see some error message. Even if the system can correct or work around the error, it should still log it so that a human is aware. Consequently, error messages need to be well-written and informative. That's a topic for another blog post, but in short: every error messages should, at least, state what check or conditions in the code resulted in the error being returned. For example, `CheckDatabase()` should return error messages like the one given above: "replication lag = 100s, expected < 1s". That clearly states the expected but observed conditions that caused the error to be returned. Note: the cause of the error is a different issue, i.e. why the replica has 100s of lag is a different issue which the code probably can't ascertain, it only knows that it should be < 1s but it's not.

Use error messages in two cases. First: when code is new or being changed frequently. In this case, it's probably not clear if or where the other two error types should be used, so defer the decision until the code is more settled. Switching from error messages to other types is usually safe and relatively easy because there's only one [error interface type](https://pkg.go.dev/builtin#error). Second: in unique or one-off error cases. For example, a program that loads a config file probably doesn't need the other error types because loading the config is a one-off event. If it fails, we only need to know why; a great error message is sufficient.

## Package Error Variable

Package error variables are idiomatically defined like:

```go
import errors


var (
    // ErrNotFound is returned when the user is not found.
    ErrNotFound = errors.New("not found")

    // ErrTooMany is returned when too many users match.
    ErrTooMany = errors.New("too many")
)
```

For example: [io](https://golang.org/pkg/io/#pkg-variables), [bytes](https://golang.org/pkg/bytes/#pkg-variables), [net/http](https://golang.org/pkg/net/http/#pkg-variables), and many others. Although these are vars, they must be treated as const. _Never modify a package error variable!_

<mark>The variable itself is what's important. Its string (error message) is usually not important or logged.</mark> Instead, the variable is used by the caller for error handling like:

```go
if err := DeleteUser(name); err != nil {
    switch {
    case ErrNotFound:
        log.Printf("user %s already deleted", name)
        return nil
    case ErrTooMany:
        return fmt.Errorf("%s matches too many users", name)
    default:
        return err
    }
}
```

If `DeleteUser(name)` returns `ErrNotFound` we just log and return `nil`, i.e. we suppress the error because delete is idempotent (or whatever reason; this is just an example). If the func returns `ErrTooMany` we wrap and return that in an new error message to add more context. In this case, perhaps we know the caller logs return errors, so we need a great error message (ironically, this one is not so great because it doesn't specify what "too many" means; better would be: "%s matches %d users, only 100 allowed"). Finally, when handling errors like this, always handle the `default` case because the errors in `DeleteUser()` can change and it can return errors from functions it calls that we cannot see (especially if it's calling 3rd-party pkgs). In this case, if we don't explicitly handle the error, we simply return the unaltered error and let the caller deal with it.

These types are errors are common because they're very powerful for both package and caller. In my opinion, they're a defining quality of a well-designed, mature package. They show that the package knows itself, so to speak. By contrast, a poorly-designed package returns a barrage of random errors&mdash;it's anyone's guess! That often indicates that the package doesn't care or handle errors well, it returns whatever and forces the caller to figure it out, i.e. the package isn't actively trying to help the caller. But when a package like [io](https://golang.org/pkg/io/#pkg-variables) has documented error variables, I know what to expect and what it means, and that helps me as the caller.

Use package error variables liberally when the code is stable enough to make it clear what kind of errors the package commonly returns. Look at Go core packages for many examples. But don't overdo it. It's perfectly fine and normal for packages to return some, or many, error messages. Package error vars should be common (frequently returned or returned by many functions) or important (something the caller should know about and handle specifically). Remember: once a package exposes an error variable, removing it is a breaking code change requiring a new minor level release.

## Custom Error Type

Custom error types are objects (struct) that implement the [error interface type](https://pkg.go.dev/builtin#error):

```go
type DbError struct {
    Schema  string
    Message string
    Code    int
}

type (e DbError) Error() string {
    return fmt.Sprintf("using %s: error %d: %s", e.Schema, e.Code, e.Message)
}
```

Custom error types encapsulate app-specific information. They are custom but also plain 'ol error types because they implement the error interface. So they can be used for the previous two types, error messages and package error variables, but they can also be used like:

```go
// In an API controller
if err := DeleteUser(name); err != nil {
    switch v := err.(type) {
    case DbError:
        switch v.Code {
	case 1836: // ER_READ_ONLY_MODE
	    http.Error(w, "db is read-only, try again", http.StatusServiceUnavailable)
	default:
	    http.Error(w, "db error: " + v.Error(), http.StatusInternalServerError)
        }
    default:
        http.Error(w, "API error: " + err.Error(), http.StatusInternalServerError)
    }
    return
}
```

The custom erorr type lets the caller do fine-grain error handling. In this example, the API controller returns HTTP status code 503 (http.StatusServiceUnavailable) if the database is read-only. A robust client will handle this code and retry the request. The custom type also injects more useful, contextual information into the error message: the schema name. Any app-specific information can be added to the custom type which helps make the error very specific and detailed.

Package error variables can be custom error types:

```go
var (
    // ErrReadOnlyDb is returned when the database is read-only.
    ErrReadOnlyDb = DbError{Code: 1836, Message: "db is read-only"}
)
```

Some Go core packages use this, but it's less common in the wild. Use sparingly and only when needed.

Use custom error types when simpler package error variables don't convey enough app-specifc, contextual information that callers need. Package error variables are usually sufficient, so wait to use custom error types until there's a need.
