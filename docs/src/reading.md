# Reading a recipe

A BeerJSON document is read with `readjson`, given the root type `BeerJSONParser` (or
`RootType`), or parsed from a string with `fromjson`. Here we read one of the sample
documents of BeerJSON, a Kölsch recipe converted from BeerXML:

```@example reading
using BeerJSON

file = joinpath(pkgdir(BeerJSON), "test", "samples", "converted", "Kolsh.json")
doc = readjson(BeerJSONParser, file)
typeof(doc)
```

The content of the document is in the field `beerjson`, with the BeerJSON version and
lists of recipes, styles, hop varieties, equipments, and so on:

```@example reading
doc.beerjson.version
```

```@example reading
recipe = only(doc.beerjson.recipes)
recipe.name, recipe.type
```

The fields of the types are those of the schema, with optional ones `nothing` when absent:

```@example reading
fieldnames(RecipeType)
```

Enumerations are wrapper types, with the value in the field `value`:

```@example reading
recipe.type.value
```

## Style and batch size

```@example reading
style = recipe.style
style.name, style.category, style.style_guide
```

Measurements have a `unit`, from the units of the schema, and a `value`:

```@example reading
recipe.batch_size
```

```@example reading
println(recipe.batch_size.value, " ", recipe.batch_size.unit)
```

## Fermentables, hops and mash steps

```@example reading
for f in recipe.ingredients.fermentable_additions
    println(rpad(f.name, 24), f.amount.value, " ", f.amount.unit, ", ", f.color.value, " ", f.color.unit)
end
```

```@example reading
for h in recipe.ingredients.hop_additions
    t = h.timing
    println(rpad(h.name, 16), h.amount.value, " ", h.amount.unit, ", alpha acid ",
            h.alpha_acid.value, h.alpha_acid.unit, ", ", t.use, " ",
            t.time === nothing ? "" : string(t.time.value, " ", t.time.unit))
end
```

```@example reading
for s in recipe.mash.mash_steps
    println(rpad(s.name, 24), s.type, ": ", s.step_temperature.value, " ",
            s.step_temperature.unit, " for ", s.step_time.value, " ", s.step_time.unit)
end
```

## Unknown properties

Properties that are not in the schema (where the schema allows them) are kept in the field
`_extra`, so that nothing is lost when a document is read and written back:

```@example reading
recipe.ingredients.hop_additions[1]._extra
```
