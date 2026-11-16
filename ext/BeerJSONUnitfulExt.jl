"""
    BeerJSONUnitfulExt

Maps the units of BeerJSON to Unitful.jl units, with the brewing units of UnitfulBrewing.jl,
and converts between the measurement types of BeerJSON and Unitful quantities.

This is only the vocabulary of units: the working types and the calculations belong in
BrewQuiver.jl.
"""
module BeerJSONUnitfulExt

using BeerJSON
using BeerJSON: BeerJSONTypes, AbstractSchemaEnum, AbstractSchemaObject
using BeerJSON: AcidityType, AcidityUnitType, BitternessType, BitternessUnitType,
    CarbonationType, CarbonationUnitType, ColorType, ColorUnitType, ConcentrationType,
    ConcentrationUnitType, DiastaticPowerType, DiastaticPowerUnitType, GravityType,
    GravityUnitType, MassType, MassUnitType, PercentType, PercentUnitType, SpecificHeatType,
    SpecificHeatUnitType, SpecificVolumeType, SpecificVolumeUnitType, TemperatureType,
    TemperatureUnitType, TimeType, TimeUnitType, UnitType, UnitUnitType, ViscosityType,
    ViscosityUnitType, VolumeType, VolumeUnitType
import BeerJSON: quantity, unitful_unit, unit_table, unsupported_units

using Unitful
using Unitful: AbstractQuantity, Units, NoUnits, Gain, dimension, unit, ustrip, uconvert
import UnitfulBrewing
const UB = UnitfulBrewing

"""
    UnitTable

The Unitful units of a unit enumeration of BeerJSON:

- `units`: BeerJSON unit string => Unitful unit;
- `unsupported`: BeerJSON unit string => why it has no Unitful unit;
- `default`: the BeerJSON unit used to write a quantity, when none of `units` fits it;
- `equivalence`: the UnitfulEquivalences equivalence used to convert between units of
  different dimensions (e.g. specific gravity and degrees Plato), or `nothing`;
- `dimensionless`: for scales whose units are dimensionless, the only dimensionless units
  accepted (e.g. `sg` and `gu` for gravity, so that a percentage or a plain ratio is not
  taken as a specific gravity), or `nothing` to accept any.
"""
struct UnitTable
    units::Dict{String, Any}
    unsupported::Dict{String, String}
    default::String
    equivalence::Any
    dimensionless::Union{Nothing, Vector{Any}}
end

UnitTable(units, default; unsupported = Dict{String, String}(), equivalence = nothing,
          dimensionless = nothing) =
    UnitTable(Dict{String, Any}(units), Dict{String, String}(unsupported), default,
              equivalence, dimensionless === nothing ? nothing : collect(Any, dimensionless))

