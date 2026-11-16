using Accessors: @set

@testset "Reading and writing the samples" begin
    @test length(SAMPLE_FILES) == 43
    for file in SAMPLE_FILES
        doc = readjson(BeerJSONParser, file)
        @test doc isa RootType
        # written back without changes (as JSON values)
        @test JSON.parse(tojson(doc)) == JSON.parse(read(file, String))
        # and through a file
        out = joinpath(mktempdir(), "copy.json")
        writejson(out, doc)
        @test JSON.parse(read(out, String)) == JSON.parse(read(file, String))
        # all the samples are valid
        @test isvalid(doc)
        @test isempty(violations(doc))
        @test validate(doc) === doc
    end
end

@testset "Full precision" begin
    for file in SAMPLE_FILES
        doc = readjson(BeerJSONParser{BigInt, BigFloat}, file)
        @test doc isa BeerJSONParser{BigInt, BigFloat}
        @test JSON.parse(tojson(doc)) == JSON.parse(read(file, String))
    end
end

@testset "Contents of a recipe" begin
    doc = readjson(RootType, joinpath(SAMPLES, "real", "SourMash.json"))
    recipe = only(doc.beerjson.recipes)
    @test recipe isa RecipeType{Int64, Float64}
    @test recipe.name == "Sour Mash"
    @test recipe.type == RecipeTypeEnum("all grain")
    @test recipe.batch_size == VolumeType(unit = "gal", value = 12)
    @test recipe.batch_size.unit.value == "gal"
    @test !isempty(recipe.ingredients.fermentable_additions)
end

@testset "Changing values" begin
    doc = readjson(RootType, joinpath(SAMPLES, "real", "SourMash.json"))
    recipe = only(doc.beerjson.recipes)
    r2 = setfields(recipe; batch_size = VolumeType(unit = "l", value = 45))
    @test r2.batch_size.value == 45.0 && recipe.batch_size.value == 12.0
    @test setfields(recipe; batch_size = (unit = "l", value = 45)) == r2
    r3 = @set recipe.batch_size.value = 13
    @test r3.batch_size == VolumeType(unit = "gal", value = 13)
    @test isvalid(r3)
end

@testset "Invalid values" begin
    doc = readjson(RootType, joinpath(SAMPLES, "real", "SourMash.json"))
    recipe = only(doc.beerjson.recipes)
    # the constructors only convert...
    v = VolumeType(unit = "litre", value = 20)
    @test !isvalid(v)
    @test only(violations(v)) == "unit: invalid value \"litre\" for `VolumeUnitType`; allowed values are " *
        join(repr.(BeerJSON.BeerJSONTypes._enumvalues(VolumeUnitType)), ", ")
    bad = setfields(recipe; batch_size = v)
    baddoc = @set doc.beerjson.recipes = [bad]
    @test startswith(only(violations(baddoc)), "beerjson.recipes[1].batch_size.unit: invalid value \"litre\"")
    @test_throws SchemaValidationError validate(baddoc)
    # ...and writing validates
    @test_throws SchemaValidationError tojson(baddoc)
    out = joinpath(mktempdir(), "bad.json")
    @test_throws SchemaValidationError writejson(out, baddoc)
    @test !isfile(out)
    @test occursin("litre", tojson(baddoc; validate = false))
    # another constraint of the schema: a mash has at least one step
    mash = recipe.mash
    badmash = @set mash.mash_steps = MashStepType{Int64, Float64}[]
    @test only(violations(badmash)) == "`mash_steps` in `MashProcedureType` must have at least 1 items, got 0"
    @test_throws SchemaValidationError tojson(badmash)
    # the structure is still enforced by the types
    @test_throws UndefKeywordError VolumeType(unit = "l")
    @test_throws SchemaValidationError VolumeType(unit = "l", value = "x")
    @test_throws SchemaValidationError fromjson(VolumeType, """{"unit": "l"}""")
end
