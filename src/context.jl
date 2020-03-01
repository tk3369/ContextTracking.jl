"""
$(TYPEDEF)
Context is a container for storing any contextual information.
It uses Memento pattern to keep track of prior history.  While
the context can be changed, explict save/restore can be used
to save the current context and restore the most recently saved
one.
$(TYPEDFIELDS)
"""
struct Context{T}
    "ID of the context"
    id::Int
    "History of context data"
    history::Stack{T}
end


"""
$(TYPEDSIGNATURES)
Create a context with the provided container.
"""
function Context(id::Int, container::T) where {T}
    write_debug_log(id, "creating new context of type $T")
    history = Stack{T}()
    push!(history, container)
    return Context(id, history)
end

"""
$(TYPEDSIGNATURES)
Save the current context to history.
"""
function save(c::Context)
    write_debug_log(c, "saving context started")
    push!(getfield(c, :history), deepcopy(c.data))
    write_debug_log(c, "saving context done")
end

"""
$(TYPEDSIGNATURES)
Restore to the last saved context.
"""
function restore(c::Context)
    write_debug_log(c, "restoring context started")
    pop!(getfield(c, :history))
    write_debug_log(c, "restoring context done")
end

# Extensions to Base functions

function Base.show(io::IO, c::Context)
    print(io, "Context ", c.id, " with ", c.generations, " generation(s)")
end

# Standard context management

function Base.push!(c::Context, entry)
    write_debug_log(c, "Appending to context ", c.id, " with ", entry)
    push!(c.data, entry)
end

Base.getindex(c::Context, index) = c.data[index]

Base.empty!(c::Context) = empty!(c.data)

Base.length(c::Context) = length(c.data)

# Property interface

Base.propertynames(c::Context) = (:id, :data, :generations)

function Base.getproperty(c::Context, s::Symbol)
    s === :id && return getfield(c, :id)
    s === :data && return first(getfield(c, :history))
    s === :generations && return length(getfield(c, :history))
    throw(UndefVarError("$s is not a valid property name."))
end

# Debug logging

"""
    debug_threading!(flag::Bool)

Turn on/off debugging for multi-threading applications.  It generates a lot
of debug information and they're saved in the tmp directory by thread id.

Caution: when debugging is turned on, expect much slower performance due to
excessive I/O.
"""
debug_threading!(flag::Bool) = DEBUG_THREAD[] = flag

function write_debug_log(id, args...)
    if DEBUG_THREAD[]
        open(joinpath(tempdir(), "ContextLib-Thread-" * string(id) * ".txt"), "a") do io
            println(io, now(), " ", args...)
        end
    end
end

write_debug_log(c::Context, args...) = write_debug_log(c.id, args...)

