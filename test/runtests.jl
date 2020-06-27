using ContextTracking
using Test

@testset "ContextTracking.jl" begin
    include("test_context.jl")
    include("test_trace.jl")
end
