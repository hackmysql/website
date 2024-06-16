---
type: "page"
date: "2018-02-04T19:30:00-07:00"
title: "Bootloader Design Pattern"
subtitle: "Make a clean start with extensibility and integration"
tags: ["software design", "design pattern", "bootloader"]
aliases:
  - /post/bootloader-design-pattern/
---

[Extensibility](https://en.wikipedia.org/wiki/Extensibility) is a lofty goal for software design, and difficult to achieve. The Wikipedia article notes:

> Extensible design in software engineering is to accept that not everything can be designed in advance.

That's a paradox because it entails that extensible design does not accept that extensibility can be designed in advance! Fortunately, there's at least one solution that can be intentionally designed and implemented in advance. I call it the "Bootloader" design pattern. Its intention is twofold: boot the program _and_ make it extensible to the caller. Of course, every program is booted (started) somehow, usually a `main()` function that does a lot and isn't well tested. But before we dive into Bootloader, let's consider Keurig.

![Keurig coffee maker](/img/keurig.jpg)

If you've never used a Keurig coffee maker, it's a machine that makes a cup of coffee using a little pod (three shown at bottom right). You open the top of th machine, drop in a pod, close the top, then push a button and a few seconds later you have a hot cup of coffee. There's a wide selection of pods for different types of coffee, tea, hot chocolate, etc. Don't worry: this analogy will not digress into JavaScript-related puns, I promise!

The Keurig is a great analogy because it's a fixed system that produces very different results depending on how it's "booted", i.e. depending on which pod you put in before starting it. The intention of the Bootloader design pattern is the same: fixed system with different results depending on how it's booted. Granted, for software "different results" is more analogous to light-, medium-, or dark-roasted coffee. If your software is supposed to make coffee but makes tea instead, that's a bug.

Bootloader has three elements:

![Bootloader diagram](/img/bootloader.svg)

* Start code (red)
* App context (green)
* Boot code (gray)

Bootloader in one sentence: _Start code uses an app context to boot the program._

## Start Code

As the name implies, start code starts the program. It can also be called "entry point" or simply "main" since the default start code is usually in a `main()` function. <mark>The defining characteristic of start code: with respect to the program, it only calls the boot code with an app context.</mark> This means start code can be very minimal, like:

```go
func main() {
    err := server.Run(app.Defaults())
    log.Fatal("server stopped: %s", err)
}
```

`app.Defaults()` returns a default app context, and `server.Run()` is the boot code. The qualification "with respect to the program" is important: start code can do anything if unrelated to the program. This allows wrapper code to do wrapper-specific work. For example, let's imagine `keurig` is a program that makes coffee and we want to use it in another system that makes breakfast, so the breakfast code needs to wrap `keurig` and make coffee at the right time and with a user-specified roast. The pseudo code is:

```go
func makeBreakfast(coffeeRoast string) {
	toast.BurnIt()
	fruit.SliceIt()

	coffee := app.NewCoffee(coffeeRoast)
	keurig.Make(coffee)

	waffles.FlipThem()
}
```

`makeBreakfast()` is the start code, `coffee` is the app context, and `keurig.Make()` is the boot code. The example demonstrates two things. First, that start code can do anything if unrelated to the program in question, `keurig`. Second, that although a program must have its own default start code, it might not be used; instead, other wrapper code serves as the start code, `makeBreakfast()`. So although `makeBreakfast()` does other stuff, it's still start code for `keurig` because with respect to `keurig` it only calls the boot code (`keurig.Make()`) with an app context (`coffee`).

## App Context

![App Context](/img/app_context.svg)

App context is a well-defined structure (blue rectangles) that exposes all "global" app configuration, factories, hooks (callbacks), and any other well-defined semantics. It is a pseudo-singleton: only one app context should be instantiated. (I suppose a system that can dynamically reload might have varying contexts between reloads, but the intention is for the app context to be a singleton.) It is global in usage, _not_ namespace (i.e. it's not a global variable) because it's passed to most components in the program as part of their instantiation or initialization.

The app context structure is what allows developers to define, document, and expose points of integration and extensibility while hiding the inner working (i.e. implementation details) of the program. With the Keurig coffee maker, pods are "app context" for the machine: the pod structure is defined by Keurig, but the user chooses a pod. In software, developers define the app context, and the start code instantiates an app context (green circles). Usually, a program provides default start code and a default app context.

As a "global" pseudo-singleton, the app context is a unifying design element, a single source of truth, and the point of integration and extensibility. This is simple but extremely powerful because it allows 3rd-party code to affect the program in fundamental ways without breaking the program's encapsulations, boundaries, interfaces, etc. For example, a common requirement for an API is authentication, but an open-source project cannot predict or reasonably support all possible auth mechanisms. It can support common mechanisms by default, but it can also expose an auth hook to allow any auth mechanism:

```go
type Hooks struct {
    Auth func(*http.Request) (bool, error)
}

type AppContext struct {
    Hooks Hooks
}

func startCode() {
    appCtx := app.Defaults()
    appCtx.Hooks.Auth = func(req *http.Request) (bool, error) {
        // Allow access only on 1st day of month
        firstDayOfMonth := time.Now().Day() == 1
	return firstDayOfMonth, nil
    }
    server.Boot(appCtx)
}
```
In the pseudo code above, we define a special auth hook in our start code that only authenticates (returns true) on the 1st day of the month. This is a silly example, but the possibilities are endless and easy to add.

Whereas hooks allow arbitrary code callback during program execution, [factories](https://sourcemaking.com/design_patterns/factory_method) are a great design pattern to let 3rd-party code create internal objects. For example, in Go an `*http.Client` is frequently used and has a lot of internal configuration. Exposing an `HTTPClientFactory` allows 3rd-party code to make an `*http.Client` with a specific internal configuration.

Last note: <mark>app context should only be mutable in the start code.</mark> Outside the start code (i.e. when passed to other code components), app context should by passed by value. Since the app context is used globally, we don't want one part of the program to interfere with another via changes to the app context. Also good to keep in mind that it's probably used concurrently, but it doesn't need guarding as long as it's immutable and read-only outside the start code.

## Boot Code

The third and final element of the Bootloader design pattern is boot code. This is usually the code previously in `main()` (now that `main()` is minimal start code). Boot code does as its name suggests: it boots the system. <mark>The defining characteristics of boot code: it is called only by start code and always passed the app context.</mark> Therefore, boot code cannot be in `main()` because `main()` should be the default start code. Boot code must be passed the app context, but it can be passed other arguments, too. The intention is for boot code to use the app context heavily, but the ultimate goal is that boot code makes the program runnable. Depending on the program, the boot code might run the program, or it might return something to allow the start code to run the program later. Either way, all logic that makes the program runnable (read config files, instantiate other code components, etc.) should be put in the boot code.

Last note: boot code is static. There's only one boot code and it's written by the program developers. Unlike start code which might be a 3rd-party wrapper, boot code is static. All variability in the boot process should be determined by the app context. For example, if some internal code component is optional, make it configurable (config file, command-line option, etc.), include the configuration in the app context, and then the boot code can create the optional component or not depending on the app context configuration.

## Extensibility 

I've seen the Bootloader design pattern used in various forms before, so it's not new, but I've never seen it named or explicitly outlined. When implemented, it has two effects: it create clean, well-delineate "main code" (code used to start and boot the program), and it makes the program extensible while remaining well-defined and testable. The two effects work together because it's at startup that we want to expose any points of integration. Doing so elsewhere is likely to poke holes in the code through which implementation details will leak, or yield entangled, tightly-coupled code, or lead to other poor designs.

Two nice things about Bootloader: it's difficult to over-engineer (the program already has "main code"), and introducing new points of integration is backwards-compatible (only requires a new minor version release). You can start with a very small app context that exposes, for example, only the "global" app configuration: the final result of merging environment variables, config files, command-line options, and hard-coded defaults. I suggest starting very small because it's easy to add points of integration but, once released, very difficult to change or deprecate them. Begin with what you know you need, ship it, then wait for other needs to arise.
