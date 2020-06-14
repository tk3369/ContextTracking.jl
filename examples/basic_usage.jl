# Basic usages of @ctx and @memo macros

using ContextTracking

@ctx function foo()
    @memo a = 1
    @memo b = 2
    @info "before calling bar"
    bar()
    @info "after calling bar"
end

@ctx function bar()
    @memo c = 3
    d = 4
    @info "inside bar" d
    @info "inside bar" d c   # this would cause duplicate!
    cool()
end

@ctx function cool()
    x = 1
    y = "hello"
    @info "cool stuffs" x y
    @debug "debugging only"
end

# The standard logger does not know anything about context
foo()
#=
julia> foo()
[ Info: before calling bar
┌ Error: oops
│   d = 4
└ @ Main REPL[119]:4
┌ Error: oops
│   d = 4
│   c = 3
└ @ Main REPL[119]:5
┌ Info: cool stuffs
│   x = 1
└   y = "hello"
[ Info: after calling bar
=#

using Logging

context_logger = ContextLogger(min_level = Logging.Debug, include_context_path = true)
with_logger(context_logger) do
    foo()
end
#=
2020-03-01T00:05:45.203-08:00 level=INFO message="before calling bar" .ContextPath=foo a=1 b=2
2020-03-01T00:05:45.222-08:00 level=ERROR message=oops .ContextPath=foo.bar a=1 b=2 c=3 d=4
2020-03-01T00:05:45.243-08:00 level=ERROR message=oops .ContextPath=foo.bar a=1 b=2 c=3 c=3 d=4
2020-03-01T00:05:45.262-08:00 level=INFO message="cool stuffs" .ContextPath=foo.bar.cool a=1 b=2 c=3 x=1 y=hello
2020-03-01T00:05:45.287-08:00 level=DEBUG message="debugging only" .ContextPath=foo.bar.cool a=1 b=2 c=3
2020-03-01T00:05:45.321-08:00 level=INFO message="after calling bar" .ContextPath=foo a=1 b=2
=#

context_logger = ContextLogger()
with_logger(context_logger) do
    foo()
end
#=
2020-03-01T00:06:11.449-08:00 level=INFO message="before calling bar" a=1 b=2
2020-03-01T00:06:11.474-08:00 level=ERROR message=oops a=1 b=2 c=3 d=4
2020-03-01T00:06:11.491-08:00 level=ERROR message=oops a=1 b=2 c=3 c=3 d=4
2020-03-01T00:06:11.509-08:00 level=INFO message="cool stuffs" a=1 b=2 c=3 x=1 y=hello
2020-03-01T00:06:11.53-08:00 level=INFO message="after calling bar" a=1 b=2
=#

