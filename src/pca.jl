"""
Remotely sensed imagery typically consists of anywhere from four to several hundred spectral bands. These bands are often highly correlated due to occupying
similar spectral regions. Principal Component Analysis (PCA) is used in remote sensing to:

1. Create a smaller dataset from multiple bands, while retaining as much of the original spectral information as possible. The new image will consist of several uncorrelated PC bands.

2. Reveal complex relationships among spectral features.

3. Distinguish between characteristics that are prevalent in most bands and those that are specific to only a few.

# Example
```julia-repl
julia> desis = DESIS("DESIS-HSI-L2A-DT0884573241_001-20200601T234520-V0210/");

julia> desis_bands = Raster(desis, :Bands)

julia> pca = fit_pca(desis_bands, stats_fraction=0.1)
PCA(dimensions=235) 

Projection Matrix:
235×235 Matrix{Float32}:
  0.0001  0.0032   0.0016  -0.0094   0.0147  -0.0151  -0.0049   0.0163  …   0.0038  -0.0012   0.0008  -0.0032  -0.0007   0.0053
  0.0005  0.0099   0.0042  -0.0244   0.0517  -0.0335  -0.0185   0.0441     -0.0023  -0.0016  -0.0008   0.001    0.0003  -0.0004
  0.0003  0.015    0.0053  -0.037    0.133   -0.0443  -0.0271   0.1381     -0.0006   0.0004   0.0002  -0.0006   0.0003   0.0002
  0.0003  0.019    0.0071  -0.0385   0.1369  -0.0393  -0.0148   0.0949     -0.0008   0.0006  -0.0001  -0.0006   0.0001  -0.0006
  0.0003  0.0232   0.0073  -0.0419   0.1469  -0.037    0.0041   0.0839     -0.0013  -0.0025   0.0005   0.0007   0.0007  -0.0002
  0.0001  0.0267   0.0077  -0.0461   0.1713  -0.0325   0.0246   0.0861  …   0.0013  -0.0007  -0.0007   0.0024  -0.0012  -0.0028
  0.0001  0.0295   0.0083  -0.0476   0.1695  -0.0348   0.0319   0.0827     -0.0015  -0.0016  -0.0029   0.0004   0.0019  -0.0009
 -0.0001  0.0318   0.0086  -0.0482   0.17    -0.0352   0.0414   0.0784      0.0005  -0.002    0.0003   0.0021  -0.0003  -0.0022
  ⋮                                           ⋮                         ⋱            ⋮                                  
 -0.0663  0.0371  -0.1728   0.0196  -0.0508  -0.1394  -0.0054  -0.0226     -0.0003   0.0001   0.0007  -0.0009  -0.0002   0.0004
 -0.0658  0.0365  -0.1679   0.0204  -0.0717  -0.1474  -0.0087  -0.0193     -0.0006   0.0002   0.0004  -0.0      0.0004  -0.0001
 -0.0655  0.0352  -0.163    0.0193  -0.0767  -0.1511  -0.012   -0.0232     -0.0005   0.0002  -0.0004  -0.0001  -0.0002   0.0005
 -0.066   0.035   -0.1618   0.0193  -0.0859  -0.1503  -0.0055  -0.0177  …   0.0003   0.0005   0.001   -0.0      0.0003  -0.0002
 -0.067   0.035   -0.1619   0.019   -0.0745  -0.1466   0.0245  -0.0228     -0.0001   0.0002  -0.0002  -0.0001  -0.0002   0.0005
 -0.0679  0.0343  -0.1601   0.0176  -0.0721  -0.139    0.0328  -0.0286      0.0003   0.0003   0.0005  -0.0      0.0003   0.0002
 -0.0682  0.0337  -0.1588   0.0151  -0.0458  -0.1242   0.0549  -0.0315      0.0002  -0.0002  -0.0003   0.0002  -0.0003  -0.0005
 -0.0711  0.0343  -0.1601   0.012   -0.0612  -0.1804   0.2151  -0.0971      0.0004  -0.0001   0.0      0.0003   0.0     -0.0003

Importance of Components:
  Cumulative Variance: 0.8782  0.9493  0.9809  0.9869  0.9889  0.9906  0.9915  0.9922  0.9928  ...  1.0
  Explained Variance: 0.8782  0.0711  0.0316  0.006  0.0021  0.0017  0.0009  0.0007  0.0006  ...  0.0

julia> transformed = forward_pca(pca, desis_bands, 12);

julia> size(transformed)
(1131, 1120, 12)

julia> recovered = inverse_pca(pca, transformed);

julia> size(recovered)
(1131, 1120, 235)
```
"""
struct PCA
    mean::Vector{Float32}
    projection::Matrix{Float32}
    cumulative_variance::Vector{Float32}
    explained_variance::Vector{Float32}
