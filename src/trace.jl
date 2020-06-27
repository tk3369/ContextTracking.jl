"""
    @ctx <function definition> [label]

Define a function that is context-aware i.e. save the current context
before executing the function and restore the context right before
returning to the caller. So, if the function modifies the context
using (see [`@memo`](@ref)), then the change is not visible the caller.

An optional label of type symbol/string can be added at the end of function definition for
tracking the call path.  Function name is used when the label is not provided.
```
"""
macro ctx(ex, label = nothing)
    def = splitdef(ex)
    name = QuoteNode(label !== nothing ? Symbol(label) : def[:name])
    def[:body] = quote
        try
            save(ContextTracking.context())
            ContextTracking.trace!(ContextTracking.context(), $name)
            $(def[:body])
        finally
            restore(ContextTracking.context())
        end
    end
    return esc(combinedef(def))
end

"""
    @memo var = expr
    @memo var

Store the variable/value from the assigment statement in the current
context.
"""
macro memo(ex)
    # capture the variable
    if ex isa Symbol          # @memo var
        x = ex
    elseif ex.head === :(=)   # @memo var = expression
        x = ex.args[1]
    else
        error("@memo must be followed by an assignment or a variable name.")
    end
    sym = QuoteNode(x)
    return quote
        val = $(esc(ex))
        push!(ContextTracking.context(), $sym => val)
    end
end

"""
    trace!(ctx, name)

Store the function name in the trace path in the context.
"""
function trace!(ctx::Context, name::Symbol)
    dct = ctx.data
    if haskey(dct, CONTEXT_PATH_KEY)
        push!(dct[CONTEXT_PATH_KEY], name)
    else
        dct[CONTEXT_PATH_KEY] = Symbol[name]
    end
    return dct
end

call_path(ctx::Context{Dict{Any,Any}}) = get(ctx.data, CONTEXT_PATH_KEY, nothing)
