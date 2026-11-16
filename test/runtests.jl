using BeerJSON
using JSON
using Test

const SAMPLES = joinpath(@__DIR__, "samples")
const SAMPLE_FILES = [joinpath(dir, f) for dir in readdir(SAMPLES; join = true) if isdir(dir)
                      for f in readdir(dir) if endswith(f, ".json")]

@testset "BeerJSON.jl" begin
    include("documents.jl")
    include("show.jl")
    include("generated.jl")
    include("unitful.jl")
end