end

"""
    projection(x::PCA)

Return the projection matrix for the fitted PCA transformation.
"""
projection(x::PCA) = x.projection

"""
    cumulative_variance(x::PCA)

Return the cumulative variance associated with each principal component of the fitted PCA transform.
"""
cumulative_variance(x::PCA) = x.cumulative_variance

"""
    explained_variance(x::PCA)

Return the explained variance associated with each principal component of the fitted PCA transform.
"""
explained_variance(x::PCA) = x.explained_variance

function Base.show(io::IO, ::MIME"text/plain", x::PCA)
    # Extract Values
    cv = @pipe round.(x.cumulative_variance, digits=4)
    ev = @pipe round.(x.explained_variance, digits=4)
    P = round.(x.projection, digits=4)

    # Split Explained Variance and Cumulative Variance
    cv = length(cv) > 10 ? vcat(cv[1:9], ["..."], cv[end:end]) : cv
    ev = length(ev) > 10 ? vcat(ev[1:9], ["..."], ev[end:end]) : ev

    # Turn EV and SNR Into Strings
    ev = @pipe ev |> string.(_) |> join(_, "  ")
    cv = @pipe cv |> string.(_) |> join(_, "  ")
    
    # Display PCA
    println(io, "PCA(dimensions=$(size(P, 1))) \n")
    println(io, "Projection Matrix:")
    show(io, "text/plain", P)
    println(io, "\n\nImportance of Components:")
    println(io, "  Cumulative Variance: ", cv)
    print(io, "  Explained Variance: ", ev)
end

"""
    fit_pca(raster::Union{<:AbstractRasterStack, <:AbstractRaster}; method=:cov, stats_fraction=1.0)
    fit_pca(signatures::Matrix{Float32}; method=:cov, stats_fraction=1.0)

Fit a Principal Component Analysis (PCA) transformation to the given raster or spectral signatures.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to fit the PCA transformation.
- `signatures`: An nxb matrix of spectral signatures where n is the number of signatures and b is the number of bands.

# Keywords
- `method`: Either `:cov` or `:cor`, depending on whether we want to use the covariance or correlation matrix for computing the PCA rotation.
- `stats_fraction`: The fraction of pixels to use when computing the covariance (or correlation) matrix. Values less than 1.0 will speed up computation at the cost of precision.
"""
function fit_pca(raster::Union{<:AbstractRasterStack, <:AbstractRaster}; method=:cov, stats_fraction=1.0)
    signatures = sample(raster, DataFrame; fraction=stats_fraction) |> Tables.matrix .|> Float32
    return fit_pca(signatures; method=method, stats_fraction=1.0)
end

function fit_pca(signatures::Matrix; kwargs...)
    return fit_pca(Float32.(signatures); kwargs...)
end

function fit_pca(signatures::Matrix{Float32}; method=:cov, stats_fraction=1.0)
    # Check Arguments
    !in(method, (:cov, :cor)) && throw(ArgumentError("`method` must be one of `:cov` or `:cor`!"))
    ((stats_fraction <= 0) || (stats_fraction > 1)) && throw(ArgumentError("`stats_fraction` must in the interval (0, 1]!"))

    # Draw Sample
    n = size(signatures, 1)
    n_samples = round(Int, n * stats_fraction)
    samples = Random.randperm(n)[1:n_samples]
    X = @view signatures[samples,:]

    # Compute Means
    μ = @pipe Statistics.mean(X, dims=1) |> dropdims(_, dims=1)
    
    # Compute Eigenvalues and Eigenvectors of Covariance/Correlation Matrix
    λ, pc = method == :cov ? (X |> Statistics.cov |> _eigen) : (X |> Statistics.cor |> _eigen)
    
    # Cumulative and Explained Variance
    cumulative_var = cumsum(λ) ./ sum(λ)
    explained_var = λ ./ sum(λ)

    # Return Results
    return PCA(Float32.(μ), Float32.(pc), Float32.(cumulative_var), Float32.(explained_var))
