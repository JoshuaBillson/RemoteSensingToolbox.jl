using RemoteSensingToolbox
using Test
using Images
using Pipe: @pipe

@testset "Landsat" begin

    landsat = Landsat8("data/landsat/"; ext="tif")

    # Test Visualization
    for color in [TrueColor, Agriculture, ColorInfrared, Geology, SWIR]
        @test visualize(landsat, color) isa AbstractArray{RGB{N0f8}}
    end

    # Test DN to Reflectance
    @test @pipe landsat |> dn_to_reflectance |> skipmissing(_.stack) |> minimum |> all([x >= 0.001f0 for x in _])
    @test @pipe landsat |> dn_to_reflectance |> skipmissing(_.stack) |> maximum |> all([x <= 0.999f0 for x in _])

    # Test Indices
    landsat_sr = landsat |> dn_to_reflectance
    for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
        result = index(landsat_sr)
        @test result isa AbstractArray{Float32}
        @test maximum(result) <= 1.0f0
        @test minimum(result) >= -1.0f0
        @test visualize(result) isa AbstractArray{Gray{N0f8}}
    end

end

@testset "Sentinel" begin

    sentinel = Sentinel2A("data/sentinel/")

    # Test Visualization
    for color in [TrueColor, Agriculture, ColorInfrared, Geology, SWIR]
        @test visualize(sentinel, color) isa AbstractArray{RGB{N0f8}}
    end

    # Test DN to Reflectance
    @test @pipe sentinel |> dn_to_reflectance |> skipmissing(_.stack) |> minimum |> all([x >= 0.001f0 for x in _])
    @test @pipe sentinel |> dn_to_reflectance |> skipmissing(_.stack) |> maximum |> all([x <= 0.999f0 for x in _])

    # Test Indices
    sentinel_sr = sentinel |> dn_to_reflectance
    for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
        result = index(sentinel_sr)
        @test result isa AbstractArray{Float32}
        @test result |> skipmissing |> maximum <= 1.0f0
        @test result |> skipmissing |> minimum >= -1.0f0
        @test visualize(result) isa AbstractArray{Gray{N0f8}}
    end

end
