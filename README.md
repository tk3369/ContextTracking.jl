[![Travis Build Status](https://travis-ci.org/tk3369/ContextTracking.jl.svg?branch=master)](https://travis-ci.org/tk3369/ContextTracking.jl)
[![codecov.io](http://codecov.io/github/tk3369/ContextTracking.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/ContextTracking.jl?branch=master)


# ContextTracking.jl

ContextTracking is used to keep track of execution context.  The context data is kept in a stack data structure.  When a function is called, the context is saved.  When the function exits, the context is restored.  Hence, any change to the context during execution is visible to current and deeper stack frames only.

Participation of context tracking is voluntary - you must annotate functions with `@ctx` macro to get in the game.  Then,you can append data to the context fairly easily using the `@memo` macro in front of an assignment statement or a variable reference. Finally, context data is dumped automatically using the `ContextLogger`.

## Motivation

Suppose that we are processing a web request.  We may want to create a request id to keep track of the request and include the request id whenever we write anything to the log file during any part of the processing of that request.

It may seems somewhat redundant to log the same data multiple times but it is invaluable in debugging production problems.  Imagine that two users are hitting the same web request at the same time.  If we look at the log file, everything could be interleaving and it would be quite confusing without the context.

As context data is stored in a stack structure, you naturally gain more "knowledge" when going deeper into the execution stack. Then, you naturally "forget" about those details when the execution stack unwinds.  With this design, you can just memoize the most valuable knowledge needed in the log file.

## Basic Usage

Just 3 simple steps:

1. Annotate functions with `@ctx` macro to participate in context tracking
2. Use `@memo` macro to append data to the context
3. Use the `ContextLogger` for logging context data or use `context` function to access context data.

Example:

```julia
julia> using ContextTracking, Logging

julia> @ctx function foo()
           @memo x = 1
           bar()
           @info "after bar"
       end;

julia> @ctx function bar()
           y = 2
           @info "inside bar" y
       end;

julia> with_logger(ContextLogger(include_context_path = true)) do
           foo()
       end
2020-03-01T01:12:05.455-08:00 level=INFO message="inside bar" .ContextPath=foo.bar x=1 y=2
2020-03-01T01:12:05.493-08:00 level=INFO message="after bar" .ContextPath=foo x=1
```

## Working with the Context object

The `context` function returns a `Context` object with the following properties:

- `id`: context id, which is unique per current execution frame (even across async tasks or threads)
- `data`: the data being tracked by the context.  By default, it is a `Dict`.
- `generations`: current number of context levels in the stack frames.

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

The purpose of the save/restore operation is to guarantee that context data is _pushed down_ the execution chain (single direction).  So if the `foo` function calls another function that modifies the context, it will be restored when the `foo` function is returned.

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

## Additional work

General
- Need more tests especially for the macros and logger
- Convert README to Documenter.jl

Context
- Allow registering pre/post hooks for specific context updates?
- Enhance `@memo` macro to accept multiple variable reference

Logging
- Perhaps move out and interop with LoggingExtras.jl / LoggingFacilities.jl instead

## Related Projects

One can probably achieve similar result using [Cassette.jl](https://github.com/jrevels/Cassette.jl).
