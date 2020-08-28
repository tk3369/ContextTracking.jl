"""
    @ctx <function definition> [label]

Define a function that is context-aware i.e. save the current context
before executing the function and restore the context right before
returning to the caller. So, if the function modifies the context
using (see [`@memo`](@ref)), then the change is not visible the caller.
```
"""
macro ctx(ex, label = nothing)
    def = splitdef(ex)
    name = QuoteNode(label !== nothing ? Symbol(label) : def[:name])
    ctx = gensym()
    def[:body] = quote
        $ctx = ContextTracking.context()
        try
            ContextTracking.save($ctx)
            push!($ctx.path, $name)
            $(def[:body])
        finally
            pop!($ctx.path)
            ContextTracking.restore($ctx)
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
    val = gensym()
    return esc(quote
        $val =$ex
        push!(ContextTracking.context(), $sym => $val)
    end)
end
