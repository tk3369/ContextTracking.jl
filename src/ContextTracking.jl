module ContextTracking

using Dates: now
using DataStructures: Stack
using DocStringExtensions
using ExprTools: combinedef, splitdef

export Context
export context, save, restore
export @ctx, @memo, call_path
export ContextLogger

include("types.jl")
include("context.jl")
include("singleton.jl")
include("trace.jl")
include("logger.jl")

end # module
