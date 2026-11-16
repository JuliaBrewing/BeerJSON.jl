using Unitful
using UnitfulBrewing
using UnitfulBrewing: SugarGravity, SugarGravityQuad, DensityConcentration, CarbonationDensity

const EXT = Base.get_extension(BeerJSON, :BeerJSONUnitfulExt)
const ENUMVALUES = BeerJSON.BeerJSONTypes._enumvalues

@testset "Unitful extension" begin

@test EXT isa Module

@testset "Every unit enumeration has a table" begin
    units = [getfield(BeerJSON, n) for n in names(BeerJSON)
             if endswith(string(n), "UnitType") && getfield(BeerJSON, n) <: AbstractSchemaEnum]
    @test length(units) == 16
    @test Set(units) == Set(keys(EXT.TABLES)) == Set(keys(EXT.MEASUREMENTS))
    for U in units
        T = EXT.MEASUREMENTS[U]
        @test fieldtype(T{Int64, Float64}, :unit) === U
        table, unsupported = unit_table(U), unsupported_units(U)
        # each value of the enumeration maps, or is listed as unsupported, but not both
        @test Set(ENUMVALUES(U)) == union(keys(table), keys(unsupported))
        @test isempty(intersect(keys(table), keys(unsupported)))
        @test EXT.TABLES[U].default in keys(table)
        for (s, u) in table
            @test unitful_unit(U(s)) === u === unitful_unit(U, s)
        end
        for s in keys(unsupported)
            @test_throws "has no Unitful counterpart" unitful_unit(U(s))
            @test_throws "has no Unitful counterpart" quantity(T(unit = s, value = 1))
        end
        @test_throws "is not a BeerJSON unit" unitful_unit(U, "furlong")
    end
    # every unit of BeerJSON has a Unitful counterpart
    @test all(isempty(unsupported_units(U)) for U in units)
end

@testset "Round trips" begin
    for (U, T) in EXT.MEASUREMENTS, s in keys(unit_table(U)), x in (3, 2.5, 0)
        T === TimeType && !(x isa Integer) && continue
        v = T(unit = s, value = x)
        q = quantity(v)
        if T === UnitType
            @test q === Float64(x)
            @test UnitType(q; unit = s) == v
        else
            @test q == x * unitful_unit(U, s)
            @test T(q) == v                         # in the unit of the quantity
        end
        # through the default unit of the table, and back
        # (`TimeType` stores whole numbers: tested below)
        if T ∉ (UnitType, AcidityType, TimeType)
            w = T(q; unit = EXT.TABLES[U].default)
            back = T(quantity(w); unit = s)
            @test back.unit == v.unit
            @test back.value ≈ v.value atol = 1e-12
        end
    end
    # with other numeric types
    v = VolumeType{BigInt, BigFloat}(5u"gal"; unit = "l")
    @test v isa VolumeType{BigInt, BigFloat}
    @test v.value == big"3.785411784" * 5
    @test TimeType{Int32, Float32}(2u"hr"; unit = "min") === TimeType{Int32, Float32}(unit = "min", value = 120) ||
          TimeType{Int32, Float32}(2u"hr"; unit = "min") == TimeType{Int32, Float32}(unit = "min", value = 120)
end

@testset "Quantities in the unit of the file" begin
    @test quantity(VolumeType(unit = "l", value = 20)) == 20.0u"L"
    @test quantity(TemperatureType(unit = "C", value = 67)) == 67.0u"°C"
    @test quantity(GravityType(unit = "plato", value = 12)) == 12.0u"°P"
    @test quantity(ColorType(unit = "Lovi", value = 3)) == 3.0u"°L"
    @test quantity(TimeType(unit = "min", value = 60)) === 60u"minute"
    @test quantity(PercentType(unit = "%", value = 5)) == 5.0u"percent"
    @test uconvert(NoUnits, quantity(PercentType(unit = "%", value = 5))) == 0.05
    @test quantity(UnitType(unit = "pkg", value = 2)) === 2.0
    @test quantity(AcidityType(unit = "pH", value = 5.2)) == 5.2u"pH⁺"
    doc = readjson(RootType, joinpath(SAMPLES, "real", "SourMash.json"))
    recipe = only(doc.beerjson.recipes)
    @test quantity(recipe.batch_size) == 12.0u"gal"
