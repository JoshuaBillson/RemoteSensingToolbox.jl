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

    # Test Indices
    for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi]
        result = index(landsat)
        @test result isa AbstractArray{Float32}
        @test maximum(result) <= 1.0f0
        @test minimum(result) >= -1.0f0
        @test visualize(result) isa AbstractArray{Gray{N0f8}}
    end
end