# The tables, one per unit enumeration of the schema, with the unit strings of the
# enumerations (`BeerJSONTypes._enumvalues(VolumeUnitType)`, ...). The tests check that
# every unit string is in `units` or in `unsupported` (none are unsupported now).
const TABLES = Dict{DataType, UnitTable}(
    VolumeUnitType => UnitTable(
        ["ml" => u"mL", "l" => u"L",
         "tsp" => UB.tsp, "tbsp" => UB.tbsp, "floz" => UB.floz, "cup" => UB.cup,
         "pt" => UB.pt, "qt" => UB.qt, "gal" => UB.gal, "bbl" => UB.bbl,
         "ifloz" => UB.ifloz, "ipt" => UB.ipt, "iqt" => UB.iqt, "igal" => UB.igal,
         "ibbl" => UB.ibbl],
        "l"),
    MassUnitType => UnitTable(
        ["mg" => u"mg", "g" => u"g", "kg" => u"kg", "lb" => u"lb", "oz" => u"oz"],
        "kg"),
    TimeUnitType => UnitTable(
        ["sec" => u"s", "min" => u"minute", "hr" => u"hr", "day" => u"d", "week" => u"wk"],
        "min"),
    TemperatureUnitType => UnitTable(["C" => u"°C", "F" => u"°F"], "C"),
    GravityUnitType => UnitTable(
        ["sg" => UB.sg, "plato" => UB.°P, "brix" => UB.Brix],
        "sg";
        equivalence = UB.SugarGravity(),
        dimensionless = [UB.sg, UB.gu]),
    ColorUnitType => UnitTable(["EBC" => UB.EBC, "Lovi" => UB.°L, "SRM" => UB.SRM], "SRM"),
    DiastaticPowerUnitType => UnitTable(["Lintner" => UB.°Lintner, "WK" => UB.°WK], "Lintner"),
    ConcentrationUnitType => UnitTable(
        ["ppm" => u"ppm", "ppb" => u"ppb", "mg/l" => u"mg/L"],
        "ppm";
        equivalence = UB.DensityConcentration()),
    BitternessUnitType => UnitTable(["IBUs" => UB.IBU], "IBUs"),
    CarbonationUnitType => UnitTable(
        ["vols" => UB.vols, "g/l" => u"g/L"],
        "g/l";
        equivalence = UB.CarbonationDensity()),
    PercentUnitType => UnitTable(["%" => u"percent"], "%"),
    AcidityUnitType => UnitTable(["pH" => UB.pH⁺], "pH"),
    # "Cal" is the calorie of the specific heat of water, 1 Cal/(g C), as for "BTU/(lb F)",
    # and "C" and "F" are differences of temperature, as kelvin and rankine
    SpecificHeatUnitType => UnitTable(
        ["Cal/(g C)" => u"cal/(g*K)", "J/(kg K)" => u"J/(kg*K)", "BTU/(lb F)" => u"btu/(lb*Ra)"],
        "J/(kg K)"),
    SpecificVolumeUnitType => UnitTable(
        ["qt/lb" => UB.qt / u"lb", "gal/lb" => UB.gal / u"lb", "gal/oz" => UB.gal / u"oz",
         "l/g" => u"L/g", "l/kg" => u"L/kg", "floz/oz" => UB.floz / u"oz",
         "m^3/kg" => u"m^3/kg", "ft^3/lb" => u"ft^3/lb"],
        "l/kg"),
    ViscosityUnitType => UnitTable(["cP" => u"cP", "mPa-s" => u"mPa*s"], "cP"),
    # counts: plain numbers
    UnitUnitType => UnitTable(
        ["1" => NoUnits, "unit" => NoUnits, "each" => NoUnits, "dimensionless" => NoUnits,
         "pkg" => NoUnits],
        "1"),
)

# the measurement types, by their unit enumeration
const MEASUREMENTS = Dict{DataType, UnionAll}(
    VolumeUnitType => VolumeType, MassUnitType => MassType, TimeUnitType => TimeType,
    TemperatureUnitType => TemperatureType, GravityUnitType => GravityType,
    ColorUnitType => ColorType, DiastaticPowerUnitType => DiastaticPowerType,
    ConcentrationUnitType => ConcentrationType, BitternessUnitType => BitternessType,
    CarbonationUnitType => CarbonationType, PercentUnitType => PercentType,
    AcidityUnitType => AcidityType, SpecificHeatUnitType => SpecificHeatType,
    SpecificVolumeUnitType => SpecificVolumeType, ViscosityUnitType => ViscosityType,
    UnitUnitType => UnitType)

_table(::Type{U}) where {U <: AbstractSchemaEnum} =
    get(TABLES, U) do
        throw(ArgumentError("`$U` is not a unit enumeration of BeerJSON"))
    end

unit_table(::Type{U}) where {U <: AbstractSchemaEnum} = copy(_table(U).units)
unsupported_units(::Type{U}) where {U <: AbstractSchemaEnum} = copy(_table(U).unsupported)

