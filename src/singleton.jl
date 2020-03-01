# Singleton implementation that is thread-safe

const context_store = Dict{Int, Context}()
const context_store_lock = Base.Threads.SpinLock()

"""
    context([id::Int], [container])

Get a new context object.  If `id` is not passed, then return a global
context for the current thread.  The `container` must be an object that
supports `push!`, `getindex`, `empty!`, and `length` functions.
The default is `Dict`.
"""
function context(id = default_context_id(), container = Dict())
    try
        write_debug_log(id, "locking context id=$id")
        lock(context_store_lock)
        get!(context_store, id, Context(id, container))
    finally
        unlock(context_store_lock)
        write_debug_log(id, "unlocked context id=$id")
    end
end

"""
    default_context_id()

Return a context name for the current thread.
"""
default_context_id() = Base.Threads.threadid()

