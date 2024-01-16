using Test, Statistics, Random
using RemoteSensingToolbox, Rasters
using Pipe: @pipe

Random.seed!(123)

# Load Sentinel
src = Sentinel2{20}("data/S2B_MSIL2A_20200804T183919_N0214_R070_T11UPT_20200804T230343")
sentinel = RasterStack(src; lazy=false)

# Fit PCA
pca = fit_pca(sentinel)

# Test PCA Fit Results
@test cumulative_variance(pca)[end] ≈ 1.0
@test all(cumulative_variance(pca) .<= 1.0)
@test sort(cumulative_variance(pca)) == cumulative_variance(pca)
@test sum(explained_variance(pca)) ≈ 1.0
@test sort(explained_variance(pca), rev=true) == explained_variance(pca)

# Test Forward Transformation With Three Components
transformed = forward_pca(pca, sentinel, 3)
@test size(transformed) == (size(sentinel)..., 3)

# Test Forward Transformation
transformed = forward_pca(pca, sentinel, length(sentinel))
@test size(transformed) == size(Raster(sentinel))

# Test Inverse Transformation
recovered = inverse_pca(pca, transformed)
@test all(isapprox.(Raster(recovered).data, Raster(sentinel).data, atol=0.1))