"""
    @ctx

Define a function that is context-aware i.e. save the current context
before executing the function and restore the context right before
returning to the caller. So, if the function modifies the context
using (see [`@memo`](@ref)), then the change is not visible the caller.

An optional string can be added at the end of function definition for
tracking the call path.  Otherwise, function name is used.

# Example
```
julia> @ctx function foo()
    @memo x = 1
    bar()
    @info context().data
end "Foo";

julia> @ctx function bar()
    @memo y = 2
    @info context().data
end;

julia> foo()
[ Info: Dict{Any,Any}("x" => 1,"_ContextPath" => "Foo.bar","y" => 2)
[ Info: Dict{Any,Any}("x" => 1,"_ContextPath" => "Foo")
```
"""
macro ctx(ex, label::Symbol)
    ctx = context()
    def = splitdef(ex)
    name = something(label, def[:name])
    def[:body] = quote
        try
            save($ctx)
            ContextLib.trace!($ctx, $name)
            $(def[:body])
        finally
            restore($ctx)
        end
    end
    esc(combinedef(def))
end

"""
    @memo

Stroe the variable/value from the assigment statement in the current
context. See usage from [`@ctx`](@ref).
"""
macro memo(ex)
    if typeof(ex) === Symbol
        x = ex
    elseif @capture(ex, x_ = y_)
        # intentionally blank since `x` and `y` are already assigned here
    else
        error("@memo must be followed by an assignment or a variable name.")
    end
    sym = QuoteNode(String(x))
    return quote
        val = $(esc(ex))
        push!(context(), $sym => val)
    end
end

"""
    trace!(ctx, name)

Push a new value to ctx[key] so
"""
function trace!(ctx::Context{Dict{Any,Any}}, name::Symbol)
    dct = ctx.data
    key = Symbol(".TracePath")
    if haskey(dct, key)
        push!(dct[key], name)
    else
        dct[key] = Symbol[name]
    end
    return dct
end
