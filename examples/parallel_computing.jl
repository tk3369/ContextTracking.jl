# Threads
using ContextLib
using Logging

@show Threads.nthreads();

@ctx function foo()
    @memo x = 1
    bar()
    sleep(0.5)  # make it slow and yield to other green threads
    @info "after bar"
end

@ctx function bar()
    y = 2
    @info "inside bar" y
end

# Turn on debugging
ContextLib.set_verbose!(false)

# Asyncmap
with_logger(ContextLogger(include_context_path = true, include_context_id = true)) do
    asyncmap(i -> foo(), 1:5)
end

# Regular experimental threading
using Base.Threads: @threads

with_logger(ContextLogger(include_context_path = true, include_context_id = true)) do
    @threads for i in 1:5
        foo()
    end
end

# New threading
using Base.Threads: @spawn

with_logger(ContextLogger(include_context_path = true, include_context_id = true)) do
    for i in 1:5
        @spawn foo()
    end
end
