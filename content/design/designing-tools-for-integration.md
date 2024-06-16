---
date: "2017-09-05"
title: "Designing Tools for Integration"
subtitle: "Using factories, hooks, and context to make tools extensible and customizable"
tags: ["software design","tools", "integration"]
aliases:
  - /post/designing-tools-for-integration/
---

When we write a new tool to do X, it's common to program the tool to do X in one way. When X is trivial or very narrow in scope, this makes sense, and programming any more would fall prey to over-engineering. However, when the tool does many things (all logically related, else it falls prey to bloat and/or feature-creep), there quickly becomes many ways to accomplish those many things. No problem, we program all those things, too, but during my tool-making career I've learned two things:

* Environments vary widely
* Users are creative

Combined, these lessons implore us to design tools that are extensible and customizable--tools that do more and work differently than we originally envision while still performing their basic, built-in functions. It's a tall order: "Do X... oh and please also allow me do Q and R with X", where we have no idea what "Q" and "R" are. Here's a concrete example: my team is developing an open-source tool which has no built-in authentication (because we can't program every possible auth mechanism) but nonetheless needs to use company-specific, internal auth mechanisms. Oh and we also want the tool to automatically detect and use the correct internal VIP based on whether the user runs the tool in dev, stage, or production. Easy, right? Yeah, actually it is, and this article describes how.

## Factories

I have a predilection for [factories](https://en.wikipedia.org/wiki/Factory_method_pattern) (see also [Exploring the Factory Design Pattern](https://msdn.microsoft.com/en-us/library/ee817667.aspx)). My advice to developers wrt factories: learn them, love them, use them. Factories are normally used to create clean code, but they're also useful for creating extensible, customizable code by allowing the user to provide their own factory which overrides the tool's default, built-in factory.

Going back to the concrete example mentioned earlier, with respect to auth, we're dealing with a [*http.Client](https://golang.org/pkg/net/http/#Client). The tool needs to create one, so we use a factory:

```go
type HTTPClientFactory interface {
    Make(Context) (*http.Client, error)
}
```

We'll look at `Context` later. For now, the point is: the tool exposes an interface for this factory, which allows us to publish the tool with a default HTTP client factory that makes a default `*http.Client`, but then we wrap the tool with internal code that has an HTTP client factory that works with our internal auth mechanisms. The tool doesn't know and doesnt care, but now it can auth in our environment.

Of course, not _everything_ needs to be created via a factory. Use where you think the user could and would want to provide their own factory.

<mark>Define factory interfaces that create internal objects and services. Provide default factories but use custom (user-provided) factories when set.</mark>

## Hooks

Factories are one third of the solution. Another third is [hooks](https://en.wikipedia.org/wiki/Hooking). I could write a whole post just on hooks, but for now I'll keep it simple and just say: to make a tool extensible and customizable, define and declare hooks throughout the main code flow. Users are creative, and being able to hook into the tool allows them to alter and affect how the tool works. This is different than factories because once an object or service is created, the user can't control how the tool uses it. With hooks, nothing is created; the user is altering code flow to the extent made possible by the hooks.


Back to the concrete example, I mentioned that we want the tool to auto-detect and set an internal VIP based on the environment (dev, stage, prod). The open-source tool we publish has zero knowledge of either our VIPs or our environments, but it provides a hook:

```go
type Hooks struct {
    AfterParseOptions func(*config.Options)
    // more hooks...
}
```

As the hook name implies, it's called (if set) after parsing command-line options, which is what `*config.Options` contains. Passing a pointer is intentional; it reveals the code's intention that the hook can change the options. If we only wanted the hook to inspect the options, a pointer would not be passed. Consequently, in our internal wrapper code, we define a hook like (pseudo-code):

```go
h := app.Hooks{
    AfterParseOptions: func(o *config.Options) {
        if o.Env == "" {
            // --env not given, auto-detect and set
            o.Env = env
        }

        if o.Addr == "" {
	    // --addr not given, set based on --env
            switch o.Env {
            case "stage":
                o.Addr = "https://stage-vip"
            case "prod":
                o.Addr = "https://prod-vip"
            default:
                o.Addr = "http://localhost"
            }
        }
    },
}
```

After parsing command-line options, the tool calls this hook and the hook sets `--addr` and `--env`, if not already set, by auto-detecting internal stuff and using internal VIPs. Of course, if the hook breaks these options' values, that'll break the tool, but that's the hook's fault, not the tool's.

Give hooks consistent and descriptive names. I find "Before" and "After" prefixes work well. Or, if a hook can override a point in the code, then name it according to that point, like "LogTheData(data)" where only the hook is called (if set) to log the data. (By contrast, before- and after-hooks are always called when set and don't override/replace built-in code execution.")

<mark>Define hooks with consistent and descriptive names throughout the main code flow and call them if set.</mark>

## Context

The final third of the solution is a global app context. By "global" I do _not_ mean global var, I mean a single object or data structure used throughout the code, passed to factories and hooks. (It's probably a [singleton](https://en.wikipedia.org/wiki/Singleton_pattern).) The context contains at least the user-defined factories and hooks, but it can and should contain anything else that defines how and "where" to run the app. An example from the concrete example:

```go
// Context represents how to run spinc. A context is passed to spinc.Run().
// A default context is created in main.go. Wrapper code can integrate with
// spinc by passing a custom context to spinc.Run(). Integration is done
// primarily with hooks and factories.
type Context struct {
    // Set in main.go or by wrapper
    In        io.Reader // where to read user input (default: stdin)
    Out       io.Writer // where to print output (default: stdout)
    Hooks     Hooks     // for integration with other code
    Factories Factories // for integration with other code
    
    // Set automatically in spinc.Run()
    Options  config.Options // command line options (--addr, etc.)
    Command  config.Command // command and args, if any ("start <request>", etc.)
    RMClient rm.Client      // Request Manager client
}   
```

Our tool's context currently has those seven things. We can ignore `RMClient` and `Command` for now, and we've already discussed `Options`, `Factories`, and `Hooks`, so let's consider `In` and `Out`. As the helpful code comments say, these define STDIN and STDOUT. Why? By default, the tool prompts on STDIN and prints on STDOUT, and the user probably doesn't want to change this, but tests do. To test interactive input on STDIN, use an `io.Reader` controlled by the test. And same with STDOUT: tests have their own STDOUT, so to test the output of the tool, use an `io.Writer` controlled by the test.

These seven things define how and where to run the app: read from `In`, print to `Out`, calls `Hooks` if set, use the `Factories` to make objects/services, all the command-line options are represented by `Options`, `Command` is whatever command the tool is supposed to do, and use `RMClient` to talk with that API. With different combinations of these things, i.e. with different contexts, the tool works in differnet ways while still doing whatever it's supposed to do. With one context, it's a full default run: command line, terminal, network calls to the API, etc. With another context, it's running inside a test. And with a user-provided context, who knows what it's doing. Maybe `Out` is writing to a dot matrix printer, and `In` is channeling the spirit of W. Richard Stevens.

<mark>Use a single app context object/struct that defines how and where to run the app. Pass the context to factories, hooks, and other code.</mark>

## Wrapper

Let's put it all together and demonstrate how we can wrap the tool to extend and customize its functionality via hooks, factories, and context. First, the tool has three files:

_app/app.go_
```go
package app

type Context struct {
    In        io.Reader // where to read user input (default: stdin)
    Out       io.Writer // where to print output (default: stdout)
    Hooks     Hooks     // for integration with other code
    Factories Factories // for integration with other code

    Options  config.Options // command line options (--addr, etc.)
    Command  config.Command // command and args, if any ("start <request>", etc.)
    RMClient rm.Client      // Request Manager client
}

type Command interface {
    Prepare() error
    Run() error
}

type CommandFactory interface {
    Make(string, Context) (Command, error)
}

type HTTPClientFactory interface {
    Make(Context) (*http.Client, error)
}

type Factories struct {
    HTTPClient HTTPClientFactory
    Command    CommandFactory
}

type Hooks struct {
    AfterParseOptions func(*config.Options)
    CommandRunResult  func(interface{}, error)
}
```

app/app.go defines everything: factory and hook interfaces, context, and other "global" app things. The wrapper code will import this.

_spinc.go_
```go
package spinc

func Run(ctx app.Context) {
    // Where the program runs
    // Use and set ctx as needed
    // Pass ctx to factories and hooks

    if ctx.Hooks.AfterParseOptions != nil {
        ctx.Hooks.AfterParseOptions(&o)

        // Dump options to see if hook changed them
        if o.Debug {
            app.Debug("options: %#v\n", o)
        }
    }


    httpClient, err := ctx.Factories.HTTPClient.Make(*ctx)
    if err != nil {
        // handle
    }
    ctx.RMClient = rm.NewClient(httpClient, ctx.Options.Addr)
}
```

spinc.go is the root-level package (our tool is called "spinc"). It contains all the code the usually goes in main.go and, instead, puts it in `Run()` which has a single arg: the app context. To run the tool, wrapper code calls `spinc.Run()`, passing it a custom context.


_bin/main.go_
```go
func main() {
    defaultContext := app.Context{
        In:        os.Stdin,
        Out:       os.Stdout,
        Hooks:     app.Hooks{},
        Factories: app.Factories{},
    }
    spinc.Run(defaultContext)
}
```

Of course, we still have a main.go because wrapper code is optional. By default, when spinc is built, main.go simply calls `spinc.Run()` which a default context, yielding a default run (print to STDOUT, read from STDIN, etc.). Unlike the code snippets above, `main()` here is complete: it only calls `spin.Run()` because that's where all the real work is done. This makes testing easier, too: tests can call `spinc.Run()` with a test-specific app context.

Those three files (plus many more packages not shown) build the default tool. Now let's look at how we wrap the tool to create a custom build of the tool:

_main.go_ (in a private/internal code repo)

```go
type authHTTPClientFactory struct {}

func (f authHTTPClientFactory) Make(ctx app.Context) (*http.Client, error) {
    switch ctx.Options.Env {
    case "dev":
        return &http.Client{}, nil // no auth
    case "stage", "prod":
        return auth.NewHTTPClient(ctx.Options.Addr), nil
    default:
        panic("Invalid env: " + ctx.Options.Env)
    }
}

func main() {
    h := app.Hooks{
        AfterParseOptions: func(o *config.Options) {
            // Do the code shown earlier for this hook
        },
    }

    f := app.Factories{
        HTTPClient: &authHTTPClientFactory{},
    }

    ctx := app.Context{
        In:        os.Stdin,
        Out:       os.Stdout,
        Hooks:     h,
        Factories: f,
    }

    spinc.Run(ctx)
}
```

The wrapper main.go defines an HTTP client factory that makes secure, auth-required HTTP clients, and it sets the `AfterParseOptions` hook to modify `--addr` and `--env` as discussed earlier. Then it creates a custom `app.Context` with its custom factories and hook and passes it to `spinc.Run()` to run the tool. The default `bin/main.go` isn't used; the wrapper `main.go` takes its place. Everything else in the tool is the same. The wrapper cannot affect the tool beyond what's possible with the app context. And since this is Go, everything is strongly-typed and checked at compile time which reduces integration-related bugs to run time.


## Conclusion

This approach is neither new nor appropriate in all cases. There are other ways to allow for integration, to allow users to extend and customize a tool, but factories, hooks, and a global app context are very useful. One advantage to this approach is that it's easy to maintain forward compatibility: _new_ factories and hooks do not affect previous releases because they're all optional, so wrapper code remains blissfully unaware. Of course, like most integrations, once a thing is released, it can't be changed (unless you don't care about backwards-compatibility), so be sparing and careful--start small--with the factories, hooks, and other app context things that the code exposes.
