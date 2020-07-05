"""
$(TYPEDEF)
Context is a container for storing any contextual information.
It uses Memento pattern to keep track of prior history.  While
the context can be changed, explict save/restore can be used
to save the current context and restore the most recently saved
one.

# Fields
$(TYPEDFIELDS)
"""
struct Context{T}
    "ID of the context"
    id::UInt
    "History of context data"
    history::Stack{T}
    "Call path"
    path::Vector{Symbol}
end

