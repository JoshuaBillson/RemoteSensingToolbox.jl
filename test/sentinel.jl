using RemoteSensingToolbox, Test, Images, ArchGDAL
using Pipe: @pipe

sentinel = read_bands(Sentinel2, "data/sentinel/")

# Test Visualization
for color in [TrueColor, Agriculture, ColorInfrared, Geology, SWIR]
    @test visualize(sentinel, color{Sentinel2}) isa AbstractArray{RGB{N0f8}}
end

# Test DN to Reflectance
@test @pipe sentinel |> dn_to_reflectance(Sentinel2, _; clamp_values=true) |> map(minimum ∘ skipmissing, _) |> all([x >= 0.0f0 for x in _])
@test @pipe sentinel |> dn_to_reflectance(Sentinel2, _; clamp_values=true) |> map(maximum ∘ skipmissing, _) |> all([x <= 1.0f0 for x in _])

# Test Indices
sentinel_sr = @pipe dn_to_reflectance(Sentinel2, sentinel; clamp_values=true) |> encode(_, Float64)
for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
    result = index(sentinel_sr, Sentinel2)
    @test result isa AbstractArray{Float32}
    @test (result |> skipmissing |> maximum) <= 1.0f0
    @test (result |> skipmissing |> minimum) >= -1.0f0
    @test visualize(result) isa AbstractArray{Gray{N0f8}}
end