module ContextTracking

using Dates: now
using DataStructures: Stack
using DocStringExtensions
using ExprTools: combinedef, splitdef

export Context
export context, save, restore
export @ctx, @memo, call_path

include("types.jl")
include("context.jl")
include("singleton.jl")
include("trace.jl")

end # module
