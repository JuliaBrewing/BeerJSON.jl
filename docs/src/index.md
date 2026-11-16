# BeerJSON.jl

Julia types for reading, writing and validating [BeerJSON](https://github.com/beerjson/beerjson)
1.0.1 documents.

The types are generated from the official BeerJSON 1.0.1 JSON Schema by
[JSONSchema2Types.jl](https://github.com/rmsrosa/JSONSchema2Types.jl), so that they mirror the
schema: one Julia type per type of the schema, with the same fields, enumerations as wrapper
types, and the checks of the schema available to validate documents before writing them.

## An exchange layer

BeerJSON.jl is the **exchange layer** of a homebrewing toolkit: its types are the documents
of BeerJSON as they are, to read and write files. It has no calculations and no types of
its own, and it is kept faithful to the schema, light (it only depends on JSON.jl), and easy
to regenerate when the schema changes.

The **working layer** is the separate package BrewQuiver.jl (in preparation), with its own
types based on [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) quantities, the
calculations of a brewing software (in the spirit of
[Brewtarget](https://github.com/Brewtarget/brewtarget)), and the conversions between its
types and those of BeerJSON.jl.

Between the two, the [Unitful extension](unitful.md) of BeerJSON.jl maps the units of BeerJSON to
Unitful units, with the brewing units of
[UnitfulBrewing.jl](https://github.com/JuliaBrewing/UnitfulBrewing.jl): the building blocks of
those conversions, also handy for displaying values and for scripting.

## Installation

The package is not registered yet. Install it from GitHub:

```julia
julia> using Pkg

julia> Pkg.add(url = "https://github.com/rmsrosa/BeerJSON.jl")
```

## Quick start

```julia
using BeerJSON

doc = readjson(BeerJSONParser, "recipe.json")    # the whole document
recipe = doc.beerjson.recipes[1]
recipe.batch_size                                 # VolumeType(VolumeUnitType("l"), 20.0)

recipe2 = setfields(recipe; batch_size = (unit = "l", value = 40))
writejson("recipe2.json", setfields(doc; beerjson = setfields(doc.beerjson; recipes = [recipe2])))
```

The root type of a document is `BeerJSONParser`, also available as `RootType`. (It can't be
named `BeerJSON`, as the root of the schema is, since that is the name of the package.)

## How the code is organized

* `schemas/`: the BeerJSON 1.0.1 schemas, from tag `v1.0.1` of
  [beerjson/beerjson](https://github.com/beerjson/beerjson) (MIT License);
* `gen/generate.jl`: regenerates the code in `src/generated/` with JSONSchema2Types.jl (a
  dependency of `gen/` only, pinned in `gen/Project.toml`);
* `src/generated/`: the generated module, `BeerJSON.BeerJSONTypes`, committed so that users
  don't need JSONSchema2Types. It is never edited by hand. The checks of the schema are in
  `src/generated/validation.jl`;
* `src/BeerJSON.jl`: the package module, which includes the generated module and re-exports
  its names, and the hand-written additions in other files of `src/`;
* `ext/BeerJSONUnitfulExt.jl`: the Unitful extension.

To regenerate the code (with Julia 1.11 or later):

```shell
julia --project=gen -e 'using Pkg; Pkg.instantiate()'
julia --project=gen gen/generate.jl
```

The tests check that the committed code is the same as the regenerated one.
