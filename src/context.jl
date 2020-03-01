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
    "Name of the context"
    name::AbstractString
    "History of context data"
    history::Stack{T}
end


"""
$(TYPEDSIGNATURES)
Create a context with the provided container.
"""
function Context(name::AbstractString, container::T) where {T}
    history = Stack{T}()
    push!(history, container)
    return Context(name, history)
end

"""
$(TYPEDSIGNATURES)
Save the current context to history.
"""
function save(c::Context)
    # @debug "saving context"
    push!(getfield(c, :history), deepcopy(c.data))
end

"""
$(TYPEDSIGNATURES)
Restore to the last saved context.
"""
function restore(c::Context)
    # @debug "restoring context"
    pop!(getfield(c, :history))
end

# Extensions to Base functions

function Base.show(io::IO, c::Context)
    print(io, "Context ", c.name, " with ", c.generations, " generation(s)")
end

# Standard context management

Base.push!(c::Context, entry) = push!(c.data, entry)

Base.getindex(c::Context, index) = c.data[index]

Base.empty!(c::Context) = empty!(c.data)

Base.length(c::Context) = length(c.data)

# Property interface

Base.propertynames(c::Context) = (:name, :data, :generations)

function Base.getproperty(c::Context, s::Symbol)
    s === :name && return getfield(c, :name)
    s === :data && return first(getfield(c, :history))
    s === :generations && return length(getfield(c, :history))
    throw(UndefVarError("$s is not a valid property name."))
end
