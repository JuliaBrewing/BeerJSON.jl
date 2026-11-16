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

## Displaying values

In the REPL, and in `display`, a record is shown as a tree of the fields that are present,
with measurements as their value and unit, and lists of more than six items shortened:

```@example reading
recipe
```

Numbers are shown with 6 significant digits there, as in other compact displays; the
values themselves are not rounded. The tree of the whole document, with no lists
shortened, is printed with `show(stdout, MIME"text/plain"(), doc)`.

Every part of a recipe is shown in the same way. The ingredients:

```@example reading
recipe.ingredients
```

A list of records, below the usual summary line of a vector, such as the hop additions:

```@example reading
recipe.ingredients.hop_additions
```

The mash, with its steps, and a single step:

```@example reading
recipe.mash
```

```@example reading
recipe.mash.mash_steps[1]
```

The boil and the style:

```@example reading
recipe.boil
```

```@example reading
recipe.style
```

And a single measurement:

```@example reading
recipe.batch_size
```

The one-line form, used by `repr` and inside other containers, such as tuples, is a call
to the constructor, which can be evaluated back:

```@example reading
repr(recipe.batch_size)
```

and `print`, `string` and string interpolation give the value and the unit of a
measurement:

```@example reading
println("Batch size: ", recipe.batch_size)
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
recipe.batch_size.value, recipe.batch_size.unit.value
```

## Fermentables, hops and mash steps

```@example reading
for f in recipe.ingredients.fermentable_additions
    println(rpad(f.name, 24), f.amount, ", ", f.color)
end
```

```@example reading
for h in recipe.ingredients.hop_additions
    t = h.timing
    println(rpad(h.name, 16), h.amount, ", alpha acid ", h.alpha_acid, ", ", t.use, " ",
            something(t.time, ""))
end
```

```@example reading
for s in recipe.mash.mash_steps
    println(rpad(s.name, 24), s.type, ": ", s.step_temperature, " for ", s.step_time)
end
```

## Unknown properties

Properties that are not in the schema (where the schema allows them) are kept in the field
`_extra`, so that nothing is lost when a document is read and written back:

```@example reading
recipe.ingredients.hop_additions[1]._extra
```
