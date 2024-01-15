using Test, Statistics
using RemoteSensingToolbox, Rasters, ArchGDAL
using DataDeps, Fetch, Images
using Pipe: @pipe

# Load Sentinel
sentinel = Sentinel2{20}("data/S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")
stack = RasterStack(sentinel)

# Test Indices
for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
    result = index(sentinel)
    @test result isa AbstractArray{Float32}
    @test (result |> skipmissing |> maximum) <= 1.0f0
    @test (result |> skipmissing |> minimum) >= -1.0f0
    @test visualize(result) isa AbstractArray{Gray{N0f8}}
    @test all(result .== index(Sentinel2{20}, stack))
end