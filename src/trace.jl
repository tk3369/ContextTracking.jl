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
macro ctx(ex, label = nothing)
    ctx = context()
    def = splitdef(ex)
    name = something(label, string(def[:name]))
    def[:body] = quote
        try
            save($ctx)
            ContextTools._pushappend!($ctx, "_ContextPath", $name)
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
    @capture(ex, x_ = y_) || error("Not an assignment")
    sym = QuoteNode(String(x))
    return quote
        val = $(esc(ex))
        push!(context(), $sym => val)
    end
end

function _pushappend!(c::Context{Dict{Any,Any}}, key::AbstractString, s::AbstractString)
    dct = c.data
    if haskey(dct, key)
        dct[key] = dct[key] * "." * s
    else
        dct[key] = s
    end
    return dct
end
