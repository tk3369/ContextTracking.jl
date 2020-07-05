using ContextTracking
using Logging
using LoggingFacilities

# Top level function
@ctx function foo()
    @memo x = 1
    @memo y = 2
    bar()
end

# Lower level function that inherits parent context
@ctx function bar()
    z = 3
    @info "inside bar" z
end

# =============================================================================
# Example 1: just include context data as kwargs
# =============================================================================

context_logger = build(current_logger(), inject(KwargsLocation(), () -> context().data));

with_logger(context_logger) do
    foo()
end
#=
julia> with_logger(context_logger) do
           foo()
       end
┌ Info: inside bar
│   y = 2
│   x = 1
└   z = 3
=#

# =============================================================================
# Example 2: logging context data as JSON
# =============================================================================

using JSON

# use MessageOnlyLogger here to avoid unwanted garbage e.g. level prefix.
json_logger = build(MessageOnlyLogger(),
                    # inject context data into kwargs location
                    inject(KwargsLocation(), (:Context => context().data,)),
                    # migrate level to kwargs location
                    migrate(LevelProperty(), KwargsProperty(); label = :Level, transform = string),
                    # migrate message to kwargs location
                    migrate(MessageProperty(), KwargsProperty(); label = :Message),
                    # migrate kwargs data to message location as JSON format
                    migrate(KwargsProperty(), MessageProperty(); transform = x -> json(x, 2))
                    );

with_logger(json_logger) do
    foo()
end

#=
julia> with_logger(json_logger) do
           foo()
       end
{
  "Message": "inside bar",
  "Level": "Info",
  "Context": {
    "y": 2,
    "x": 1
  },
  "z": 3
}
=#
