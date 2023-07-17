using RemoteSensingToolbox
using Test
using Images
import ArchGDAL
using Pipe: @pipe

@testset "Landsat" begin

    landsat = read_bands(Landsat8, "data/landsat/")

    # Test Visualization
    for color in [TrueColor, Agriculture, ColorInfrared, Geology, SWIR]
        @test visualize(landsat, color{Landsat8}) isa AbstractArray{RGB{N0f8}}
    end

    # Test DN to Reflectance
    @test @pipe landsat |> dn_to_reflectance(_, Landsat8; clamp_values=true) |> map(minimum ∘ skipmissing, _) |> all([x >= 0.0f0 for x in _])
    @test @pipe landsat |> dn_to_reflectance(_, Landsat8; clamp_values=true) |> map(maximum ∘ skipmissing, _) |> all([x <= 1.0f0 for x in _])

    # Test Indices
    landsat_sr =  dn_to_reflectance(landsat, Landsat8; clamp_values=true)
    for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
        result = index(landsat_sr, Landsat8)
        @test result isa AbstractArray{Float32}
        @test (result |> skipmissing |> maximum) <= 1.0f0
        @test (result |> skipmissing |> minimum) >= -1.0f0
        @test visualize(result) isa AbstractArray{Gray{N0f8}}
    end

end

@testset "Sentinel" begin

    sentinel = read_bands(Sentinel2, "data/sentinel/")

    # Test Visualization
    for color in [TrueColor, Agriculture, ColorInfrared, Geology, SWIR]
        @test visualize(sentinel, color{Sentinel2}) isa AbstractArray{RGB{N0f8}}
    end

    # Test DN to Reflectance
    @test @pipe sentinel |> dn_to_reflectance(_, Sentinel2; clamp_values=true) |> map(minimum ∘ skipmissing, _) |> all([x >= 0.0f0 for x in _])
    @test @pipe sentinel |> dn_to_reflectance(_, Sentinel2; clamp_values=true) |> map(maximum ∘ skipmissing, _) |> all([x <= 1.0f0 for x in _])

    # Test Indices
    sentinel_sr =  dn_to_reflectance(sentinel, Sentinel2; clamp_values=true)
    for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
        result = index(sentinel_sr, Sentinel2)
        @test result isa AbstractArray{Float32}
        @test (result |> skipmissing |> maximum) <= 1.0f0
        @test (result |> skipmissing |> minimum) >= -1.0f0
        @test visualize(result) isa AbstractArray{Gray{N0f8}}
    end

end
