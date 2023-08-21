using RemoteSensingToolbox, Test, Images, ArchGDAL
using Pipe: @pipe

landsat = read_bands(Landsat8, "data/landsat/")

# Test Visualization
for color in [TrueColor, Agriculture, ColorInfrared, Geology, SWIR]
    @test visualize(landsat, color{Landsat8}) isa AbstractArray{RGB{N0f8}}
end

# Test DN to Reflectance
@test @pipe landsat |> dn_to_reflectance(Landsat8, _; clamp_values=true) |> map(minimum ∘ skipmissing, _) |> all([x >= 0.0f0 for x in _])
@test @pipe landsat |> dn_to_reflectance(Landsat8, _; clamp_values=true) |> map(maximum ∘ skipmissing, _) |> all([x <= 1.0f0 for x in _])

# Test Indices
landsat_sr =  @pipe dn_to_reflectance(Landsat8, landsat; clamp_values=true) |> encode(_, Float64)
for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
    result = index(landsat_sr, Landsat8)
    @test result isa AbstractArray{Float32}
    @test (result |> skipmissing |> maximum) <= 1.0f0
    @test (result |> skipmissing |> minimum) >= -1.0f0
    @test visualize(result) isa AbstractArray{Gray{N0f8}}
end