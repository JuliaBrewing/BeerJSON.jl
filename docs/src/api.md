# API

```@docs
BeerJSON
```

## Reading and writing

```@docs
readjson
fromjson
writejson
tojson
fromdict
todict
```

The root type of the documents, `BeerJSONParser`, and its alias `RootType`, are in
[Generated types](types.md).

## Changing values

```@docs
setfields
```

## Validation

```@docs
validate
violations
check_formats!
SchemaValidationError
```

`isvalid(x)` is `isempty(violations(x))`.

## Unitful quantities

These need Unitful.jl and UnitfulBrewing.jl to be loaded (see [Unitful extension](unitful.md)).

```@docs
quantity
unitful_unit
unit_table
unsupported_units
```

## Abstract types

```@docs
AbstractSchemaObject
AbstractSchemaEnum
```

## Checks in the constructors

The generated module also has `checks!`, `checks` and `with_checks`, which turn on or off
the checks of the constraints in the constructors of the types. They only apply to modules
generated with the checks in the constructors: here, the types are generated with the
validation in a separate file (`validation = :separate`), so the constructors never check
the constraints, and `validate`, `violations`, `isvalid`, `tojson` and `writejson` always do.
They are not exported.

```@docs
BeerJSON.BeerJSONTypes.checks!
BeerJSON.BeerJSONTypes.checks
BeerJSON.BeerJSONTypes.with_checks
```
