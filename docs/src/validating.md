# Validating and writing

The constructors of the types only convert the values to the types of their fields. They
enforce the structure of the schema (the types of the properties, the required properties,
the enumeration types), but not its constraints, such as the values allowed for an
enumeration, or the minimum number of steps of a mash. This keeps them cheap, which matters
for brewing software that converts its own working types to these.

The checks of the constraints are done by `validate`, `violations` and `isvalid`, and before
writing.

```@example validating
using BeerJSON

file = joinpath(pkgdir(BeerJSON), "test", "samples", "converted", "Kolsh.json")
doc = readjson(BeerJSONParser, file)
isvalid(doc)
```

A unit that is not one of BeerJSON is accepted by the constructor...

```@example validating
v = VolumeType(unit = "litre", value = 20)
```

...but it is not valid:

```@example validating
isvalid(v)
```

```@example validating
foreach(println, violations(v))
```

`violations` lists the problems found in a value and in the values nested in it, with their
locations:

```@example validating
recipe = only(doc.beerjson.recipes)
bad = setfields(doc; beerjson = setfields(doc.beerjson;
    recipes = [setfields(recipe; batch_size = v)]))
foreach(println, violations(bad))
```

`validate(x)` returns `x` if it is valid, and else throws a `SchemaValidationError` listing
the problems:

```@example validating
try
    validate(bad)
catch e
    showerror(stdout, e)
end
```

## Writing

`writejson(file, x)` and `tojson(x)` validate before writing, so invalid documents are not
written:

```@example validating
try
    tojson(bad)
catch e
    showerror(stdout, e)
end
```

Valid documents are written with the same content as they were read:

```@example validating
using JSON

JSON.parse(tojson(doc)) == JSON.parse(read(file, String))
```

```julia
writejson("Kolsh-copy.json", doc)
```

The validation can be skipped with `validate = false`, as in `tojson(bad; validate = false)`.

Reading is not validated, as it would slow it down: use `validate(readjson(BeerJSONParser, file))`
for that.

## Formats

Strings with a `format` in the schema, such as dates, are checked too. JSON Schema treats
`format` as an annotation by default, so these checks can be turned off with
`check_formats!(false)` (and back on with `check_formats!(true)`).
