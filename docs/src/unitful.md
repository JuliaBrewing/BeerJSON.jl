# Unitful extension

With [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) and
[UnitfulBrewing.jl](https://github.com/JuliaBrewing/UnitfulBrewing.jl) loaded, the package
extension `BeerJSONUnitfulExt` maps the units of BeerJSON to Unitful units, to display the
values of a document as quantities, for scripting, and as building blocks for the
conversions of BrewQuiver.jl. It has no working types, internal units or calculations: those
belong in BrewQuiver.jl.

UnitfulBrewing is not registered yet: install it with
`Pkg.add(url = "https://github.com/JuliaBrewing/UnitfulBrewing.jl")`.

```@example unitful
using BeerJSON
using Unitful, UnitfulBrewing
```

## Quantities

`quantity(x)` gives the value of a measurement (any of the types with a `unit` and a `value`,
such as `VolumeType`, `TemperatureType` or `GravityType`) as a Unitful quantity, **in the
unit of the file**:

```@example unitful
file = joinpath(pkgdir(BeerJSON), "test", "samples", "converted", "Kolsh.json")
recipe = only(readjson(BeerJSONParser, file).beerjson.recipes)
quantity(recipe.batch_size)
```

```@example unitful
uconvert(u"gal", quantity(recipe.batch_size))
```

```@example unitful
[quantity(s.step_temperature) for s in recipe.mash.mash_steps]
```

```@example unitful
[(f.name, quantity(f.amount), quantity(f.color)) for f in recipe.ingredients.fermentable_additions]
```

## From quantities

The measurement types can be constructed from quantities, with the value written in a
BeerJSON unit given by the keyword argument `unit`:

```@example unitful
VolumeType(5u"gal"; unit = "l")
```

Without `unit`, the BeerJSON unit of the unit of the quantity is used if there is one, and
else a default unit (`"l"` for volumes, `"kg"` for masses, `"min"` for times, `"C"` for
temperatures, `"sg"` for gravities, `"SRM"` for colors, `"ppm"` for concentrations, ...):

```@example unitful
VolumeType(5u"gal"), VolumeType(0.02u"m^3")
```

They work with other numeric types too, as `VolumeType{BigInt, BigFloat}(q)`. So the values
round trip, `T(quantity(x)) == x`:

```@example unitful
VolumeType(quantity(recipe.batch_size)) == recipe.batch_size
```

Temperatures in °C and °F are affine units, and are converted as such:

```@example unitful
TemperatureType(67u"°C"; unit = "F")
```

`TimeType` stores whole numbers (the schema has integers there), so a time must be a whole
number in the chosen unit:

```@example unitful
TimeType(1.5u"hr"; unit = "min")
```

## Equivalences: gravity and concentration

Specific gravity and degrees Plato (or Brix) measure different things, and are not related
by a factor: UnitfulBrewing gives them different dimensions and converts between them with
*equivalences* (from [UnitfulEquivalences.jl](https://github.com/sostock/UnitfulEquivalences.jl)).
The constructors use them when the dimensions of the quantity and of the BeerJSON unit
differ, with `SugarGravity()` by default for gravities, which converts by
``°P = 259 (1 - 1/\mathrm{sg})``:

```@example unitful
GravityType(1.040u"sg"; unit = "plato")
```

```@example unitful
GravityType(12u"°P"; unit = "sg")
```

Another equivalence can be given with the keyword argument `equivalence`, such as
`SugarGravityQuad()`, the quadratic formula of UnitfulBrewing:

```@example unitful
GravityType(1.040u"sg"; unit = "plato", equivalence = SugarGravityQuad())
```

Since specific gravities are dimensionless, a gravity is only built from quantities in `sg`
or in gravity units `gu`, so that a percentage or another ratio is not silently taken as a
specific gravity:

```@example unitful
GravityType(40u"gu")
```

Concentrations in ppm or ppb and in mg/l are converted with `DensityConcentration()`, which
takes 1 ppm as 1 mg/l:

```@example unitful
ConcentrationType(150u"mg/L"; unit = "ppm")
```

Colors in EBC are proportional to SRM, and degrees Lovibond are affine in SRM, so these are
plain unit conversions in UnitfulBrewing:

```@example unitful
ColorType(10u"SRM"; unit = "EBC"), ColorType(10u"SRM"; unit = "Lovi")
```

## Percentages, counts and pH

* Percentages (`PercentType`, unit `"%"`) are quantities in Unitful's `percent`, so that
  `uconvert(NoUnits, 5u"percent") == 0.05`. `PercentType` is built from dimensionless
  quantities (`5u"percent"`, `0.5u"permille"`), not from plain numbers, which would be
  ambiguous (0.05 or 5%?).
* Counts (`UnitType`, with units `"1"`, `"unit"`, `"each"`, `"dimensionless"` and `"pkg"`)
  stay plain numbers: `quantity` gives the number, and `UnitType(2; unit = "pkg")` builds
  one, with the unit `"1"` by default.
* pH (`AcidityType`) is a logarithmic scale: `quantity` gives a `pH⁺` value of
  UnitfulBrewing, and `AcidityType(5.4u"pH⁺")` builds one.

```@example unitful
quantity(PercentType(unit = "%", value = 4.5)), quantity(UnitType(unit = "pkg", value = 2)),
quantity(AcidityType(unit = "pH", value = 5.4))
```

## The tables

`unit_table(U)` gives the Unitful unit of each BeerJSON unit of the unit enumeration `U`,
and `unsupported_units(U)` the units without one, with the reason. `unitful_unit` gives the
unit of a single BeerJSON unit:

```@example unitful
unitful_unit(VolumeUnitType("gal")), unitful_unit(GravityUnitType, "plato")
```

These are all the tables:

```@eval
using BeerJSON, Unitful, UnitfulBrewing, Markdown
const EXT = Base.get_extension(BeerJSON, :BeerJSONUnitfulExt)
rows = ["| BeerJSON unit type | BeerJSON unit | Unitful unit |", "|:---|:---|:---|"]
for U in sort(collect(keys(EXT.TABLES)); by = nameof)
    table, unsupported = unit_table(U), unsupported_units(U)
    for s in BeerJSON.BeerJSONTypes._enumvalues(U)
        u = haskey(table, s) ? "`$(table[s])`" : "unsupported"
        s == EXT.TABLES[U].default && (u *= " (default)")
        push!(rows, "| `$(nameof(U))` | `$s` | $u |")
    end
end
Markdown.parse(join(rows, "\n"))
```

Some notes on the choices:

* Volumes in `tsp`, `tbsp`, `floz`, `cup`, `pt`, `qt` and `gal` are US customary units
  (the cup is 8 US fluid ounces).
* In the specific heats, `"Cal/(g C)"` is taken as the calorie (4.184 J) per gram and
  kelvin, so that water has a specific heat of about 1 in it as in `"BTU/(lb F)"`, and the
  `C` and `F` are differences of temperatures (kelvin and rankine).
* `"brix"` is `Brix` of UnitfulBrewing, which takes it as equal to degrees Plato.

## Unsupported units

Some units of BeerJSON have no correct counterpart in UnitfulBrewing yet; using them throws
an `ArgumentError` with the reason:

```@example unitful
unsupported_units(VolumeUnitType)
```

```@example unitful
unsupported_units(CarbonationUnitType)
```

* the imperial volumes (`ifloz`, `ipt`, `iqt`, `igal`, `ibbl`): UnitfulBrewing defines
  `ifloz` as a length (28.4130625 mm instead of mL), so they have the wrong dimension;
* the barrel (`bbl`): UnitfulBrewing defines it as 42 US gallons, the barrel of oil, instead
  of the US beer barrel of 31 US gallons;
* volumes of CO₂ (`vols`): UnitfulBrewing does not define them yet, nor their equivalence
  with g/l.

These are to be fixed in UnitfulBrewing, and then supported here.
