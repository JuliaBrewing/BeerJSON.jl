# Functions implemented by the package extension `BeerJSONUnitfulExt`, which is loaded
# together with Unitful.jl and UnitfulBrewing.jl.

export quantity, unitful_unit, unit_table, unsupported_units

"""
    quantity(x)

The value of the measurement `x` (a `VolumeType`, `MassType`, `TemperatureType`, ... with
fields `unit` and `value`) as a Unitful quantity, in the unit of the BeerJSON value.

```julia
quantity(VolumeType(unit = "gal", value = 5))     # 5.0 gal
quantity(TemperatureType(unit = "C", value = 67))  # 67.0 °C
```

`PercentType` gives a quantity in `percent`, `AcidityType` a logarithmic `pH⁺` value, and
`UnitType` (counts in `"each"`, `"pkg"`, ...) a plain number.

Throws an `ArgumentError` for a unit that has no Unitful counterpart (see
[`unsupported_units`](@ref)).

Requires Unitful.jl and UnitfulBrewing.jl to be loaded.
"""
function quantity end

"""
    unitful_unit(u)
    unitful_unit(U, s)

The Unitful unit of the BeerJSON unit `u`, a value of a unit enumeration such as
`VolumeUnitType("l")`, or given by the enumeration type `U` and the string `s`, as in
`unitful_unit(VolumeUnitType, "l")`.

Throws an `ArgumentError` for a unit that has no Unitful counterpart.

Requires Unitful.jl and UnitfulBrewing.jl to be loaded.
"""
function unitful_unit end

"""
    unit_table(U)

A `Dict` from the BeerJSON unit strings of the unit enumeration `U` (e.g. `VolumeUnitType`)
that have a Unitful counterpart to that unit. The others are in
[`unsupported_units`](@ref)`(U)`.

Requires Unitful.jl and UnitfulBrewing.jl to be loaded.
"""
function unit_table end

"""
    unsupported_units(U)

A `Dict` from the BeerJSON unit strings of the unit enumeration `U` that have no Unitful
counterpart to the reason why.

Requires Unitful.jl and UnitfulBrewing.jl to be loaded.
"""
function unsupported_units end

const _UNITFUL_FUNCTIONS = (quantity, unitful_unit, unit_table, unsupported_units)

function __init__()
    Base.Experimental.register_error_hint(MethodError) do io, exc, argtypes, kwargs
        quantityarg = any(t -> nameof(t isa UnionAll ? Base.unwrap_unionall(t) : t) in (:Quantity, :Gain, :Level), argtypes)
        if exc.f in _UNITFUL_FUNCTIONS ||
           (quantityarg && exc.f isa Type && parentmodule(exc.f) === BeerJSONTypes)
            print(io, "\nThe conversions between BeerJSON values and Unitful quantities need ",
                  "both Unitful.jl and UnitfulBrewing.jl: `using Unitful, UnitfulBrewing`.")
        end
    end
end
