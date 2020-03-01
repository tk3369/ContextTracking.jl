module ContextLib

using Dates: now
using DataStructures: Stack
using DocStringExtensions
using MacroTools: combinedef, splitdef, @capture

export Context
export context, save, restore
export @ctx, @memo
export ContextLogger

include("constants.jl")
include("context.jl")
include("singleton.jl")
include("trace.jl")
include("logger.jl")

end # module
