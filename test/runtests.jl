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

@testset "PCA" begin

    # Load Sentinel
    sentinel = read_bands(Sentinel2, "data/sentinel/")

    # Fit PCA
    pca = fit_transform(PCA, sentinel)

    # Test PCA Fit Results
    @test pca.cumulative_variance[end] ≈ 1.0
    @test all(pca.cumulative_variance .<= 1.0)
    @test sort(pca.cumulative_variance) == pca.cumulative_variance
    @test sum(pca.explained_variance) ≈ 1.0
    @test sort(pca.explained_variance, rev=true) == pca.explained_variance

    # Test PCA Floating Point Transformation
    transformed = transform(pca, sentinel)
    @test size(transformed) == size(tocube(sentinel))
    @test transformed.missingval == Inf32

    # Test PCA Floating Point Inverse Transformation
    recovered = inverse_transform(pca, transformed)
    @test names(sentinel) == names(recovered)
    @test all(isapprox.(tocube(recovered).data, tocube(sentinel).data, atol=0.1))

    # Test PCA Integer Transformation
    transformed_int = transform(pca, sentinel, output_type=Int16)
    @test eltype(transformed_int) == Int16
    @test transformed_int.missingval == 32767

    # Test PCA Integer Inverse Transformation
    recovered_int = inverse_transform(pca, transformed_int)
    @test all(isapprox.(tocube(sentinel).data,  tocube(recovered_int).data, atol=1.5))

end
