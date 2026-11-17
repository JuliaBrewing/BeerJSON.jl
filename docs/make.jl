# Build the documentation with
#
#     julia --project=docs -e 'using Pkg; Pkg.instantiate()'
#     julia --project=docs docs/make.jl
#
# from the root of the repository (Julia 1.11 or later, for the `[sources]` of
# `docs/Project.toml`). The pages are written to `docs/build/`.

using Documenter
using BeerJSON
using Unitful, UnitfulBrewing

const EXT = Base.get_extension(BeerJSON, :BeerJSONUnitfulExt)

makedocs(
    sitename = "BeerJSON.jl",
    modules = [BeerJSON, EXT],
    authors = "Ricardo Rosa",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://juliabrewing.github.io/BeerJSON.jl",
        edit_link = "main",
        size_threshold_warn = 400 * 1024,
        size_threshold = 1024 * 1024,
    ),
    pages = [
        "Overview" => "index.md",
        "Reading a recipe" => "reading.md",
        "Changing values" => "changing.md",
        "Validating and writing" => "validating.md",
        "Numeric types" => "numeric.md",
        "Unitful extension" => "unitful.md",
        "API" => "api.md",
        "Generated types" => "types.md",
    ],
    checkdocs = :none,
)

deploydocs(
    repo = "github.com/JuliaBrewing/BeerJSON.jl.git",
    devbranch = "main",
    push_preview = false,
)
