# Test tracing functionalities

module TracingTest
    using ContextTracking
    using Test

    @ctx function foo()
        @memo x = 1
        me = "not visible downstream"
        bar()
    end

    @ctx function bar()
        @memo y = 2
        baz()
    end

    @ctx function baz()
        c = context()
        @test c.path == [:foo, :bar, :baz]
        @test c.data[:x] == 1
        @test c.data[:y] == 2
        @test !haskey(c.data, :me)
    end

    __init__() = foo()
end
