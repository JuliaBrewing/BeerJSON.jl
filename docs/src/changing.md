# Changing values

The types are immutable. `setfields` returns a copy of a value with some of its fields
changed, converting plain values to the types of the fields:

```@example changing
using BeerJSON

file = joinpath(pkgdir(BeerJSON), "test", "samples", "converted", "Kolsh.json")
doc = readjson(BeerJSONParser, file)
recipe = only(doc.beerjson.recipes)

recipe2 = setfields(recipe; batch_size = (unit = "l", value = 40), name = "Big Kölsch")
recipe2.name, recipe2.batch_size
```

The original is unchanged:

```@example changing
recipe.name, recipe.batch_size
```

Nested values are changed by rebuilding the values that contain them:

```@example changing
doc2 = setfields(doc; beerjson = setfields(doc.beerjson; recipes = [recipe2]))
only(doc2.beerjson.recipes).name
```

## With Accessors.jl

[Accessors.jl](https://github.com/JuliaObjects/Accessors.jl)'s `@set` makes the nested
changes easier:

```@example changing
using Accessors

doc3 = @set doc.beerjson.recipes[1].batch_size.value = 30
only(doc3.beerjson.recipes).batch_size
```

```@example changing
hop = recipe.ingredients.hop_additions[1]
hop2 = @set hop.amount = MassType(unit = "g", value = 30)
hop2.amount
```

## Constructing values

Values are constructed with keyword arguments, with plain values converted:

```@example changing
VolumeType(unit = "gal", value = 5)
```

```@example changing
TemperatureType(unit = "C", value = 67)
```
