---
type: "page"
date: "2018-05-13T09:00:00-07:00"
title: "Thinking in Go"
tags: ["golang", "software design", "godoc"]
aliases:
  - /post/thinking-in-go/
---

After learning Go, it is necessary to think in Go in order to design and implement well-written, idiomatic Go. This blog post outlines aspects that I think are important for thinking in Go. A full exploration of these aspects could fill a book, but this only an orientation for experienced programmers new to Go.

Programming languages have aspects which affect how we think, design, and implement software with the language: syntax, documentation, features/capabilities, language type (object-oriented, functional, compiled, etc.), etc. Consider [Perl Time::HiRes module](https://perldoc.perl.org/Time/HiRes.html) vs. [Ruby Time class](https://ruby-doc.org/core-2.2.0/Time.html) vs. [Go Time package](https://pkg.go.dev/time). Even subtle differences like "module" vs. "class" vs. "package" reflect thinking in the language. Effective language use requires correct language thinking. Applying Java thinking to Go results in non-idiomatic Go code, which is to say: Go code that does not "speak to" other Go programmers. This is not a superficial concern: from open-source to proprietary enterprise software, a codebase must be familiar and intuitive to other programmers with respect to the language so that the language itself does not impede the already difficult task of ongoing software maintenance by people who did not write the original code.

Important aspects when thinking in Go are:

* Objects, Packages, and Components
* Concurrency
* Channels
* Simplicity
* GoDoc

Some of these aspects are generic (e.g. concurrency and simplicity), but they have specific effects when thinking in and solving problems with Go.

## Objects, Packages, and Components

First, let's be clear that Go is not an object-oriented language. Forget about classes, hierarchies, inheritance, etc. Do not see or think of Go in these terms. And certainly do not use embedding to attempt pseudo object-oriented design with Go.

Go uses composition. Read [Composition over inheritance](https://en.wikipedia.org/wiki/Composition_over_inheritance), and if you have a copy of [Design Patterns](http://a.co/59TjVGQ) read section "Inheritance versus Composition" in chapter 1. Thinking in terms of composition is important: with Go, we design solutions, apply design patterns, and implement complex functionality by combining (i.e. composing) objects and packages. Let's address the use of "object" with respect to Go before we go further.

[Effective Go](https://go.dev/doc/effective_go) frequently uses the term "object" even though it is only mentioned once in the [Go language spec](https://go.dev/ref/spec):

> Like arrays, slices are always one-dimensional but may be composed to construct higher-dimensional objects.

Do not worry, Go is not having an existential crisis. Since this blog is only an orientation, let's avoid debate and simplify by saying that the following are Go objects:

```go
type Coffee struct {
    Origin string
}

type Roaster interface {
    Start(time.Duration)
}
```

In the code snippet above, we have two objects: `Coffee` and `Roaster`. Structures and interfaces are the most fundamental and common Go objects. There are more Go objects, but `struct` and `interface` are the nuts and bolts of all Go programs. Therefore, thinking in Go revolves primarily around structures and interfaces. Structures can have methods, and usually do. Interfaces are nothing but a set of methods that another object (usually a `struct`) must implement to satisfy the interface. Packages (discussed next) can have functions which are not methods of a `struct` or `interface`. To accomplish most high-level tasks in Go, first you find a relevant package, then you find functions or object methods in the package that do what you want. For example, to [open a file](https://golang.org/pkg/os/#Open), the `os` package has an `Open` function which returns a `File` object. With that `File` object you can do things like [Chmod](https://golang.org/pkg/os/#File.Chmod).

All well-written, idiomatic Go works and is documented this way: objects, methods, and functions (and other things). By using various objects together, we compose solutions for any problem. The [Go standard library](https://golang.org/pkg/) provides solutions for common system tasks. Familiarize yourself with it and use it often. When the standard library does not have a ready-made solution, search the internet and hopefully you will find a well-written package that you can `go get` and use out of the box. Failing that, or when designing and implementing application-specific code, mimic the standard library: create discrete, reusable, well-bounded and well-documented objects. This is a lot easier said than done, just as having paint and brushes does not mean one can paint masterpieces. Nonetheless, this how we think in Go: `struct`, `interface`, methods, functions, and packages. Let's now discuss the latter.

In one sentence: a package provides a common set of functionality. Study the gold standard: the [Go standard library](https://golang.org/pkg/). Unsurprisingly, the [Go json package](https://golang.org/pkg/encoding/json/) provides everything you need to encode and decode data as JSON. The standard library makes it look easy, but designing and implementing wonderful Go packages is very challenging. All of the objects and functions in a package should be related. One helpful way to achieve this is to document the package beginning with one sentence, like:

> Package json implements encoding and decoding of JSON as defined in RFC 7159.

Again, the standard library makes it look easy. Being able to say, in one sentence, what a package provides helps determine if objects and functions belong in the package. Well-defined packages are important because they delineate the system. Analogously, organs in a body are packages: brain, heart, lungs, stomach, etc. Each organ contains various parts: neurons in the brain, valves in the heart, alveoli in the lungs, acids in the stomach, etc. Organs are well-defined and well-delineated, and working together (hopefully) they compose the body. We think of, design, and implement Go programs in terms of packages. Complex systems are composed of many packages, each of which provides objects that code uses to compose solutions to needed tasks.

In my school of thought, there is a third and higher level of organization: components. Analogously again, the cardiovascular, respiratory, and digestive systems are components which are composed of various organs. Whereas packages and objects are actual code and strictly in the documented realm of Go, components are pure design. As such, they go a little beyond the scope of this blog. If the program is simple enough, components can be overkill; the program can be expressed and organized clearly with only packages. In large systems, however, a component represents abstract, delineate functionality. The defining difference between components and packages is that packages are inherently about code and implementation whereas components are only about abstract functionality. "Abstract functionality" is intentionally abstract but important nonetheless because it allows us to delineate and discuss high-level parts of the system without concern for how they are implemented. In other words: a component is abstract because it describes something the system does but not how. One example: a "notifier" component for sending notifications on various events. Before we discuss packages, we should discuss the abstract "notifier" concept to ensure it is necessary, well-bounded (i.e. not really part of the logging component), etc. If we agree the system needs a notifier, then we discuss what packages and objects can implement it. We might find that we need a Slack notifier and an email notifier. Those are package and object details which do not affect the notifier component, and if they change (e.g. replace email notifications wish push notifications to an app) the notifier component does not change.

Components are beyond the scope of this blog, so I will leave the topic there. For more, read [Domain-Driven Design](http://a.co/amEd2WB). Components are a lightweight application of that design philosophy. For our purposes here, packages and Go objects are crucial for thinking in Go. If you find yourself writing code at random, stop and rethink the system in terms of objects and packages. Study the [Go standard library](https://golang.org/pkg/) to learn how Go code is organized along these lines. And think of implementing solutions in Go in terms of composing packages and the objects they provide.

## Concurrency

Go is a system language and inextricably concurrent. In other languages (Perl, Ruby, JavaScript, PHP, etc.) concurrency is not usually a consideration; it might even require an additional package/module. Thinking in Go, however, we always think in terms on concurrency. [Goroutines](https://gobyexample.com/goroutines) make this possible, and they are ubiquitous in Go---so ubiquitous that most packages use them behind the scenes. Unless a program or package is very simple, there will be goroutines. Expect this and use them similarly in your own designs and implementations.

As a highly concurrent language, thinking in Go requires frequently asking one's self: "Is this safe for concurrent use by multiple goroutines?" and "How is concurrency handled?" For the former, excellent Go packages explicitly state if that is the case; if not stated, presume it is _not_ concurrent-safe (a.k.a. thread-safe). For example, the [os/exec](https://golang.org/pkg/os/exec/) package says nothing about concurrent access, multiple goroutines, etc., and if you examine the source you quickly see that the package has no concurrency control. By contrast, [go-cmd/cmd](https://github.com/go-cmd/cmd) is safe for concurrent access. When using and writing Go, be sure to think about and handle concurrency, and familiarize yourself with the [sync package](https://golang.org/pkg/sync/).

If you find yourself avoiding or struggling with concurrency in Go, re-read the manual, blogs, tutorials, etc. and master it. Go and concurrency are inextricable.

## Channels

One cannot (or, at least, should not) think in Go without thinking about [channels](https://gobyexample.com/channels). They are one of Go's best features, and they enable all sorts of elegant designs and solutions. They are usually used with concurrency to [share data by communicating](https://go.dev/blog/codelab-share) or coordinate goroutines. Already thinking in terms of concurrency, you will quickly find need for these two uses of channels. The former is rather obvious: send data via a channel in one goroutine and receive it via the same channel in another goroutine. It is a lot like a Unix pipe (`|`). The latter (coordinate goroutines) is less obvious at first. The first link in this section ([channels](https://gobyexample.com/channels)) covers this, so no need to repeat it here, but I will just call out one use:

```go
doneChan := make(chan struct{})
close(doneChan)
```

Pass `doneChan` to N-many goroutines that need to know when something is done. That something (e.g. an external command) closes the channel when done which acts like a broadcast signal to all goroutines that check the channel like:

```go
select {
    case <-doneChan:
        // done
    default:
        // not done
}
```

When open, the receiving on the channel blocks, so the `switch` falls through to the `default` case, making the check non-blocking. When closed, `case <-doneChan` returns immediately. Or, simply waiting on `<-doneChan` in a goroutine will block the goroutine until the channel is closed.

Mastering Go channels is essential to thinking in Go. Keep reading and practicing until channels are an effortless part of your Go thought process and designs.

## Simplicity

> Simplicity is the ultimate sophistication.<br>&mdash;Leonardo da Vinci

Go is a simple language, which is a virtue in the long term. What other languages can do in one line, Go might require several. And Go code tends to repeat certain boilerplate patterns. The language is powerful but its syntax and overall design are simple. Consequently, thinking in Go is a matter of designing and applying many simple steps toward a solution. In the short term, this feels pedantic, but Go is optimized for the long term: years of development and maintenance, by other engineers, long after everyone has forgotten the code and its intentions. At this future time, well-written Go provides generous returns on investments made at the beginning.

This blog is not the place to provide or argue a definition of "simplicity". The point is simply that, thinking in Go, we strive for simple solutions, as simple and intention-revealing as possible. We think about long-term development and maintenance, and all the engineers who will come later and read, understand, and work with the Go code. With a little effort, it is possible to write obfuscated Go code, but well-written Go code actively strives to avoid this. Keeping the code, like the language, as simple as possible and accepting additional upfront investments in simplicity is how we think in Go.

## GoDoc

[GoDoc](https://godoc.org/) helps motivate simplicity because clear and concise docs cannot be written for obfuscated code. Docs in Go are a first-class citizen and one of the language's greatest features because, like `gofmt`, they provide a canonical, ready-made solution for documenting Go packages and code. All we have to do is write the docs. As [Godoc: documenting Go code](https://blog.golang.org/godoc-documenting-go-code) begins:

> The Go project takes documentation seriously. Documentation is a huge part of making software accessible and maintainable.

Thinking in Go includes documentation, too. Go code is not well-written until it is also well-document. As usual, the standard library is the gold standard because it excels in being precise and concise. For example, in the section above on concurrency, I mention how the `os/exec` docs do not say if it is safe for use by multiple goroutines. With Go, we know this omission is not laziness but precision. Another example of precision from the same package, [Cmd.StdoutPipe](https://golang.org/pkg/os/exec/#Cmd.StdoutPipe):

> Wait will close the pipe after seeing the command exit, so most callers need not close the pipe themselves; however, an implication is that it is incorrect to call Wait before all reads from the pipe have completed. For the same reason, it is incorrect to call Run when using StdoutPipe. See the example for idiomatic usage.

That concise paragraph seems often to be overlooked because a commonly suggested solution for reading/streaming output from a command is precisely but incorrectly that: using `StdoutPipe`.

This type of writing requires "unpacking" the text; it is sometimes called "dense". It is difficult to write well, but it has two advantages: it is less to write and less to read. If a person must read one paragraph vs. one page to understand the code, I bet most people will prefer the former: one paragraph. Most of us do not read code docs for fun; we read them to learn how to do make progress in the actual task at hand. Consequently, Go docs strive to be pricse and concise.

When designing and writing Go code, think about what you will write for the docs. (And, of course, eventually _write_ those docs.) For every `package X`, complete this _single_ sentence: "Package X provides ...". If struggling to write that sentence, re-examine the design of the package, what it does and does not provide. Perhaps it is overloaded (i.e. doing too much) or all the functionality belongs in different package. For every `type X struct`, complete this _single_ sentence: "X represents ...". You can vary the verbs ("provides", "represents"), but keep the mental exercise: thinking how to precisely and concisely document every public part of the code.

---

In conclusion:

* **Objects, Packages, and Components**: composition over inheritance
* **Concurrency**: everything is concurrent; expect it, handle it
* **Channels**: share data and coordinate goroutines; master them
* **Simplicity**: power through simplicity; invest in simplicity
* **GoDoc**: precise and concise

Thinking in Go with these aspects in mind helps design and implement well-written, idiomatic Go.
