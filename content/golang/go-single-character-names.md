---
date: "2022-03-25T16:55:00-04:00"
title: "Go Single-character Names"
summary: "'Go Single-character Names' details the proper, idoimatic usage of single character symbols in Go."
tags: ["golang", "variable-naming"]
---

Go loves short names. Even the authoritative page [_Effective Go_](https://go.dev/doc/effective_go) uses this example:

```go
f, err := os.Open(name)
if err != nil {
    return err
}
d, err := f.Stat()
if err != nil {
    f.Close()
    return err
}
codeUsing(f, d)
```

Short names are idiomatic Go, but overusing them creates cryptic, difficult-to-read code that is _not_ idiomatic because, above all, Go is optimized for reading, especially by future engineers.
This page describes four cases when single-character names&mdash;the shortest names possible&mdash;are idiomatic and acceptable.

But first: _do not avoid an easy alternative_:
```go
f := "/tmp/foo"        // not ideal
tmpFile := "/tmp/foo"  // better: easy alternative
```

Judicious use of single-character names in Go is idiomatic, but easy alternatives are far better.

## Loops

```go
for i := 0; i < 100; i++ {
}

for k, v := range someMap {
}

for _, n := range someList {
}
```

Loop variables have near universal agreement for being single characters.
In fact, not using `i`, `j`, and similar in `for` loops might even be considered bad style because this style is ubiquitous across languages.

However, you will find counter arguments that even loop vars should have short, meaningful names.
I agree and advise the same: do not avoid an easy alternative.
For example, suppose you have a map keyed on hostname with corresponding IP address:

```go
for hostname, ip := range hostnames {
}
```

In this case, `hostname` and `ip` are clearly superior to `k` and `v`&mdash;an easy alternative&mdash;and they're still very short.

## Blocks


```go

// Do something important with the file. I don't know what
// because I'm a little teapot and this example isn't real.
f, err := os.Open(name)
if err != nil {
    return err
}
d, err := f.Stat()
if err != nil {
    f.Close()
    return err
}
codeUsing(f, d)

```

That example from [_Effective Go_](https://go.dev/doc/effective_go) is a single code block.
(To emphasize that it's a block, I added blank lines and a block code comment.)
The variables `f` and `d` are declared and used only within the block, which makes it easy for humans (without the help of an IDE) to follow and understand them.
This would be a bad, non-idiomatic example if either variable was used outside the block (later in function, for example).

Although acceptable, it's better to avoid single-character variables in blocks unless the block is short (tens of lines) and well contained.
If in doubt, err on the side of caution and use short descriptive variable names.

## Receivers

```go
type T struct {}

func (t *T) foo() {
}
```

Receiver variables are often single characters, as in `t` for the method receiver on type `T`.
If a single character is too cryptic, then use two or three characters.

Using short descriptive names for receivers is less common in Go; for example:

```go
func (worker *Worker) Slog() {  // less common
func (w *Worker) Slog() {       // more common
```

You see the more common form, `w *Worker`, even in [_Effective Go_](https://go.dev/doc/effective_go) examples.
Two- and three-character receivers are acceptable and sometimes better, like `src` instead of `s`.

<p class="note warn">
Never use <code>self</code> or <code>this</code> for Go receiver names.
</p>

## Arguments

```go
// EscapeString escapes special characters ...
func EscapeString(s string) string {}

// Render renders the parse tree n to the given writer.
func Render(w io.Writer, n *Node) error {}

// Parse returns the parse tree for the HTML from the given Reader.
func Parse(r io.Reader) (*Node, error) {}
```

Single character arguments are practically the norm in the Go standard library.
The three example above are from [`net/html`](https://pkg.go.dev/golang.org/x/net/html).

There are three requirements that makes these single-character argument names acceptable and idiomatic:

1. Great code comment on the function (which is why I included them in the examples)
2. Not too many arguments
3. Relatively limited, block-scoped usage

`Render` exemplifies the first and second; let's see if it exemplifies the third:

```go
func Render(w io.Writer, n *Node) error {
	if x, ok := w.(writer); ok {
		return render(x, n)
	}
	buf := bufio.NewWriter(w)
	if err := render(buf, n); err != nil {
		return err
	}
	return buf.Flush()
}
```

Yes: that function is one small block that makes it easy to follow arguments `w` and `n`.
