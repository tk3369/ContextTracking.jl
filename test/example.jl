using Revise, ContextLib

# Using @ctx and @memo macros

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
    @error "oops" d
    @error "oops" d c   # this would cause duplicate!
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

# The ContextLogger adds color to everything!
using Logging

context_logger = ContextLogger(stdout, Logging.Debug)
with_logger(context_logger) do
    foo()
end

using LoggingExtras, Logging
log_file_handle = open("/tmp/test.log", write = true)
log_level = Logging.Debug
global_logger(
    TeeLogger(
        global_logger(),
        ContextLogger(log_file_handle, log_level, true)
    )
)
foo()
close(log_file_handle)
readlines("/tmp/test.log")

# another starting point
start() = foo()
with_logger(context_logger) do
    start()
end

#=
2020-01-14T14:32:19.4-08:00 level=INFO message="before calling bar" _ContextPath=foo a=1 b=2
2020-01-14T14:32:19.4-08:00 level=ERROR message=oops _ContextPath=foo.bar a=1 b=2 c=3 d=4
2020-01-14T14:32:19.401-08:00 level=ERROR message=oops _ContextPath=foo.bar a=1 b=2 c=3 c=3 d=4
2020-01-14T14:32:19.401-08:00 level=INFO message="cool stuffs" _ContextPath=foo.bar.cool a=1 b=2 c=3 x=1 y=hello
2020-01-14T14:32:19.401-08:00 level=DEBUG message="debugging only" _ContextPath=foo.bar.cool a=1 b=2 c=3
2020-01-14T14:32:19.401-08:00 level=INFO message="after calling bar" _ContextPath=foo a=1 b=2
=#

# Logging to file

log_file_path = "/tmp/test_context_tracker.log"
log_file_handle = open(log_file_path, "a")
try
    context_logger = ContextLogger(log_file_handle, Logging.Debug)
    with_logger(context_logger) do
        foo()
    end
finally
    close(log_file_handle)
end
readlines(log_file_path)  # check
rm(log_file_path)
