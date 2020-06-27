# context data management tests

@testset "Basic Operation" begin
    c = context()
    @test c.generations == 1

    # add entries to current context
    push!(c, "key1" => 1)
    push!(c, "key2" => "hey")
    @test length(c) == 2
    @test c.data["key1"] == 1
    @test c.data["key2"] == "hey"

    # save current context to stack
    save(c)
    @test c.generations == 2   # current + one saved context
    @test length(c.data) == 2

    # add more "color" to current context
    push!(c, "key3" => :cool)
    @test length(c.data) == 3
    @test sort(collect(keys(c.data))) == ["key1", "key2", "key3"]

    # restore the prior context
    restore(c)
    @test c.generations == 1
    @test length(c.data) == 2
    @test sort(collect(keys(c.data))) == ["key1", "key2"]

    # empty context data
    empty!(c)
    @test length(c.data) == 0
end

@testset "Non-Dict context data" begin
    # create custom context; use random id to avoid getting the default
    c = context(id = UInt(rand(UInt)), container = String[])
    push!(c, "hello")
    push!(c, "world")

    @test length(c.data) == 2
    @test c.data == [ "hello", "world"]
end