end

@testset "Default units" begin
    @test VolumeType(5u"gal") == VolumeType(unit = "gal", value = 5)         # the unit of `q`
    @test VolumeType(2u"m^3") == VolumeType(unit = "l", value = 2000)        # the default
    @test MassType(1u"Mg") == MassType(unit = "kg", value = 1000)
    @test TimeType(2u"hr") == TimeType(unit = "hr", value = 2)
    @test TimeType(120_000u"ms") == TimeType(unit = "min", value = 2)
    @test TemperatureType(300u"K").unit == TemperatureUnitType("C")
    @test GravityType(40u"gu") == GravityType(unit = "sg", value = 1.04)
    @test ConcentrationType(10u"mg/L") == ConcentrationType(unit = "mg/l", value = 10)
    @test ConcentrationType(1u"percent") == ConcentrationType(unit = "ppm", value = 10_000)
    @test PercentType(0.5u"permille").value ≈ 0.05
    @test UnitType(3) == UnitType(unit = "1", value = 3)
    @test AcidityType(5.4u"pH⁺") == AcidityType(unit = "pH", value = 5.4)
end

@testset "Conversions" begin
    conv(T, q, s) = T(q; unit = s).value
    # volume and mass
    @test conv(VolumeType, 5u"gal", "l") ≈ 18.92705892
    @test conv(VolumeType, 1u"cup", "ml") ≈ 236.5882365
    @test conv(VolumeType, 1u"tbsp", "tsp") ≈ 3
    @test conv(VolumeType, 1u"floz", "ml") ≈ 29.5735295625
    @test conv(VolumeType, 1u"qt", "pt") ≈ 2
    @test conv(VolumeType, 1u"bbl", "gal") ≈ 31                    # the US beer barrel
    @test conv(VolumeType, 1u"bbl", "l") ≈ 117.347765304
    @test conv(VolumeType, 1u"ifloz", "ml") ≈ 28.4130625
    @test conv(VolumeType, 1u"igal", "l") ≈ 4.54609
    @test conv(VolumeType, 1u"ipt", "ifloz") ≈ 20
    @test conv(VolumeType, 1u"iqt", "ipt") ≈ 2
    @test conv(VolumeType, 1u"ibbl", "igal") ≈ 36
    @test conv(VolumeType, 1u"ibbl", "l") ≈ 163.65924
    @test conv(MassType, 1u"lb", "g") ≈ 453.59237
    @test conv(MassType, 1u"lb", "oz") ≈ 16
    # time
    @test conv(TimeType, 1u"wk", "day") == 7
    @test conv(TimeType, 2u"d", "hr") == 48
    @test_throws "whole numbers" TimeType(90u"s"; unit = "min")
    # temperatures are affine
    @test conv(TemperatureType, 100u"°C", "F") ≈ 212
    @test conv(TemperatureType, 67u"°C", "F") ≈ 152.6
    @test conv(TemperatureType, 32u"°F", "C") ≈ 0 atol = 1e-12
    @test conv(TemperatureType, 0u"K", "C") ≈ -273.15
    @test conv(TemperatureType, 0u"K", "F") ≈ -459.67
    @test TemperatureType(quantity(TemperatureType(unit = "F", value = 152.6)); unit = "C").value ≈ 67
    # gravity: specific gravity and degrees Plato are related by an equivalence
    @test conv(GravityType, 1.040u"sg", "plato") ≈ 10 rtol = 0.005
    @test conv(GravityType, 1.040u"sg", "plato") ≈ 259 * (1 - 1 / 1.040)
    @test conv(GravityType, 1.040u"sg", "plato") ≈ ustrip(u"°P", uconvert(u"°P", 1.040u"sg", SugarGravity()))
    @test conv(GravityType, 10u"°P", "sg") ≈ 259 / 249
    @test conv(GravityType, 40u"gu", "plato") ≈ 259 * (1 - 1 / 1.040)
    @test GravityType(1.040u"sg"; unit = "plato", equivalence = SugarGravityQuad()).value ≈ 9.99224
    @test GravityType(GravityType(1.040u"sg"; unit = "plato") |> quantity; unit = "sg").value ≈ 1.040
    @test conv(GravityType, 12u"Brix", "plato") ≈ 12                     # (as in UnitfulBrewing)
    @test_throws ArgumentError GravityType(1.040u"sg"; unit = "plato", equivalence = nothing)
    # a dimensionless quantity other than sg or gu is not a gravity
    @test_throws "dimensionless units accepted" GravityType(5u"percent")
    @test_throws MethodError GravityType(1.04)                      # (plain numbers)
    # color: EBC is linear in SRM, and Lovibond affine
    @test conv(ColorType, 10u"SRM", "EBC") ≈ 19.7
    @test conv(ColorType, 10u"°L", "SRM") ≈ 1.3546 * 10 - 0.76
    @test conv(ColorType, 10u"SRM", "Lovi") ≈ (10 + 0.76) / 1.3546
    # diastatic power: Windisch-Kolbach is affine in Lintner
    @test conv(DiastaticPowerType, 100u"°Lintner", "WK") ≈ 3.5 * 100 - 16
    @test conv(DiastaticPowerType, 334u"°WK", "Lintner") ≈ 100
    # concentration: ppm and mg/l by an equivalence
    @test conv(ConcentrationType, 10u"mg/L", "ppm") ≈ 10
    @test conv(ConcentrationType, 2u"ppm", "mg/l") ≈ 2
    @test conv(ConcentrationType, 1u"ppm", "ppb") ≈ 1000
    @test_throws ArgumentError ConcentrationType(1u"g"; unit = "ppm")
    # others
    @test conv(CarbonationType, 5u"g/L", "g/l") ≈ 5
    # carbonation: volumes of CO₂ and g/l by an equivalence
    @test conv(CarbonationType, 2.5u"vols", "g/l") ≈ 2.5 * 1.977
    @test conv(CarbonationType, 4.9425u"g/L", "vols") ≈ 2.5
    @test conv(CarbonationType, 2.5u"vols", "g/l") ≈ ustrip(u"g/L", uconvert(u"g/L", 2.5u"vols", CarbonationDensity()))
    @test CarbonationType(2.5u"vols") == CarbonationType(unit = "vols", value = 2.5)
    @test_throws ArgumentError CarbonationType(2.5u"vols"; unit = "g/l", equivalence = nothing)
    @test conv(BitternessType, 40u"IBU", "IBUs") == 40
    @test conv(SpecificHeatType, 1u"cal/(g*K)", "J/(kg K)") ≈ 4184
    @test conv(SpecificHeatType, 1u"btu/(lb*Ra)", "J/(kg K)") ≈ 4186.8 rtol = 1e-5
    @test conv(SpecificVolumeType, 1u"L/kg", "qt/lb") ≈ 0.45359237 / 0.946352946
    @test conv(SpecificVolumeType, 1u"m^3/kg", "l/g") ≈ 1
    @test conv(ViscosityType, 2u"cP", "mPa-s") ≈ 2
    @test conv(PercentType, 25u"percent", "%") == 25
    @test_throws MethodError PercentType(0.25)                      # (plain numbers)
    # mismatched dimensions
    @test_throws "dimensions differ" VolumeType(1u"kg")
    @test_throws "dimensions differ" TemperatureType(1u"m")
    @test_throws "is not a BeerJSON unit" VolumeType(1u"L"; unit = "litre")
end

@testset "Error hint without the extension functions" begin
    msg = sprint(showerror, MethodError(quantity, (1,)))
    @test occursin("UnitfulBrewing", msg)
end

end
