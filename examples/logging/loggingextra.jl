# Inject context information to the logger via TransformerLogger

using ContextTracking
using Logging
using LoggingExtras

# Top level function
function foo()
    @memo x = 1
    @memo y = 2
    bar()
end

# Lower level function that inherits parent context
function bar()
    z = 3
    @info "inside bar" z
end

# Create a transformer logger that appends context data to the existing kwargs
context_logger = TransformerLogger(current_logger()) do log
    updated_kwargs = (context().data..., log.kwargs...)
    merge(log, (; kwargs = updated_kwargs))
end

# Test!
with_logger(context_logger) do
    foo()
end

#=
julia> with_logger(context_logger) do
           foo()
       end
┌ Info: inside bar
│   context.x = 1
└   y = 2
=#
