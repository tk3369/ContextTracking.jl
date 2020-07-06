# Test tracing functionalities

module TracingTest
    using ContextTracking
    using Test

    @ctx function foo()
        @memo x = 1
        me = "not visible downstream"
        bar()
        @test context().path == [:foo]
    end

    @ctx function bar()
        @memo y = 2
        z = 3
        @memo z
        baz()
        @test context().path == [:foo, :bar]
    end

    @ctx function baz()
        c = context()
        @test c.path == [:foo, :bar, :baz]
        @test c.data[:x] == 1
        @test c.data[:y] == 2
        @test c.data[:z] == 3
        @test !haskey(c.data, :me)
    end

    __init__() = foo()
end
