# ContextTracking.jl

ContextTracking is used to keep track of execution context.  The context data is kept in a stack data structure.  When a function is called, the context is saved.  When the function exits, the context is restored.  Hence, any change to the context during execution is visible to current and called functions only.

Participation of context tracking is voluntary - you must annotate functions with `@ctx` macro to get in the game.  The easiest way to append data to the context is to use the `@memo` macro in front of an assignment statement or a variable reference. Context data is automatically logged when using the `ContextLogger`.

## Motivation

Suppose that we are processing a web request.  We may want to create a request id to keep track of the request and include the request id whenever we write anything to the log file.

It may seems somewhat redundant to log the same data multiple times but it is invaluable in debugging production problems and even analyzing system performance.  Imagine that two users are hitting the same web request at the same time.  If we look at the log file, everything could be interleaving and it would be quite confusing without the context.

In microservices design, Correlation ID is used to track the activities of a transaction across multiple services.  When all microservices output the same Correlation ID to the log, we can trace the complete path of the process.

## Basic Usage

Just 3 simple steps:

1. Annotate functions with `@ctx` macro to participate in context tracking
2. Use `@memo` macro to append data to the context
3. Use the `ContextLogger` for logging context data, or use `context` function to access context data.

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

- `id`: context id, by default it is the thread id
- `data`: the data being tracked by the context.  By default, it is a `Dict`.
- `generations`: number of context levels.

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
val = 1
push!(ContextTracking.context(), :x => val)
```

It is highly advise that you only use `@memo` in functions that are annotated with `@ctx` macro.  Failing to do so would leak your data to the parent function's context, which is usually not a desirable effect.

## Todo's

- Need more tests especially for the macros and logger
- Convert README to Documenter.jl
- Allow registering pre/post hooks for specific context updates
- Enhance `@memo` macro to accept multiple variable reference

Logging
- ContextLogger should accept any kind of log formatter
- Generic logging formatter interface
- Write a JSON logging adapter
- Example for logging to ELK stack

Should we separate logging facility to separate package?  So people using ContextTracking doesn't have to get its logging function?

## Similar Projects

Using [Cassette.jl](https://github.com/jrevels/Cassette.jl), we can achieve similar result by overdubbing functions such that the context is saved/restored in the prehook/posthook.  Its facility is more powerful and general than this package.


