"""
A struct for storing the parameters necessary to perform a PCA transformation.
"""
struct PCA <: AbstractTransformation
    cumulative_variance::Vector{Float64}
    explained_variance::Vector{Float64}
    projection::Matrix{Float64}
end

function Base.show(io::IO, ::MIME"text/plain", x::PCA)
    cv = @pipe round.(x.cumulative_variance, digits=4) |> string.(_) |> join(_, "  ")
    ev = @pipe round.(x.explained_variance, digits=4) |> string.(_) |> join(_, "  ")
    projection = round.(x.projection, digits=4)
    println(io, "PCA(in_dim=$(size(projection, 1)), out_dim=$(size(projection, 2)), explained_variance=$(round(x.cumulative_variance[end], digits=4)))\n")
    println(io, "Projection Matrix:")
    show(io, "text/plain", projection)
    println(io, "\n\nImportance of Components:")
    println(io, "  Cumulative Variance: ", cv)
    print(io, "  Explained Variance: ", ev)
end

"""
    fit(transformation::Type{PCA}, raster; components=length(raster), method=:cov, stats_fraction=1.0)

Fit a PCA transformation to the given raster.

# Parameters
- `raster`: The `AbstractRaster`, `AbstractRasterStack` or `AbstractSensor` on which to perform a PCA transformation.
- `components`: The number of principal components to use.
- `method`: One of either `:cov` or `:cor`, depending on whether we want to run PCA on the covariance or the correlation matrix.
- `stats_fraction`: The fraction of pixels to use in the calculation. Setting `stats_fraction < 1` will produce faster but less accurate results. 
"""
function fit(::Type{PCA}, raster::Union{<:AbstractRasterStack, <:AbstractSensor}; components=length(raster), method=:cov, stats_fraction=1.0)
    ((components < 1) || components > length(raster)) && throw(ArgumentError("`components` must be in the interval [1, length(stack)]!"))
    !in(method, (:cov, :cor)) && throw(ArgumentError("`method` must be one of `:cov` or `:cor`!"))
    ((stats_fraction <= 0) || (stats_fraction > 1)) && throw(ArgumentError("`stats_fraction` must in the interval (0, 1]!"))

    # Read Stack Into DataFrame
    df = @pipe raster |> replace_missing |> DataFrame

    # Drop Missing Elements
    dropmissing!(df) 

    # Prepare Data For Statistics
    n = nrow(df)
    n_samples = round(Int, n * stats_fraction)
    samples = Random.randperm(n_samples)[1:n_samples]
    X = @view(df[samples, Not([:X, :Y])]) |> Matrix 
    
    # Compute Eigenvalues and Eigenvectors of Covariance/Correlation Matrix
    eigs, vecs = method == :cov ? (X |> cov |> LinearAlgebra.eigen) : (X |> cor |> LinearAlgebra.eigen)
    
    # Get Principal Components and Weights
    λ = reverse(eigs)
    pc = reverse(vecs, dims=2)
    
    # Return Results
    cumulative_var = cumsum(λ) ./ (cumsum(λ)[end])
    explained_var = λ ./ (cumsum(λ)[end])
    return PCA(cumulative_var[1:components], explained_var[1:components], pc[:,1:components])
end

function fit(::Type{PCA}, raster::AbstractRaster; kwargs...)
    fit(PCA, RasterStack(raster; layersfrom=Rasters.Band); kwargs...)
end

"""
    transform(transformation::PCA, raster)

Perform a PCA transformation to the given raster.

# Parameters
- `transformation`: The fitted `PCA` transformation to apply.
- `raster`: The `AbstractRaster`, `AbstractRasterStack` or `AbstractSensor` on which to perform a PCA transformation.
"""
function transform(transformation::PCA, raster::Union{<:AbstractRasterStack, <:AbstractSensor})
    return @pipe tocube(raster) |> transform(transformation, _)
end

function transform(transformation::PCA, raster::AbstractRaster)
    # Project To New Axes
    data = 
    @pipe reshape(raster.data, (:, size(raster, :Band))) |> 
    (_ * Float32.(transformation.projection)) |> 
    reshape(_, (size(raster.data)[1:2]..., size(transformation.projection, 2)))
    
    # Copy CRS and Dimensions
    transformed_raster = _copy_dims(data, raster)

    # Mask Missing Values
    mask!(transformed_raster; with=@view(raster[Rasters.Band(1)]), missingval=eltype(transformed_raster)(-Inf))
    
    # Set missingval
    transformed_raster = rebuild(transformed_raster, missingval=eltype(transformed_raster)(-Inf))

    # Return as RasterStack
    return RasterStack(transformed_raster, layersfrom=Rasters.Band, name=Symbol.(["PC$i" for i in eachindex(transformation.cumulative_variance)]))
end
