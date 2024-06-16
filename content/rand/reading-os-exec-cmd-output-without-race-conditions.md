---
date: "2017-06-17"
title:  "Reading os/exec.Cmd Output Without Race Conditions"
subtitle: "And without cmd.StdoutPipe"
tags: ["golang", "os/exec", "race condition"]
aliases:
  - /post/reading-os-exec-cmd-output-without-race-conditions/
---

[Golang Weekly issue 164](https://golangweekly.com/issues/164) features a nice article, [Advanced command execution in Go with os/exec](https://blog.kowalczyk.info/article/wOYk/advanced-command-execution-in-go-with-osexec.html), which details several ways of working with [os/exec](https://golang.org/pkg/os/exec/), especially how to read STDOUT and STDERR while the command is running. This common task is commonly done wrong, where "wrong" means "the code has a race condition". This blog post shows how to read STDOUT and STDERR from an `os/exec.Cmd` while it's running and _without_ race conditions.

## Problem

The Internet is rife solutions like Krzysztof provides (but afaik no one has provided them in one place and so thoroughly, so his post is a good read nonetheless), but let's test one:

```go
//
// cmd.go
//
package cmd

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
)

func Run() {
	var stdoutBuf, stderrBuf bytes.Buffer
	cmd := exec.Command("ls", "-lah")

	stdoutIn, _ := cmd.StdoutPipe()
	stderrIn, _ := cmd.StderrPipe()

	var errStdout, errStderr error
	stdout := io.MultiWriter(os.Stdout, &stdoutBuf)
	stderr := io.MultiWriter(os.Stderr, &stderrBuf)
	err := cmd.Start()
	if err != nil {
		log.Fatalf("cmd.Start() failed with '%s'\n", err)
	}

	go func() {
		_, errStdout = io.Copy(stdout, stdoutIn)
	}()

	go func() {
		_, errStderr = io.Copy(stderr, stderrIn)
	}()

	err = cmd.Wait()
	if err != nil {
		log.Fatalf("cmd.Run() failed with %s\n", err)
	}
	if errStdout != nil || errStderr != nil {
		log.Fatal("failed to capture stdout or stderr\n")
	}
	outStr, errStr := string(stdoutBuf.Bytes()), string(stderrBuf.Bytes())
	fmt.Printf("\nout:\n%s\nerr:\n%s\n", outStr, errStr)
}
```

```go
//
// cmd_test.go
//
package cmd

import (
	"testing"
)

func TestRun(t *testing.T) {
	Run()
}

```

Let's `go test -race` it:

```
$ go test -race

==================
WARNING: DATA RACE
Write at 0x00c420084280 by goroutine 6:
  os.(*file).close()
      /usr/local/opt/go/libexec/src/os/file_unix.go:143 +0x124
  os.(*File).Close()
      /usr/local/opt/go/libexec/src/os/file_unix.go:132 +0x55
  os/exec.(*Cmd).closeDescriptors()
      /usr/local/opt/go/libexec/src/os/exec/exec.go:262 +0x67
  os/exec.(*Cmd).Wait()
      /usr/local/opt/go/libexec/src/os/exec/exec.go:447 +0x2bd
  _/opt/dev/test/cmd-output/cmd.Run()
      /opt/dev/test/cmd-output/cmd/cmd.go:35 +0x4ea
  _/opt/dev/test/cmd-output/cmd.TestRun()
      /opt/dev/test/cmd-output/cmd/cmd_test.go:8 +0x2f
  testing.tRunner()
      /usr/local/opt/go/libexec/src/testing/testing.go:610 +0xc9

Previous read at 0x00c420084280 by goroutine 7:
  os.(*File).read()
      /usr/local/opt/go/libexec/src/os/file_unix.go:228 +0x7e
  os.(*File).Read()
      /usr/local/opt/go/libexec/src/os/file.go:101 +0x6f
  io.copyBuffer()
      /usr/local/opt/go/libexec/src/io/io.go:390 +0x168
  io.Copy()
      /usr/local/opt/go/libexec/src/io/io.go:360 +0x7e
  _/opt/dev/test/cmd-output/cmd.Run.func1()
      /opt/dev/test/cmd-output/cmd/cmd.go:28 +0x7e

Goroutine 6 (running) created at:
  testing.(*T).Run()
      /usr/local/opt/go/libexec/src/testing/testing.go:646 +0x52f
  testing.RunTests.func1()
      /usr/local/opt/go/libexec/src/testing/testing.go:793 +0xb9
  testing.tRunner()
      /usr/local/opt/go/libexec/src/testing/testing.go:610 +0xc9
  testing.RunTests()
      /usr/local/opt/go/libexec/src/testing/testing.go:799 +0x4ba
  testing.(*M).Run()
      /usr/local/opt/go/libexec/src/testing/testing.go:743 +0x12f
  main.main()
      _/opt/dev/test/cmd-output/cmd/_test/_testmain.go:54 +0x1b8

Goroutine 7 (finished) created at:
  _/opt/dev/test/cmd-output/cmd.Run()
      /opt/dev/test/cmd-output/cmd/cmd.go:29 +0x480
  _/opt/dev/test/cmd-output/cmd.TestRun()
      /opt/dev/test/cmd-output/cmd/cmd_test.go:8 +0x2f
  testing.tRunner()
      /usr/local/opt/go/libexec/src/testing/testing.go:610 +0xc9
==================

...

Found 7 data race(s)
exit status 66
FAIL	_/opt/dev/test/cmd-output/cmd	1.025s
```

I'll summarize:

* goroutine 6:
 * runs cmd
 * writes to stdout
* goroutine 7
 * runs `io.Copy`
 * reads from stdout
* cmd finishes
 * `Wait` closes stdout (goroutine 6)
 * `io.Copy` was reading stdout (goroutine 7)
* Race condition:
 * two goroutines accessing stdout without concurrency guards/sync
 * did `io.Copy` read everything before `Wait` closed stdout?

Sidebar: another great article in Golang Weekly issue 164: [Don’t defer Close() on writable files](https://joeshaw.org/dont-defer-close-on-writable-files/)

The docs for [Cmd.StdoutPipe](https://golang.org/pkg/os/exec/#Cmd.StdoutPipe) say:

> Wait will close the pipe after seeing the command exit, so most callers need not close the pipe themselves; however, an implication is that it is incorrect to call Wait before all reads from the pipe have completed.

To put it another way: the correct usage is to read everything first, _then_ call `Wait`. The docs provide an idiomatic example to illustrate. Used correctly, there's no race condition because the simple flow is `reads -> (reads stop) -> close -> wirte`. Consequently, and unfortunately for what we're trying to achieve, reading `StdoutPipe` before/during `Wait` is wrong and causes a race condition.

## Solution

TL;DR: [go-cmd/cmd](https://github.com/go-cmd/cmd)

I agree with Krzysztof: it's important to understand `os/exec`. Once you do and you want to make things "just work", just use `go-cmd/cmd`; it has _100% test coverage_ and _no race conditions_, and it can be used synchronously or asynchronously. It also correctly handles process termination, which is a problem far more subtle and infrequently realized let alone handled.

Here's how `go-cmd/cmd` handles it (just code snippets):

```go
// os/exec.Cmd.StdoutPipe is usually used incorrectly. The docs are clear:
// "it is incorrect to call Wait before all reads from the pipe have completed."
// Therefore, we can't read from the pipe in another goroutine because it
// causes a race condition: we'll read in one goroutine and the original
// goroutine that calls Wait will write on close which is what Wait does.
// The proper solution is using an io.Writer for cmd.Stdout. I couldn't find
// an io.Writer that's also safe for concurrent reads (as lines in a []string
// no less), so I created one:
type output struct {
	buf   *bytes.Buffer
	lines []string
	*sync.Mutex
}

func newOutput() *output {
	return &output{
		buf:   &bytes.Buffer{},
		lines: []string{},
		Mutex: &sync.Mutex{},
	}
}

// io.Writer interface is only this method
func (rw *output) Write(p []byte) (int, error) {
	rw.Lock()
	defer rw.Unlock()
	return rw.buf.Write(p) // and bytes.Buffer implements it, too
}

func (rw *output) Lines() []string {
	rw.Lock()
	defer rw.Unlock()
	// Scanners are io.Readers which effectively destroy the buffer by reading
	// to EOF. So once we scan the buf to lines, the buf is empty again.
	s := bufio.NewScanner(rw.buf)
	for s.Scan() {
		rw.lines = append(rw.lines, s.Text())
	}
	return rw.lines
}

//
// Elsewhere in the code...
//

cmd := exec.Command(name, args...)

stdout = newOutput()
stderr = newOutput()

cmd.Stdout = stdout
cmd.Stderr = stderr

cmd.Start() 

// Safe to call stdout.Lines()

cmd.Wait()
```

This this the best way? I don't know. Is it a _correct_ way? I'm 99% certain it is. Does it work? Yes! I've used it extensively in the real world without issues.

`go-cmd/cmd` saves me a lot of time because it just works. I hope it "just works" for you, too, and I hope this blog post helps turn the tide of racey solutions to the common and important task of reading STDOUT/STDERR from a Go `os/exec.Cmd` while it's running.
