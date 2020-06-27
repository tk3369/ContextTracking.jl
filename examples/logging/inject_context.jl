# Inject context information to the logger via TransformerLogger

using ContextTracking
using Logging
using LoggingExtras

# Create a transformer logger that appends context data to the existing kwargs
context_logger = TransformerLogger(current_logger()) do log
    # prepare pairs of context data with custom prefix
    prefix = "context."
    kv = [Symbol(prefix, k) => v for (k,v) in context()]
    # merge context data to kwargs
    updated_kwargs = (kv..., log.kwargs...)
    merge(log, (; kwargs = updated_kwargs))
end

# Top level function
function foo()
    @memo x = 1
    bar()
end

# Lower level function that inherits parent context
function bar()
    y = 2
    @info "inside bar" y
end

# Test!
with_logger(context_logger) do
    foo()
end
#= Result
julia> with_logger(context_logger) do
           foo()
       end
┌ Info: inside bar
│   context.x = 1
└   y = 2
=#
