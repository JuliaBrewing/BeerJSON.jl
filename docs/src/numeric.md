# Numeric types

The types are parametric in the types of their numbers: `RecipeType{I, T}`, with
`I <: Integer` for the integers of the schema (e.g. the values of `TimeType`) and `T <: Real`
for the other numbers, passed on to the types they contain. They default to `Int64` and
`Float64`:

```@example numeric
using BeerJSON

VolumeType(unit = "l", value = 20)
```

```@example numeric
typeof(VolumeType(unit = "l", value = 20))
```

Other types can be chosen when constructing or reading values. With `BigInt` and
`BigFloat`, numbers are read with full precision:

```@example numeric
file = joinpath(pkgdir(BeerJSON), "test", "samples", "converted", "Kolsh.json")
doc = readjson(BeerJSONParser{BigInt, BigFloat}, file)
recipe = only(doc.beerjson.recipes)
typeof(recipe.batch_size)
```

```@example numeric
VolumeType{Int32, Float32}(unit = "l", value = 2.5)
```

```@example numeric
VolumeType{Int, Rational{Int}}(unit = "l", value = 0.5)
```
