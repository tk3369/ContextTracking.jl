[![Travis Build Status](https://travis-ci.org/tk3369/ContextTracking.jl.svg?branch=master)](https://travis-ci.org/tk3369/ContextTracking.jl)
[![codecov.io](http://codecov.io/github/tk3369/ContextTracking.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/ContextTracking.jl?branch=master)
![Project Status](https://img.shields.io/badge/status-maturing-green)

# ContextTracking.jl

ContextTracking is used to keep track of execution context.  The context data is kept in a stack data structure.  When a function is called, the context is saved.  When the function exits, the context is restored.  User can make changes to the context during execution, and the data is visible to both the current and deeper stack frames.

The usage is embarassingly simple:
1. Annotate functions with `@ctx` macro
2. Attach context data using the `@memo` macro
3. Access context data anywhere using the `context` function

## Motivation

Suppose that we are [processing a web request](images/web_service_example.png).  We may want to create a [correlation id](https://blog.rapid7.com/2016/12/23/the-value-of-correlation-ids/) to keep track of the request and include the request id whenever we write anything to the log file during any part of the processing of that request.

It may seems somewhat redundant to log the same data multiple times but it is invaluable in debugging production problems.  Imagine that two users are hitting the same web service at the same time.  If we look at the log file, everything could be interleaving and it would be quite confusing without the context.

As context data is stored in a stack structure, you naturally gain more "knowledge" when going deeper into the execution stack. Then, you naturally "forget" about those details when the execution stack unwinds.  With this design, you can just memoize the most valuable knowledge needed in the log file.

## Example

```julia
using ContextTracking

@ctx function foo()
    @memo x = 1
    bar()
end

@ctx function bar()
    c = context()
    @info "context data" c.data
end
```

Result:
```julia
julia> foo()
┌ Info: context data
│   c.data =
│    Dict{Any,Any} with 2 entries:
└      :x             => 1
```

## Working with the Context object

The `context` function returns a `Context` object with the following properties:

- `id`: context id, which is unique per task/thread
- `data`: the data being tracked by the context.  By default, it is a `Dict`.
- `path`: the call path, an array of function names as recorded by `@ctx`
- `generations`: number of context levels in the stack
- `hex_id`: same as `id`, represented as a hexadecimal string

```julia
julia> @ctx function foo()
           @memo x = 1
           c = context()
           @show c.id c.path c.data
           return nothing
       end;

julia> foo()
c.id = 0x010000011a80f610
c.path = [:foo]
c.data = Dict{Any,Any}(:x => 1)
```

## How does `@ctx` macro work?

By annotating a function with `@ctx` macro, the function body is wrapped by code that saves and restores context.  Consider the following example:

```julia
@ctx function foo()
    @info "Inside Foo"
end
```

It would be translated to something like this:

```julia
function foo()
    try
        # << inserted code to save context >>
        @info "Your code inside Foo"
    finally
        # << inserted code to restore context >>
    end
end
```

The purpose of the save/restore operation is to guarantee that context data is visible only during the current execution chain - inside the current function or any subsequent functions being called from here.

## How does `@memo` macro work?

The `@memo` macro is used to assign data to the current context.  Consider the following example:

```julia
@memo x = 1
```

It would be translated to something like:

```julia
val = (x = 1)
push!(ContextTracking.context(), :x => val)
```

It is highly recommended that you only use `@memo` in functions that are annotated with `@ctx` macro.  Failing to do so would leak your data to the parent function's context, which is *usually* not a desirable effect.

## Is it thread-safe?

The `context()` function always returns a `Context` object that is unique by thread / async task.
Therefore, the context data is managed properly even when you run your program using multiple
threads or with `@async`.

For example, if you run the program with 4 threads, then `context()` would return a separate
context when it is called from the individual threads.  Likewise for async tasks.

```julia
julia> using Base.Threads

julia> Threads.nthreads()
4

julia> Threads.@threads for i in 1:4
           println("Thread ", threadid(), " has context ", context().hex_id)
       end
Thread 3 has context 0x30000011092bcd0
Thread 2 has context 0x20000011092ba90
Thread 1 has context 0x10000011092b850
Thread 4 has context 0x40000011098c010
```

## What if I don't want to use Dict for storing my context?

The `Context` type allows you to use a different container type if you want to use something
different.  The only requirement is that the container type must implement the following functions:

```julia
Base.push!       # accepting Pair{Symbol,Any}
Base.getindex    # retrieving context value by Symbol
Base.length
Base.empty!
Base.iterate
```

## Related Projects

One can probably achieve similar result using [Cassette.jl](https://github.com/jrevels/Cassette.jl).