end

"""
    forward_pca(transformation::PCA, raster::Union{<:AbstractRaster, <:AbstractRasterStack}, components::Int)
    forward_pca(transformation::PCA, signatures::Matrix, components::Int)

Perform a forward Principal Component Analysis (PCA) rotation while retaining only the specified number of components.

# Parameters
- `transformation`: A previously fitted PCA transformation.
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to perform the PCA transformation.
- `signatures`: An nxb matrix of signatures where n is the number of signatures and b is the number of bands.
- `components`: The number of bands to retain in the transformed image or signatures.
"""
function forward_pca(transformation::PCA, raster::AbstractRasterStack, components::Int)
    return forward_pca(transformation, Raster(raster |> efficient_read), components)
end

function forward_pca(transformation::PCA, raster::AbstractRaster, components::Int)
    # Project To New Axes
    transformed = @pipe raster |>
        replace_missing(_, 0.0f0) |>  # Replace Missing Values with Zero
        reshape(_.data, (:, nbands(raster))) |>  # Reshape Data Into a Matrix
        forward_pca(transformation, _, components) |>  # Project to new Coordinates
        reshape(_, (size(raster, 1), size(raster, 2), components)) |>  # Restore Shape of Raster
        Raster(_, (dims(raster)[1:2]..., Rasters.Band))  # Restore Raster Dimensions
    
    # Mask Missing Values
    bmask = boolmask(@view raster[Rasters.Band(1)])
    return mask!(transformed, with=bmask, missingval=Inf32)
end

function forward_pca(transformation::PCA, signatures::Matrix, components::Int)
    return forward_pca(transformation, Float32.(signatures), components)
end

function forward_pca(transformation::PCA, signatures::Matrix{Float32}, components::Int)
    P = projection(transformation)[:,1:components]
    return (signatures .- reshape(transformation.mean, 1, :)) * P
end

"""
    inverse_pca(transformation::PCA, raster::AbstractRaster)
    inverse_pca(transformation::PCA, signatures::Matrix)

Perform an inverse Principal Component Analysis (PCA) transformation to recover the original image.

# Parameters
- `transformation`: A previously fitted PCA transformation.
- `raster`: An `AbstractRaster` representing a previously transformed image.
- `signatures`: An nxc matrix of previously transformed signatures where n is the number of signatures and c is the number of components.
"""
function inverse_pca(transformation::PCA, raster::AbstractRaster)
    # Check Arguments
    1 <= nbands(raster) <= size(projection(transformation), 1) || throw(ArgumentError("nbands(raster) must be less than or equal to the number of bands in the original image!"))

    # Invert Projection
    P = projection(transformation)
    restored = @pipe raster |>
        replace_missing(_, 0.0f0) |>  # Replace Missing Values with Zero
        reshape(_.data, (:, nbands(raster))) |>  # Reshape Raster Into a Matrix
        inverse_pca(transformation, _) |>  # Reverse Transformation
        reshape(_, (size(raster)[1:2]..., size(P, 1))) |>  # Restore Shape of Raster
        Raster(_, (dims(raster)[1:2]..., Rasters.Band))  # Restore Raster Dimensions

    # Mask Missing Values
    bmask = boolmask(@view raster[Rasters.Band(1)])
    return mask!(restored, with=bmask, missingval=Inf32)
end

function inverse_pca(transformation::PCA, signatures::Matrix)
    return inverse_pca(transformation, Float32.(signatures))
end

function inverse_pca(transformation::PCA, signatures::Matrix{Float32})
    components = size(signatures, 2)
    P = projection(transformation)[:,1:components]
    return (signatures * P') .+ reshape(transformation.mean, 1, :)
end

function _eigen(A)
    eigs, vecs = LinearAlgebra.eigen(A)
    return reverse(eigs), reverse(vecs, dims=2)
end