using RemoteSensingToolbox
using Test
using Images
using Shapefile
import ArchGDAL
import Tables
using Pipe: @pipe

@testset "Landsat" begin

    landsat = read_bands(Landsat8, "data/landsat/")

    # Test Visualization
    for color in [TrueColor, Agriculture, ColorInfrared, Geology, SWIR]
        @test visualize(landsat, color{Landsat8}) isa AbstractArray{RGB{N0f8}}
    end

    # Test DN to Reflectance
    @test @pipe landsat |> dn_to_reflectance(Landsat8, _; clamp_values=true) |> map(minimum ∘ skipmissing, _) |> all([x >= 0.0f0 for x in _])
    @test @pipe landsat |> dn_to_reflectance(Landsat8, _; clamp_values=true) |> map(maximum ∘ skipmissing, _) |> all([x <= 1.0f0 for x in _])

    # Test Indices
    landsat_sr =  dn_to_reflectance(Landsat8, landsat; clamp_values=true)
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
    @test @pipe sentinel |> dn_to_reflectance(Sentinel2, _; clamp_values=true) |> map(minimum ∘ skipmissing, _) |> all([x >= 0.0f0 for x in _])
    @test @pipe sentinel |> dn_to_reflectance(Sentinel2, _; clamp_values=true) |> map(maximum ∘ skipmissing, _) |> all([x <= 1.0f0 for x in _])

    # Test Indices
    sentinel_sr =  dn_to_reflectance(Sentinel2, sentinel; clamp_values=true)
    for index in [mndwi, ndwi, ndvi, ndmi, nbri, ndbi, savi]
        result = index(sentinel_sr, Sentinel2)
        @test result isa AbstractArray{Float32}
        @test (result |> skipmissing |> maximum) <= 1.0f0
        @test (result |> skipmissing |> minimum) >= -1.0f0
        @test visualize(result) isa AbstractArray{Gray{N0f8}}
    end

end

@testset "PCA" begin

    # Load Sentinel
    sentinel = read_bands(Sentinel2, "data/sentinel/")

    # Fit PCA
    pca = fit_pca(sentinel)

    # Test PCA Fit Results
    @test cumulative_variance(pca)[end] ≈ 1.0
    @test all(cumulative_variance(pca) .<= 1.0)
    @test sort(cumulative_variance(pca)) == cumulative_variance(pca)
    @test sum(explained_variance(pca)) ≈ 1.0
    @test sort(explained_variance(pca), rev=true) == explained_variance(pca)

    # Test PCA Floating Point Transformation
    transformed = forward_pca(pca, sentinel, length(sentinel))
    @test size(transformed) == size(tocube(sentinel))
    @test transformed.missingval == Inf32

    # Test PCA Floating Point Inverse Transformation
    recovered = inverse_pca(pca, transformed)
    @test names(sentinel) == names(recovered)
    @test all(isapprox.(tocube(recovered).data, tocube(sentinel).data, atol=0.1))
end

@testset "makie" begin

    # Load Sentinel
    sentinel = @pipe read_bands(Sentinel2, "data/sentinel/") |> dn_to_reflectance(Sentinel2, _)

    # Read Shapefile
    shp = Shapefile.Table("data/landcover/landcover.shp") |> Tables.columntable

    # Should Throw Error Telling Us To Load CairoMakie
    @test_throws ErrorException plot_signatures(Sentinel2, sentinel, shp, :MC_name)

    using CairoMakie

    # Should Run Now That CairoMakie is Loaded
    fig = plot_signatures(Sentinel2, sentinel, shp, :MC_name)
end
