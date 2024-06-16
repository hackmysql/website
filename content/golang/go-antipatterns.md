---
date: "2017-06-03T18:51:14-07:00"
title: "Go Antipatterns"
summary: "'Go Antipatterns' describes bad Go code and how to make it better."
tags: ["golang", "antipatterns"]
---

These Go lang antipatterns are inspired by [SQL Antipatterns](https://pragprog.com/titles/bksqla/sql-antipatterns/). Antipattern Go code is syntactically correct, but there's a better way that's both functionally equivalent and [idiomatic]({{< ref "idiomatic-go.md" >}}).

These are guidelines not absolutes. For example, [Generic Package]({{< relref "#generic-package" >}}) is common in practice and often difficult to avoid. Spending significant time trying to rename a `util` package can quickly amount to bikeshedding. Therefore, the antipatterns are divided into three classes: critical, important, and stylistic.

## Critical

Critical antipatterns affect fundamental, difficult-to-change aspects of software design, functionality, or testing. As such, they are difficult to change later, so they should be fixed immediately.

### Writable Read-only Value

```go
//
// Antipattern
//
func Load(&config)
```

```go
//
// Better
//
func Load(config)
```

If an argument should not be modified, then don't allow it to be modified by passing a pointer; instead, by the argument by value. This prevents accidental modification and signals to developers that the function doesn't modify the argument. But when a function is intended to modify the argument, pass a pointer to signal this to developers.

Another way to think about this: if Load() should not modify the caller's config, then preclude even the possibility by passing config by value. Otherwise, subtle and difficult bugs are possible when Load() mutates the config in wrong or unexpected ways causing the app to break or, worse, run like it's ok for awhile then crash later.

### Promiscuous Interface

```go
//
// Antipattern
//
type ObjectFinder interface {
    Query(query string) []string
}
```

```go
//
// Better
//
type ObjectFinder interface {
    Databases(app string) []string
    Servers(dc string) []string
}
```

Interfaces provide _discrete_ functionality; they "specify the behavior of an object: if something can do this, then it can be used here." ([Effective Go](https://golang.org/doc/effective_go.html)) Methods like Query() allow the interface to do anything, making it difficult to test and mock. It also tends to leak logic: for the antipattern, the caller must know how to query for specific objects, but this logic (query syntax and semantics) is most likely not within the purview of the caller. It's better to encapsulate this logic in the implementation of the interface. This makes the caller simpler (it doesn't have to know query logic), and it decouples the caller from query logic which allow the logic to change without without breaking the caller.

### Labyrinthine Structure

```go
//
// Antipattern
//
type Module struct {
    *ConfigModule
}

type ConfigModule struct {
    Config              ServerConfig
    Base                *config.BaseModule
    ServiceConfigModule *config.Module
}

type ServerConfig struct {
    SSL *ServiceSSLConfig
}
			        
type ServiceSSLConfig struct {
    KeyFile string
}
```

Structures should be shallow, preferably no more than three levels deep, especially when embedding is used. Structure and field names should be unique and descriptive. No proper example is given for the example above because it's too conflated for clarification, probably resulting from an inherently flawed data model. To be done properly, we would need first to clarify the data model.

To highlight the antipattern, think about how KeyFile would be accessed from a Module object. It requires a nontrivial and unnecessary amount of attention to detail because of embedding and repeated use of "Config".

### Hidden Goroutine

```go
//
// Antipattern
//
func Cleanup() {
    go func() {
        // ...
    }()
}

Cleanup()
```

```go
//
// Better
//
func Cleanup() {
    // ...
}

go Cleanup()
```

All code should be necessary and sufficient. The Cleanup() function in the antipattern is not necessary. The better implementation is sufficient (and still necessary). Additionally, the antipattern breaks developer expectation by hiding the goroutine because, in general, function calls are expected to be synchronous. When a function does nothing but launch a goroutine, it is asynchronous. Functions can and should launch goroutines, but not only this. The better solution is unambiguous, explicit. It also allows Cleanup() to be called synchronously if needed, whereas the antipattern precludes this possibility (as well as testing).

### New and Do

```go
//
// Antipattern
//
func NewFoo() (*Foo, error) {
    if err := connect(); err != nil {
        return nil, err
    }
    return &Foo{}
}
```

```go
//
// Better
//
func NewFoo() *Foo {
    return &Foo{}
}

func (f *Foo) Connect() error {
    if err := f.connect(); err != nil {
        return nil, err
    }
    return nil
}
```

NewFoo() in the antipattern does two things: it creates a new Foo object _and_ it connects (to whatever; a database, for example). That functions should do one thing is a widely accepted principle (related: [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single_responsibility_principle)).

The antipattern also creates a tight coupling between object creation and connection, meaning the caller cannot create a Foo object and connect later, which is common when objects are not created by the caller but, for example, by a [factory method](https://en.wikipedia.org/wiki/Factory_method_pattern). In this case, the factory should only create Foo and let the caller connect Foo when and where necessary.

The antipattern also makes it difficult to test connect() separately, and it makes the return error more difficult to handle because it could be a transient or retryable connect() error, or a fatal object creation error.

What if Foo should always be connected? What if Foo isn't useful until connected? This is common, but it's still better to decouple creation and connection and let the caller connect where and when necessary. It means the caller must do one more step (i.e. call Connect() after NewFoo()), but that's a small price to pay for better, more explicit design.

There is, however, a valid reason for NewFoo() to call other functions: when the functions are necessary and sufficient to the _creation_ of the new object. By contrast, connect() is neither necessary nor sufficient to create a Foo; it's necessary (but perhaps not sufficient) to _use_ a Foo. If, for example, a Foo cannot be created without the return value from bar(), then call bar() in NewFoo().

Notice also that the better example doesn't return an error. Unless an object is complex (and if too complex, perhaps it's doing too much and should be multiple, simpler objects), creation should be guaranteed, hence no return error. This means creation should be little more than initializing and assigning variables.

### Guarded Channel

```go
//
// Antipattern
//
mux.Lock()
v <- theChan
mux.Unlock()
```

```go
//
// Better?
//
select {
case <-stopChan: // terminate
    return
case v = <-theChan:
}
```

Channels do not need concurrency control because channels _are_ concurrency control (among other uses). Guarding a channel is an antipattern because channels do not need to be guarded when used properly. Moreover, channels have an internal mutex, so the result is a mutex on a mutex.

A better example depends on why the channel is being guarded. One possibility: the channel is overloaded, i.e. used for communicating and concurrency control. Communicating means that `v` is used by the code. Concurrency control means that closing `theChan` is used to signal that the receiver (probably a goroutine) should terminate. In this case, the solution is two channels: `theChan` to communicate, and `stopChan` to signal.

To avoid this antipattern for communicating channels, it helps to think of a channel as pipe which, magically, does not spill its contents. Thanks to that magic, you can change either end of the pipe (sender or receiver) without guarding the pipe itself. (You might need to guard the sender or receiver to change them safely.)

### Opaque Error

```go
//
// Antipattern
//
return fmt.Errorf("replication not running on db.localhost")
```

```go
//
// Better
//
return fmt.Errorf("replication not running on db.localhost: Replica_IO_Running = No, expected Yes (check SHOW REPLICA STATUS)")

```

Opaque errors hide the "why" from the user: _why_ is the code returning this error? There is always a "why": what the code expects but fails to obtain. Not including the "why" in the error message is a critical antipattern because it leaves the user without insight when they need it the most, i.e. when things are not working. The antipattern example narrows the problem to replication, which is a start, but it does not state why replication is not running according to its checks; there could be many reasons why. The better example states which check failed and gives the user a hint what to do next.

In this simple example the different is not huge, but in complex, distributed systems great error messages are invaluable. Especially in dynamic environments where the system might auto-correct, the user can investigate but see nothing wrong&mdash;a [heisenbug](https://en.wikipedia.org/wiki/Heisenbug). If the error is fleeting or sporadic, the "why" of a great error message gives us the clues we need to isolate the cause.

## Important

Important antipatterns affect overall software design and on-going maintenance. They do not need to be fixed immediately, but they should be prioritized and regularly improved to keep the code flexible.

### Superfluous Function

```go
//
// Antipattern
//
func (t *T) run(cmd string) error {
    return t.runRemote(cmd)
}

func (t *T) other() error {
    if err := t.run(cmd); err != nil {
        // ...
}
```

```go
//
// Better
//
func (t *T) other() error {
    if err := t.runRemote(cmd); err != nil {
        // ...
```

All code should be necessary and sufficient. Function run() in the antipattern is not necessary; other() can and should call runRemote(). Wrapper functions like run() are only necessary when they perform common/shared logic for callers (plural), like handling the error. This antipattern is stronger if there is only one caller, in which case runRemote() should definitely be called the one place where it is needed.

### Superfluous Structure

```go
//
// Antipattern
//
type RedisInfo map[string]string

type RawMetrics struct {
    Info RedisInfo
}

func (r *Redis) Info() RawMetrics
```

```go
//
// Better
//
func (r *Redis) Info() map[string]string
```

The simplest and most direct use of data types and structures yields code that's easier to follow and test because there are no superfluous parts. RawMetrics, with no other fields, serves no purpose. If other fields are planned/expected (and [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it) isn't a stronger argument), a code comment should note it. Otherwise, it's better to keep it simple and return the native data type: map[string]string.

### Transient Argument

```go
//
// Antipattern
//
func GetNodes(er Ranger, query string) []string {
    nodes := er.Query(query)
    // logic to transform nodes
    return nodesByName
}
```

```go
//
// Better
//
func GetNodes(er Ranger) []string {
    nodes := er.GetNodes()
    // logic to transform nodes
    return nodesByName
}
```

An argument is transient if not directly used by the function; the function only passes it to other function calls. The argument is literally only passing through the function, hence it is "transient". The antipattern also exhibits the "Promiscuous Interface" antipattern, and the better solution uses a well-defined interface to avoid the transient argument by encapsulating the query logic in the Ranger implementation.

### Runaway Arguments

```go
//
// Antipattern
//
func NewFoo(
    id string,
    name string,
    alias string,
    userId uint,
    apiKey string,
    loc *Location,
    size int64,
    active bool,
) *Foo {
    // ...
}
```

```go
//
// Better
//

// FooConfig represents required and optional values for creating a new Foo.
type FooConfig struct {
    id     string    // ID of the foo
    name   string    // Human-friendly name of the foo
    alias  string    // Alias of the foo (optional)
    userId uint      // User ID who created this foo
    apiKey string    // API key
    loc    *Location // Location of this foo
    size   int64     // Size of this foo
    active bool      // True if this foo is active
}

func NewFoo(cfg FooConfig) *Foo {
    // ...
}
```

Functions should have at most four positional arguments. Having more is difficult for humans to remember and, if data type are the same, humans might confuse the order of arguments and cause subtle bugs (e.g. passing `firstName, middleName, lastName` instead of `lastName, firstName, middleName`). Use a struct to represent more than four arguments. This has two important benefits: the arguments can and should be documented, and it's "future-proof": adding new arguments is backward-compatible. The arguments struct should be immutable.

### Type Hiding

```go
//
// Antipattern
//
type Job struct { ... }
type Jobs []Job

func List(Jobs)
```

```go
//
// Better
//
type Job struct { ... }

func List([]Job)
```

Unless a custom [sort](https://golang.org/pkg/sort/) on Jobs is required, Jobs should not be used because it hides the underlying data type (Job) and requires one to remember that Jobs is just []Job. Better to keep it simple and explicit: use []Job directly.

## Stylistic

Stylistic antipatterns are low priority, easy to change later without having to rewrite much, or any, code.

### C-style Pointer

```go
//
// Antipattern
//
var fileName *string
var files *[]FileInfo
```

```go
//
// Better
//
var fileName string
var files []FileInfo
```

It's not typical and usually not necessary to use pointers to scalars, slices, or maps in Go. There are exceptions (see [GoLang: When to use string pointers](https://dhdersch.github.io/golang/2016/01/23/golang-when-to-use-string-pointers.html)), but excessive use of pointers indicates Go being written like C (or C++ or Java) where pointers are more commonplace. In Go, the ubiquitous (and correct) use of pointers is to structures (`func(t *T)`, `return &T{}`, `var t = &T{}`, etc.) and pointer methods (`func (t *T) Foo()`). 

### Generic Package

```go
//
// Antipattern
//
import (
    "app/tools"
    "app/util"
    "app/misc"
    "app/db"
)
```

A package provides functionality around a logical and isolated part of the system. "What can pkg X do?" is the question we ask of that part. "How we do X" is an implementation detail that's leaked by generic package names. Of course, naming things is difficult, and generic packages are common, but we should nonetheless attempt to clarify their purpose and place in the app with a more domain-specific package name.

### Un Nom Court

```go
//
// Antipattern
//

var (
    m Metrics
    s Stats
)
```

```go
//
// Better
//
var (
    metrics Metrics
    stats   Stats
)
```

Short names are idiomatic Go, but don't take this style too far: Go still favors readability above all else.
Names aren't required to be short; it's just nice (and idiomatic) when there happens to be a short yet clear name.
In the antipattern, variable names `m` and `s` are too short, which makes them cryptic (not intention-revealing) and nearly impossible to search for (not all programmers use IDEs that follow variable references).
Moreover, there are better names that are still short, as shown in the better example.

>_Un nom court_ is French for "a short name".
>It's play on words since "nom" is an even shorter name for "name".

As another example, in the context of a package, idiomatic Go is function `Render()` not `RenderParseTreeToWriter()`.
Daily Go developers probably cringe at the latter, but engineers steeped in other languages might see it as a good name and, instead, think the former is too cryptic.
In Go, short names are idiomatic, just don't take it too far or eschew _slightly_ longer names.

See [Go Single-character Names](/golang/go-single-character-names/) for a reference on using single-character names.
Otherwise, use short descriptive names like shown in the better example.

<p class="note">
In Go, <code>camelCase</code> is standard and idiomatic.
A common exception is constant variables: <code>const ALL_CAPS_SNAKE_CASE = 1</code>.
</p>

### Narrative Naming

```go
//
// Antipattern
//
func (t *T) clearFlagIfTableDoesNotExist(tblstat TableStatus) {
    // ... Table check logic ...
    if !exists {
        t.flag = ""
    }
}

t.clearFlagIfTableDoesNotExist(tblstat)
```

```go
//
// Better
//
func (t *T) tableExists(tblstat TableStatus) bool {
    exists := false
    // ... Table check logic ...
    return exists
}

// Some good comment about why we clear the flag when the table
// does not exist.
if !t.tableExists(tblstat) {
    t.flag = ""
}
```

```go
//
// Alternative
//

// clearFlag sets flag to an empty string if the table does not exist,
// else the flag value is not changed.
func (t *T) clearFlag(tblstat TableStatus) {
    // ... Table check logic ...
    if !exists {
        t.flag = ""
    }
}

// Some good comment about why we clear the flag when the table
// does not exist.
t.clearFlag(tblstat)
```

Narrative naming is the opposite of _un nom court_: names that are not just long but narrate what the object is or does.
While this naming style is acceptable in other languages, it is an antipattern in Go; don't use it in Go.
Short names in Go are a challenge: it's not easy finding a short name for everything.
Avoid narrative naming, and use the shortest yet clearest, most intention-reveal name you can think of.

### Non-variable Variable

```go
//
// Antipattern
//
func CollectMetric(db *sql.DB) (float64, error) {
	query := `SELECT timer_wait FROM events_statements_current ORDER BY timer_wait DESC LIMIT 1`

	// ...
}
```

```go
//
// Better
//
const max_timer_wait_query = `SELECT timer_wait FROM events_statements_current ORDER BY timer_wait DESC LIMIT 1`

func CollectMetric(db *sql.DB) (float64, error) {
	// ...
}
```

If the value of a variable cannot or does not vary, then it's a constant, not a variable.
The variable `query` in the antipattern is not really a variable: it's a constant string.
Not only is its allocation in the function a waste (which a package `const` avoids), it leads the reader to wonder: could the query change?
Was it intended to change?
In this case, the query is intended to be constant, so it is better to declare it `const` outside (and next to) the function where it's used.
