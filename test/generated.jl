# The committed generated code is up to date with the schemas and `gen/generate.jl`
@testset "Generated code is up to date" begin
    generator = Module()
    Base.include(generator, joinpath(@__DIR__, "..", "gen", "generate.jl"))
    out = joinpath(mktempdir(), "generated")
    Base.invokelatest(generator.generate_beerjson, out)
    committed = joinpath(@__DIR__, "..", "src", "generated")
    @test sort(readdir(out)) == sort(readdir(committed))
    for f in readdir(out)
        same = read(joinpath(out, f), String) == read(joinpath(committed, f), String)
        same || @info "`src/generated/$f` is out of date: run `julia --project=gen gen/generate.jl`"
        @test same
    end
end
