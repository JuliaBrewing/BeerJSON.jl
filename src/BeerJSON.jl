"""
    BeerJSON

Julia types for reading, writing and validating [BeerJSON](https://github.com/beerjson/beerjson)
1.0.1 documents.

The types are generated from the official JSON Schema by
[JSONSchema2Types.jl](https://github.com/rmsrosa/JSONSchema2Types.jl), into the submodule
`BeerJSON.BeerJSONTypes`, whose names are all re-exported. The root of a document is
[`BeerJSONParser`](@ref) (also `RootType`).

With [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) and
[UnitfulBrewing.jl](https://github.com/JuliaBrewing/UnitfulBrewing.jl) loaded, the extension
`BeerJSONUnitfulExt` adds [`quantity`](@ref), [`unitful_unit`](@ref), [`unit_table`](@ref),
[`unsupported_units`](@ref) and constructors of the measurement types from quantities.
"""
module BeerJSON

# The generated code: never edit it, regenerate it with `gen/generate.jl`.
include(joinpath("generated", "BeerJSONTypes.jl"))
using .BeerJSONTypes

# re-export the API and the types of the generated module
for name in names(BeerJSONTypes)
    name === :BeerJSONTypes && continue
    @eval export $name
end

include("show.jl")
include("unitful_api.jl")

end # module BeerJSON
