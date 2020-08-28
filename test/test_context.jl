# context data management tests

@testset "Basic operations" begin
    c = context()

    # property access
    @test c.generations == 1
    @test c.id > 0
    @test c.hex_id isa String
    @test length(c.hex_id) > 0
    @test c.path isa Vector{Symbol}
    @test length(c.path) == 0
    @test propertynames(c) ∩ (:id, :hex_id, :generations, :data, :path) |> length == 5

    # add entries to current context
    push!(c, "key1" => 1)
    push!(c, "key2" => "hey")
    @test length(c) == 2

    # Test direct data access
    @test c["key1"] == 1
    @test c["key2"] == "hey"

    # save current context to stack
    ContextTracking.save(c)
    @test c.generations == 2   # current + one saved context
    @test length(c) == 2

    # add more "color" to current context.  Assumes Dict.
    push!(c, "key3" => :cool)
    @test length(c) == 3
    @test sort(collect(keys(c.data))) == ["key1", "key2", "key3"]

    # restore the prior context
    ContextTracking.restore(c)
    @test c.generations == 1
    @test length(c) == 2
    @test sort(collect(keys(c.data))) == ["key1", "key2"]

    # test iterability
    @test length(collect(c)) == 2
    @test length(kv for kv in c) == 2

    # empty context data
    empty!(c)
    @test length(c) == 0

    # print
    let io = IOBuffer()
        show(io, c)
        @test length(String(take!(io))) > 0
    end
end

@testset "Custom container" begin
    # create custom context; use random id to avoid getting the default
    c = context(id = UInt(rand(UInt)), container = String[])
    push!(c, "hello")
    push!(c, "world")

    @test length(c.data) == 2
    @test c.data == [ "hello", "world"]
end

@testset "Error handling" begin
    c = context()
    @test_throws UndefVarError c.whatever
end
