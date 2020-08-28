module ContextTracking

using Dates: now
using DataStructures: Stack
using DocStringExtensions
using ExprTools: combinedef, splitdef

export Context
export context
export @ctx, @memo

include("types.jl")
include("context.jl")
include("singleton.jl")
include("trace.jl")

end # module