function unitful_unit(::Type{U}, s::AbstractString) where {U <: AbstractSchemaEnum}
    t = _table(U)
    haskey(t.units, s) && return t.units[s]
    haskey(t.unsupported, s) &&
        throw(ArgumentError("the BeerJSON unit $(repr(s)) of `$(nameof(U))` has no Unitful " *
                            "counterpart: " * t.unsupported[s]))
    throw(ArgumentError("$(repr(s)) is not a BeerJSON unit of `$(nameof(U))`; the units are " *
                        join(repr.(BeerJSONTypes._enumvalues(U)), ", ")))
end
unitful_unit(u::AbstractSchemaEnum) = unitful_unit(typeof(u), u.value)

# Measurement types: the BeerJSON value as a quantity, in the unit of the BeerJSON value

for T in values(MEASUREMENTS)
    T === UnitType && continue
    # (for `AcidityType`, a logarithmic `pH⁺` value)
    @eval quantity(x::$T) = x.value * unitful_unit(x.unit)
end
quantity(x::UnitType) = (unitful_unit(x.unit); x.value)          # counts: plain numbers

# Measurement types from quantities

function _fromquantity(::Type{S}, q; unit = nothing, equivalence = :default) where {S}
    U = fieldtype(S isa UnionAll ? S{Int64, Float64} : S, :unit)
    t = _table(U)
    s = unit === nothing ? _beerjson_unit(t, q) : String(unit)
    target = unitful_unit(U, s)
    eq = equivalence === :default ? t.equivalence : equivalence
    value = _convert(t, target, q, eq, s, U)
    return S(unit = s, value = _value(S, value, s))
end

# the BeerJSON unit for `q`: its own unit if it is in the table, else the default (units
# are compared with `===`, since `==` is true for different units with the same size, such
# as cP and mPa s)
function _beerjson_unit(t::UnitTable, q)
    u = unit(q)
    for (s, v) in t.units
        v === u && return s
    end
    return t.default
end

function _convert(t::UnitTable, target, q, eq, s, U)
    if dimension(target) == dimension(q)
        if dimension(q) == NoDims && t.dimensionless !== nothing && !(unit(q) in t.dimensionless)
            throw(ArgumentError("a quantity in `$(unit(q))` can't be written in the BeerJSON " *
                                "unit $(repr(s)) of `$(nameof(U))`: the dimensionless units " *
                                "accepted are $(join(t.dimensionless, ", "))"))
        end
        return ustrip(target, q)
    elseif eq !== nothing
        return ustrip(target, uconvert(target, q, eq))
    else
        throw(ArgumentError("a quantity in `$(unit(q))` can't be written in the BeerJSON " *
                            "unit $(repr(s)) of `$(nameof(U))` (`$target`): their " *
                            "dimensions differ and there is no equivalence between them"))
    end
end

# `TimeType` stores integers: accept values that are integers up to rounding errors
function _value(::Type{S}, v, s) where {S <: TimeType}
    I = S isa UnionAll ? Int64 : fieldtype(S, :value)
    r = round(v)
    isapprox(v, r; rtol = 1e-12, atol = 1e-9) ||
        throw(ArgumentError("`TimeType` stores whole numbers, and the value is $v $s: " *
                            "choose a smaller unit with the keyword argument `unit`"))
    return convert(I, r)
end
_value(::Type, v, s) = v

for T in values(MEASUREMENTS)
    T === UnitType && continue
    T === AcidityType && continue
    @eval (::Type{S})(q::AbstractQuantity; kwargs...) where {S <: $T} = _fromquantity(S, q; kwargs...)
end

# pH is a logarithmic scale: a `Gain` of `pH⁺`, not a quantity
const PHGain = Gain{Unitful.LogInfo{:powerofHydrogen, 10, 10}}
function (::Type{S})(x::PHGain; unit = "pH") where {S <: AcidityType}
    unitful_unit(AcidityUnitType, String(unit))      # (checks the unit)
    return S(unit = unit, value = x.val)
end

# counts: plain numbers
function (::Type{S})(x::Real; unit = "1") where {S <: UnitType}
    unitful_unit(UnitUnitType, String(unit))
    return S(unit = unit, value = x)
end

end # module BeerJSONUnitfulExt
