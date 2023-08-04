"""
A struct for storing the parameters necessary to perform a MNF transformation.
"""
struct MNF <: AbstractTransformation
    components::Int
    mean::Vector{Float64}
    projection::Matrix{Float64}
    cumulative_variance::Vector{Float64}
    explained_variance::Vector{Float64}
    bands::Vector{Symbol}
end

function Base.show(io::IO, ::MIME"text/plain", x::MNF)
    cv = @pipe round.(x.cumulative_variance[1:x.components], digits=4) |> string.(_) |> join(_, "  ")
    ev = @pipe round.(x.explained_variance[1:x.components], digits=4) |> string.(_) |> join(_, "  ")
    projection = round.(x.projection[:,1:x.components], digits=4)
    println(io, "MNF(in_dim=$(size(projection, 1)), out_dim=$(size(projection, 2)), explained_variance=$(round(x.cumulative_variance[x.components], digits=4)))\n")
    println(io, "Projection Matrix:")
    show(io, "text/plain", projection)
    println(io, "\n\nImportance of Components:")
    println(io, "  Cumulative Variance: ", cv)
    print(io, "  Explained Variance: ", ev)
end

function _compute_ncm(img)
    return  @pipe (@view img[1:end-1, 1:end-1, :]) .- (@view img[2:end,2:end,:]) |> reshape(_, (:, 235)) |> cov
end

function fit_transform(::Type{MNF}, raster::Union{<:AbstractRasterStack, <:AbstractRaster}; components=nbands(raster), method=:cov, stats_fraction=1.0)
    # Check Arguments
    ((components < 1) || components > length(raster)) && throw(ArgumentError("`components` must be in the interval [1, length(stack)]!"))
    !in(method, (:cov, :cor)) && throw(ArgumentError("`method` must be one of `:cov` or `:cor`!"))
    ((stats_fraction <= 0) || (stats_fraction > 1)) && throw(ArgumentError("`stats_fraction` must in the interval (0, 1]!"))

    # Prepare Data For Statistics
    data = _raster_to_df(raster) |> dropmissing! |> Matrix

    # Fit MNF
    bands = raster isa AbstractRasterStack ? collect(names(raster)) : Symbol[]
    return _fit(MNF, data, components, method, stats_fraction, bands)
end

function _fit(::Type{MNF}, data::Matrix, components, method, stats_fraction, bands)
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
    return MNF(components, μ, pc, cumulative_var, explained_var, bands)
end

function transform(transformation::MNF, raster::AbstractRasterStack; output_type=Float32)
    return transform(transformation, tocube(raster); output_type=output_type)
end

function transform(transformation::MNF, raster::AbstractRaster; output_type=Int16)
    # Project To New Axes
    transformed = modify(_centralize(raster, transformation.mean)) do data
        @pipe reshape(data, (:, size(raster, Rasters.Band))) |> (_ * Float32.(transformation.projection)) |> reshape(_, size(data))
    end

    # Mask Missing Values
    transformed = @pipe mask!(transformed; with=raster, missingval=typemax(output_type)) |> rebuild(_, missingval=typemax(output_type))
    
    # Extract Components
    if output_type <: Integer
        return @pipe (@view transformed[Rasters.Band(1:transformation.components)]) |> round.(output_type, _)
    end
    return transformed[Rasters.Band(1:transformation.components)]
end

function inverse_transform(transformation::MNF, raster::AbstractRaster; output_type=Float32)
    # Get Projection
    P = transformation.projection[:,1:transformation.components]

    # Invert Projection
    restored = @pipe reshape(raster.data, (:, size(raster, Rasters.Band))) |> (_ * Float32.(P')) |> reshape(_, (size(raster.data)[1:2]..., size(P, 1)))

    # De-Centralize
    restored .+= Float32.(reshape(transformation.mean, (1, 1, :)))

    # Write Results Into a Raster
    restored_raster = if output_type <: Integer
        _copy_dims(round.(output_type, restored), raster)
    else
        @pipe (eltype(restored) != output_type ? output_type.(restored) : restored) |> _copy_dims(_, raster)
    end

    # Mask Missing Values
    restored_raster = rebuild(restored_raster, missingval=typemax(output_type))
    for i in 1:size(raster, Rasters.Band)
        mask!(restored_raster, with=view(raster, Rasters.Band(i)))
    end

    if isempty(transformation.bands)
        return restored_raster
    else
        rasters = [restored_raster[Rasters.Band(i)] for i in eachindex(transformation.bands)]
        return RasterStack(rasters..., name=transformation.bands)
    end

    return restored_raster
end
