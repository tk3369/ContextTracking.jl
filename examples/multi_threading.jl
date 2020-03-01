# A multi threading example
using Revise, ContextLib
using Base.Threads

@show Threads.nthreads()

@ctx function foo(id)
    @memo id
    bar()
end

@ctx function bar()
    @memo threadid = Threads.threadid()
    c = context()
    @info "Inside Bar" c.id
end

using Logging
with_logger(ContextLogger()) do
    Threads.@threads for i in 1:128
        foo(i)
    end
end
#=
2020-03-01T10:38:40.634-08:00 level=INFO message="Bar start" id=33 threadid=2 c.id=2
2020-03-01T10:38:40.688-08:00 level=INFO message="Bar start" id=65 threadid=3 c.id=3
2020-03-01T10:38:40.744-08:00 level=INFO message="Bar start" id=97 threadid=4 c.id=4
2020-03-01T10:38:40.791-08:00 level=INFO message="Bar start" id=34 threadid=2 c.id=2
2020-03-01T10:38:40.852-08:00 level=INFO message="Bar start" id=1 threadid=1 c.id=1
2020-03-01T10:38:40.919-08:00 level=INFO message="Bar start" id=35 threadid=2 c.id=2
2020-03-01T10:38:40.964-08:00 level=INFO message="Bar start" id=98 threadid=4 c.id=4
...
=#

# Turn on debugging for multi-threading (use with caution due to performance impact)
ContextLib.debug_threading!(true)

with_logger(ContextLogger()) do
    Threads.@threads for i in 1:128
        foo(i)
    end
end

filter(x -> startswith(x, "ContextLib"), readdir(tempdir()))
#=
julia> filter(x -> startswith(x, "ContextLib"), readdir(tempdir()))
4-element Array{String,1}:
 "ContextLib-Thread-1.txt"
 "ContextLib-Thread-2.txt"
 "ContextLib-Thread-3.txt"
 "ContextLib-Thread-4.txt"
=#
