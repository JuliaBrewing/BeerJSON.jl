# BeerJSON.jl

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://rmsrosa.github.io/BeerJSON.jl/dev/)
[![CI](https://github.com/rmsrosa/BeerJSON.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/rmsrosa/BeerJSON.jl/actions/workflows/CI.yml)

Julia types for reading, writing and validating [BeerJSON](https://github.com/beerjson/beerjson)
1.0.1 documents, generated from the official JSON Schema with
[JSONSchema2Types.jl](https://github.com/rmsrosa/JSONSchema2Types.jl).

BeerJSON.jl is an **exchange layer**: its types mirror the schema, for reading and writing
files, and it only depends on JSON.jl. The **working layer**, with types based on Unitful
quantities and the calculations for homebrewers, is the separate package BrewQuiver.jl (in
preparation), which converts between its types and these.

## Installation

The package is not registered yet:

```julia
julia> using Pkg

julia> Pkg.add(url = "https://github.com/rmsrosa/BeerJSON.jl")
```

## Usage

```julia
julia> using BeerJSON

julia> doc = readjson(BeerJSONParser, "Kolsh.json");   # the root type, also `RootType`

julia> recipe = doc.beerjson.recipes[1];

julia> recipe.name, recipe.batch_size
("Lloyd&#39;s Krispy Kolsch", VolumeType(VolumeUnitType("l"), 19.0028767))

julia> recipe.ingredients.hop_additions[1]              # records are shown as trees
HopAdditionType "Hallertauer"
├─ origin: Germany
├─ form: pellet
├─ alpha_acid: 4.8 %
├─ beta_acid: 4.0 %
├─ timing:
│  ├─ time: 60 min
│  └─ use: add_to_boil
├─ amount: 0.0332677 kg
└─ _extra (not in the schema):
   └─ use: boil

julia> recipe2 = setfields(recipe; batch_size = (unit = "litre", value = 40));  # not checked...

julia> violations(recipe2)
1-element Vector{String}:
 "batch_size.unit: invalid value \"litre\" for `VolumeUnitType`; allowed values are \"ml\", \"l\", ..."

julia> writejson("recipe.json", recipe2)                                       # ...until written
ERROR: SchemaValidationError: 1 value does not conform to the schema: ...
```

The constructors only convert values to the types of their fields; the checks of the schema
are done by `validate`, `violations` and `isvalid`, and before writing. Every sample document
of BeerJSON 1.0.1 is read and written back without changes. `BeerJSONParser{BigInt, BigFloat}`
reads numbers with full precision. Accessors.jl's `@set` works too.

With [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) and
[UnitfulBrewing.jl](https://github.com/JuliaBrewing/UnitfulBrewing.jl) loaded, an extension
maps the units of BeerJSON to Unitful:

```julia
julia> using Unitful, UnitfulBrewing

julia> quantity(recipe.batch_size)
19.0028767 L

julia> GravityType(1.040u"sg"; unit = "plato")       # through UnitfulBrewing's SugarGravity()
GravityType(GravityUnitType("plato"), 9.961538461538483)
```

See the [documentation](https://rmsrosa.github.io/BeerJSON.jl/dev/) for more.

## Regenerating the types

The generated code in `src/generated/` is committed, and never edited by hand. To regenerate
it from the schemas in `schemas/` (with Julia 1.11 or later):

```shell
julia --project=gen -e 'using Pkg; Pkg.instantiate()'
julia --project=gen gen/generate.jl
```

## Tests and documentation

```shell
julia --project=test -e 'using Pkg; Pkg.instantiate()'
julia --project=test test/runtests.jl
julia --project=docs -e 'using Pkg; Pkg.instantiate()'
julia --project=docs docs/make.jl
```

(With Julia 1.11 or later, for the `[sources]` of these projects; see `.github/workflows/CI.yml`
for Julia 1.10.)

## License

MIT; see [LICENSE](LICENSE). The BeerJSON schemas and sample documents are from
[beerjson/beerjson](https://github.com/beerjson/beerjson), also under the MIT License (see
`schemas/LICENSE` and `test/samples/LICENSE`).
