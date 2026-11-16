plain(x; limit = true) = sprint((io, x) -> show(io, MIME"text/plain"(), x), x; context = :limit => limit)

@testset "Display" begin
    # the two-argument `show` is unchanged: a constructor call, which evaluates back
    v = VolumeType(unit = "l", value = 20)
    @test repr(v) == "VolumeType(VolumeUnitType(\"l\"), 20.0)"
    @test eval(Meta.parse(repr(v))) == v
    @test repr([v]) == "VolumeType{Int64, Float64}[VolumeType(VolumeUnitType(\"l\"), 20.0)]"

    # measurements print as their value and unit
    @test string(v) == "20.0 l"
    @test "$(TimeType(unit = "min", value = 60))" == "60 min"
    @test string(GravityType(unit = "sg", value = 1.0401606425702812)) == "1.0401606425702812 sg"
    @test plain(v) == "VolumeType: 20.0 l"
    @test plain(GravityType(unit = "sg", value = 1.0401606425702812)) == "GravityType: 1.04016 sg"
    @test plain(VolumeType{BigInt, BigFloat}(unit = "l", value = 2)) == "VolumeType{BigInt, BigFloat}: 2.0 l"

    # ranges on one line
    og = GravityRangeType(minimum = (unit = "sg", value = 1.044), maximum = (unit = "sg", value = 1.050))
    @test plain(og) == "GravityRangeType: 1.044 – 1.05 sg"
    mixed = TemperatureRangeType(minimum = (unit = "C", value = 18), maximum = (unit = "F", value = 68))
    @test plain(mixed) == "TemperatureRangeType: 18.0 C – 68.0 F"

    # records as trees, without the absent fields
    hop = HopAdditionType(name = "Cascade", alpha_acid = (unit = "%", value = 5.5),
        timing = (time = (unit = "min", value = 60), use = "add_to_boil"),
        amount = (unit = "g", value = 28))
    @test plain(hop) == """
        HopAdditionType "Cascade"
        ├─ alpha_acid: 5.5 %
        ├─ timing:
        │  ├─ time: 60 min
        │  └─ use: add_to_boil
        └─ amount: 28.0 g"""

    doc = readjson(RootType, joinpath(SAMPLES, "converted", "Kolsh.json"))
    recipe = only(doc.beerjson.recipes)
    out = plain(recipe)
    @test startswith(out, "RecipeType \"Lloyd&#39;s Krispy Kolsch\"\n├─ type: all grain\n")
    @test occursin("├─ batch_size: 19.0029 l\n", out)
    @test occursin("│  ├─ fermentable_additions (3 items)\n│  │  ├─ [1] Pilsner (2 Row) Ger\n", out)
    @test occursin("│     └─ [3] Sparge\n", out)
    @test occursin("_extra (not in the schema):\n", out)
    # long notes are shortened, but not when the output isn't limited
    @test occursin("├─ notes: Brew in a bag method where the full boil volume is mashed wi…\n", out)
    @test occursin(recipe.mash.notes, plain(recipe; limit = false))

    # long lists are shortened when the output is limited
    punk = only(readjson(RootType, joinpath(SAMPLES, "converted", "punk-ipa-2010-current.json")).beerjson.recipes)
    n = length(punk.ingredients.hop_additions)
    @test n > 6
    out = plain(punk)
    @test occursin("hop_additions ($n items)", out)
    @test occursin("[5] ", out) && !occursin("[6] ", out)
    @test occursin("└─ $(n - 5) more\n", out)
    @test occursin("[$n] ", plain(punk; limit = false))

    # vectors of records as trees, below the usual summary line
    @test startswith(plain(recipe.ingredients.hop_additions), """
        2-element Vector{HopAdditionType{Int64, Float64}}:
        ├─ [1] Hallertauer
        │  ├─ origin: Germany
        """)
    @test endswith(plain(recipe.mash.mash_steps), """
        └─ [3] Sparge
           ├─ type: sparge
           ├─ step_temperature: 75.6 C
           └─ step_time: 15 min""")
    @test plain(HopAdditionType{Int64, Float64}[]) == "0-element Vector{HopAdditionType{Int64, Float64}}"
    @test plain([v]) == "1-element Vector{VolumeType{Int64, Float64}}:\n└─ [1]: 20.0 l"
    @test occursin("└─ $(n - 5) more", plain(punk.ingredients.hop_additions))
    @test repr([v]) == "VolumeType{Int64, Float64}[VolumeType(VolumeUnitType(\"l\"), 20.0)]"
    # other vectors are shown as usual
    @test plain([1, 2]) == sprint(show, MIME"text/plain"(), [1, 2])

    # every sample can be displayed
    for file in SAMPLE_FILES
        doc = readjson(RootType, file)
        @test startswith(plain(doc), "BeerJSONParser\n└─ beerjson:\n")
        @test length(plain(doc; limit = false)) >= length(plain(doc))
    end
end
