[![Travis Build Status](https://travis-ci.org/tk3369/ContextTracking.jl.svg?branch=master)](https://travis-ci.org/tk3369/ContextTracking.jl)
[![codecov.io](http://codecov.io/github/tk3369/ContextTracking.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/ContextTracking.jl?branch=master)


# ContextTracking.jl

ContextTracking is used to keep track of execution context.  The context data is kept in a stack data structure.  When a function is called, the context is saved.  When the function exits, the context is restored.  Hence, any change to the context during execution is visible to current and deeper stack frames only.

Participation of context tracking is voluntary - you must annotate functions with `@ctx` macro to get in the game.  Then, you can append data to the context fairly easily using the `@memo` macro in front of an assignment statement or a variable reference.

## Motivation

Suppose that we are processing a web request.  We may want to create a request id to keep track of the request and include the request id whenever we write anything to the log file during any part of the processing of that request.

It may seems somewhat redundant to log the same data multiple times but it is invaluable in debugging production problems.  Imagine that two users are hitting the same web request at the same time.  If we look at the log file, everything could be interleaving and it would be quite confusing without the context.

As context data is stored in a stack structure, you naturally gain more "knowledge" when going deeper into the execution stack. Then, you naturally "forget" about those details when the execution stack unwinds.  With this design, you can just memoize the most valuable knowledge needed in the log file.

## Basic Usage

Just 3 simple steps:

1. Annotate functions with `@ctx` macro to participate in context tracking
2. Use `@memo` macro to append data to the context
3. Use `context` function to access context data.

Example:

```julia
using ContextTracking

@ctx function foo()
    @memo x = 1
    bar()
end

@ctx function bar()
    c = context()
    @show c.data
end
```

Result:
```julia
julia> foo()
c.data = Dict{Any,Any}(:_ContextPath_ => [:foo, :bar],:x => 1)
Dict{Any,Any} with 2 entries:
  :_ContextPath_ => [:foo, :bar]
  :x             => 1
```

## Working with the Context object

The `context` function returns a `Context` object with the following properties:

- `id`: context id, which is unique per current execution frame (even across async tasks or threads)
- `data`: the data being tracked by the context.  By default, it is a `Dict`.
- `generations`: current number of context levels in the stack frames
- `hex_id`: same as `id`, represented as a hexadecimal string

```julia
julia> c = context()
Context(id=0x10000011a3f3610,generations=1)

julia> c.id
0x010000011a3f3610

julia> c.data
Dict{Any,Any} with 0 entries
```

## How does `@ctx` macro work?

By annotating a function with `@ctx` macro, the function body is wrapped by code that saves and restores context.  Consider the following example:

```julia
@ctx function foo()
    @info "Inside Foo"
end
```

It would be translated to something like:

```julia
function foo()
    try
        save(ContextTracking.context())
        @info "Inside Foo"
    finally
        restore(ContextTracking.context())
    end
end
```

The purpose of the save/restore operation is to guarantee that context data is visible only during the current execution chain - inside the current function or any subsequent functions being called from here.

## How does `@memo` macro work?

The `@memo` macro is used to append new data to the current context.  Consider the following example:

```julia
@memo x = 1
```

It would be translated to something like:

```julia
val = (x = 1)
push!(ContextTracking.context(), :x => val)
```

It is highly advise that you only use `@memo` in functions that are annotated with `@ctx` macro.  Failing to do so would leak your data to the parent function's context, which is usually not a desirable effect.

## Is it thread-safe?

The `context()` always return a `Context` object that is unique by thread and async tasks.
Therefore, the context data is managed properly even when you run your program using multiple
threads or with `@async`.

For example, if you run the program with 4 threads, then `context()` would return a separate
context when it is called from the individual threads.  Likewise for async tasks.

<<<<<<< HEAD
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
Base.length
Base.push!       # accepting Pair{Symbol,Any}
Base.empty!
Base.getindex    # retrieving context value by Symbol
Base.iterate
```

=======
Context
- Allow registering pre/post hooks for specific context updates?
- Enhance `@memo` macro to accept multiple variable reference

>>>>>>> 674146d3b4a5841fea3a6b82981d46b3e23ccee1
## Related Projects

One can probably achieve similar result using [Cassette.jl](https://github.com/jrevels/Cassette.jl).
