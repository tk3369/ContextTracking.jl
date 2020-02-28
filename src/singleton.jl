# Singleton implementation that is thread-safe

const context_store = Dict{AbstractString, Context}()
const context_store_lock = ReentrantLock()

"""
    context([name::AbstractString], [container])

Get a new context object.  If `name` is not passed, then return a global
context for the current thread.  The `container` must be an object that
supports `push!`, `empty!`, and `length` functions. The default is `Dict`.
"""
function context(name::AbstractString = global_context_name(), container = Dict())
    try
        lock(context_store_lock)
        get!(context_store, name, Context(name, container))
    finally
        unlock(context_store_lock)
    end
end

global_context_name() = "Thread-" * string(Base.Threads.threadid())

