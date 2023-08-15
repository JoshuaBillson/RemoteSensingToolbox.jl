"""
Remotely sensed imagery typically consists of anywhere from a few to several hundred spectral bands. These bands are often highly correlated due to occupying
 similar spectral regions. Principal Component Analysis (PCA) is used in remote sensing to:

1. Create a smaller dataset from multiple bands, while retaining as much of the original spectral information as possible. The new image will consist of several uncorrelated PC bands.

2. Reveal complex relationships among spectral features.

3. Determine which characteristics are prevalent in most of the bands, and those that are specific to only a few.
"""
struct PCA
    mean::Vector{Float32}
    projection::Matrix{Float32}
    cumulative_variance::Vector{Float32}
    explained_variance::Vector{Float32}
    bands::Vector{Symbol}
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
    fit_pca(raster; method=:cov, stats_fraction=1.0)

Fit a Principal Component Analysis (PCA) transformation to the given `AbstractRasterStack` or `AbstractRaster`.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to fit the PCA transformation.
- `method`: Either `:cov` or `:cor`, depending on whether we want to use the covariance or correlation matrix for computing the PCA rotation.
- `stats_fraction`: The fraction of pixels to use when computing the covariance (or correlation) matrix. Values less than 1.0 will speed up computation at the cost of precision.
"""
function fit_pca(raster::Union{<:AbstractRasterStack, <:AbstractRaster}; method=:cov, stats_fraction=1.0)
    # Check Arguments
    !in(method, (:cov, :cor)) && throw(ArgumentError("`method` must be one of `:cov` or `:cor`!"))
    ((stats_fraction <= 0) || (stats_fraction > 1)) && throw(ArgumentError("`stats_fraction` must in the interval (0, 1]!"))

    # Prepare Data For Statistics
    data = RasterTable(raster) |> dropmissing |> Tables.matrix .|> Float64

    # Fit PCA
    bands = raster isa AbstractRasterStack ? collect(names(raster)) : Symbol[]
    return _fit_pca(data, method, stats_fraction, bands)
end

"""
    forward_pca(transformation::PCA, raster, components::Int)

Perform a forward Principal Component Analysis (PCA) transformation on the given raster, retaining only the specified number of components.

# Parameters
- `transformation`: A previously fitted PCA transformation.
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to perform the PCA transformation.
- `components`: The number of bands to retain in the transformed image. All band numbers exceeding this value will be discarded.
"""
function forward_pca(transformation::PCA, raster::AbstractRasterStack, components::Int)
    return transform(transformation, tocube(raster), components)
end

function transform(transformation::PCA, raster::AbstractRaster, components::Int)
    # Get Projection
    P = projection(transformation)[:,1:components]

    # Project To New Axes
    output_dims = (size(raster, 1), size(raster, 2), components)
    transformed = @pipe _centralize(raster, transformation.mean).data |> reshape(_, (:, size(raster, Rasters.Band))) |> (_ * P) |> reshape(_, output_dims) |> _copy_dims(_, raster)
    
    # Mask Missing Values
    t = eltype(transformed)
    return @pipe mask!(transformed; with=(@view raster[Rasters.Band(1)]), missingval=typemax(t)) |> rebuild(_, missingval=typemax(t))
end

"""
    inverse_pca(transformation::PCA, raster::AbstractRaster)

Perform an inverse Principal Component Analysis (PCA) transformation to recover the original image.

# Parameters
- `transformation`: A previously fitted PCA transformation.
- `raster`: An `AbstractRaster` representing a previously transformed image. The number of bands should be less than or equal to that of the original image.
"""
function inverse_pca(transformation::PCA, raster::AbstractRaster)
    # Check Arguments
    1 <= nbands(raster) <= size(projection(transformation), 1) || throw(ArgumentError("nbands(raster) must be less than or equal to the number of bands in the original image!"))

    # Get Projection
    components = nbands(raster)
    P = projection(transformation)[:,1:components]

    # Invert Projection
    restored = @pipe reshape(raster.data, (:, size(raster, Rasters.Band))) |> (_ * P') |> reshape(_, (size(raster.data)[1:2]..., size(P, 1)))

    # De-Centralize
    restored .+= reshape(transformation.mean, (1, 1, :))

    # Write Results Into a Raster
    restored_raster = _copy_dims(restored, raster)

    # Mask Missing Values
    t = eltype(restored_raster)
    restored_raster = rebuild(restored_raster, missingval=typemax(t))
    mask!(restored_raster, with=(@view raster[Rasters.Band(1)]))

    # Recover Band Names
    if isempty(transformation.bands)
        return restored_raster
    else
        rasters = [restored_raster[Rasters.Band(i)] for i in eachindex(transformation.bands)]
        return RasterStack(rasters..., name=transformation.bands)
    end
end

function _fit_pca(data::Matrix, method, stats_fraction, bands)
    # Draw Sample
    n = size(data, 1)
    n_samples = round(Int, n * stats_fraction)
    samples = Random.randperm(n)[1:n_samples]
    X = @view data[samples,:]

    # Compute Means
    μ = @pipe mean(data, dims=1) |> dropdims(_, dims=1)
    
    # Compute Eigenvalues and Eigenvectors of Covariance/Correlation Matrix
    eigs, vecs = method == :cov ? (X |> cov |> LinearAlgebra.eigen) : (X |> cor |> LinearAlgebra.eigen)
    
    # Get Principal Components and Weights
    λ = reverse(eigs)
    pc = reverse(vecs, dims=2)
    
    # Cumulative and Explained Variance
    cumulative_var = cumsum(λ) ./ (cumsum(λ)[end])
    explained_var = λ ./ (cumsum(λ)[end])

    # Return Results
    return PCA(Float32.(μ), Float32.(pc), Float32.(cumulative_var), Float32.(explained_var), bands)
end