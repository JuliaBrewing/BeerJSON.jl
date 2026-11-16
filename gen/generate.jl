# Regenerate the Julia types of BeerJSON 1.0.1 in `src/generated/` from the schemas in
# `schemas/`, with JSONSchema2Types.jl. Run it from the root of the repository with
#
#     julia --project=gen -e 'using Pkg; Pkg.instantiate()'
#     julia --project=gen gen/generate.jl
#
# The generated code is committed, so that users of BeerJSON.jl don't need
# JSONSchema2Types. Never edit it by hand: change the options here and regenerate.
# `gen/Project.toml` pins the revision of JSONSchema2Types used.

using JSONSchema2Types

const ROOT = dirname(@__DIR__)

"""
    generate_beerjson(output = joinpath(ROOT, "src", "generated"))

Generate the module `BeerJSONTypes` into the directory `output`, one file per schema file,
with the checks of the schema in the separate file `validation.jl`. Returns the path of the
main file of the module.
"""
function generate_beerjson(output = joinpath(ROOT, "src", "generated"))
    isdir(output) && rm(output; recursive = true)
    return generate_module(joinpath(ROOT, "schemas", "beer.json"), output;
        # the module of the package is `BeerJSON`, so the root type can't be named so
        root_name = "BeerJSONParser",
        # the content of the `beerjson` property, otherwise named `BeerJSONParserBeerjson`
        type_names = Dict("#/properties/beerjson" => "BeerJSONContent"),
        module_name = "BeerJSONTypes",
        split = true,
        validation = :separate)
end

if abspath(PROGRAM_FILE) == @__FILE__
    println(generate_beerjson())
end
