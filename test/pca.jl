using RemoteSensingToolbox, Test, ArchGDAL
using Pipe: @pipe

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

# Test Forward Transformation With Three Components
transformed = forward_pca(pca, sentinel, 3)
@test size(transformed) == (size(sentinel)..., 3)

# Test Forward Transformation
transformed = forward_pca(pca, sentinel, length(sentinel))
@test size(transformed) == size(Raster(sentinel))

# Test Inverse Transformation
recovered = inverse_pca(pca, transformed)
@test names(sentinel) == names(recovered)
@test all(isapprox.(Raster(recovered).data, Raster(sentinel).data, atol=0.1))