# Threads
using ContextTracking
using Logging

@ctx function foo()
    @memo x = 1
    bar(current_task(), threadid())
    sleep(0.5)  # make it slow and yield to other green threads
end

@ctx function bar(task, thread_id)
    c = context()
    @info "inside bar" task thread_id c.data[:x]
end

asyncmap(i -> foo(), 1:3);
#=
julia> asyncmap(i -> foo(), 1:3);
┌ Info: inside bar
│   task = Task (runnable) @0x0000000127810010
│   thread_id = 1
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x0000000127810250
│   thread_id = 1
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x0000000127810490
│   thread_id = 1
└   c.data[:x] = 1
=#

# Regular experimental threading
using Base.Threads: @threads

@show Threads.nthreads();
#=
julia> @show Threads.nthreads();
Threads.nthreads() = 4
=#

@threads for i in 1:5
    foo()
end
#=
julia> @threads for i in 1:5
           foo()
       end
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874490
│   thread_id = 3
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874010
│   thread_id = 1
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b8746d0
│   thread_id = 4
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874250
│   thread_id = 2
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874010
│   thread_id = 1
└   c.data[:x] = 1
=#

# New threading
using Base.Threads: @spawn

for i in 1:5
    @spawn foo()
end
#=
julia> for i in 1:5
           @spawn foo()
       end

┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874910
│   thread_id = 2
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874b50
│   thread_id = 3
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b875210
│   thread_id = 2
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874d90
│   thread_id = 4
└   c.data[:x] = 1
┌ Info: inside bar
│   task = Task (runnable) @0x000000010b874fd0
│   thread_id = 1
└   c.data[:x] = 1
=#
