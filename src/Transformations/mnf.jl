"""
The Minimum Noise Fraction (MNF) transform is a linear transformation used to reduce the spectral dimensionality of image data and 
segregate noise.  MNF consists of two separate principal components analysis rotations. The first rotation uses the principal components 
of the noise covariance matrix to decorrelate and rescale the noise (a process known as noise whitening), resulting in a transformed 
image in which the noise has unit variance and no band-to-band correlations. The second rotation is a standard PCA rotation 
applied to the noise-whitened image.

The bands in the transformed image will be ordered according to their Signal to Noise Ratio (SNR), with the highest SNR being 
placed first. The result is that the noise becomes concentrated in the higher bands. Thus, the transform can be used to separate 
noise from data by performing a forward transform, determining which bands contain coherent images, and running an inverse 
transform after discarding the remaining bands. The number of bands to keep in the inverse transform can be determined by a number 
of methods. The simplest approach is to look at the sorted transformed bands, and threshold at the band where no recognizable 
features can be observed. It can also be chosen by thresholding at a desired cumulative SNR.
"""
struct MNF
    noise_cov::Matrix{Float32}
    data_cov::Matrix{Float32}
    projection::Matrix{Float32}
    eigenvalues::Vector{Float32}
end

"""
    noise_cov(x::MNF)

Return the noise covariance matrix for the fitted MNF transform.
"""
noise_cov(x::MNF) = x.noise_cov

"""
    data_cov(x::MNF)

Return the data covariance matrix for the fitted MNF transform.
"""
data_cov(x::MNF) = x.data_cov

"""
    projection(x::MNF)

Return the projection matrix for the fitted MNF transform.
"""
projection(x::MNF) = x.projection

"""
    eigenvalues(x::MNF)

Return the eigenvalues associated with each principal components of the fitted MNF transform.
"""
eigenvalues(x::MNF) = x.eigenvalues

"""
    cumulative_eigenvalues(x::MNF)

Return the cumulative eigenvalues associated with each principal components of the fitted MNF transform.
"""
function cumulative_eigenvalues(x::MNF)
    s = eigenvalues(x) |> cumsum
    return s ./ maximum(s)
end

"""
    accounted_snr(x::MNF)

Return the estimated SNR associated with each principal components of the fitted MNF transform.
"""
function accounted_snr(x::MNF)
    P = projection(x)
    ([P[:,i]' * (x.data_cov * P[i,:]) for i in 1:235] ./ [P[:,i]' * (x.noise_cov * P[i,:]) for i in 1:235]) .- 1
end

"""
    cumulative_snr(x::MNF)

Return the cumulative SNR associated with each principal components of the fitted MNF transform.
"""
function cumulative_snr(x::MNF)
    s = accounted_snr(x) |> cumsum
    return s ./ maximum(s)
end

function Base.show(io::IO, ::MIME"text/plain", x::MNF)
    # Extract Projection, Eigenvalues, and SNR
    P = round.(projection(x), digits=4)
    ev = round.(eigenvalues(x), digits=4)
    snr = round.(accounted_snr(x), digits=4)
    snr_cum = round.(cumulative_snr(x), digits=4)
    ev_cum = round.(cumulative_eigenvalues(x), digits=4)

    # Split EV and SNR
    ev = length(ev) > 10 ? vcat(ev[1:9], ["..."], ev[end:end]) : ev
    snr = length(snr) > 10 ? vcat(snr[1:9], ["..."], snr[end:end]) : snr
    snr_cum = length(snr_cum) > 10 ? vcat(snr_cum[1:9], ["..."], snr_cum[end:end]) : snr_cum
    ev_cum = length(ev_cum) > 10 ? vcat(ev_cum[1:9], ["..."], ev_cum[end:end]) : ev_cum

    # Turn EV and SNR Into Strings
    ev = @pipe ev |> string.(_) |> join(_, "  ")
    snr = @pipe snr |> string.(_) |> join(_, "  ")
    snr_cum = @pipe snr_cum |> string.(_) |> join(_, "  ")
    ev_cum = @pipe ev_cum |> string.(_) |> join(_, "  ")

    # Display MNF
    println(io, "MNF(dimensions=$(size(P, 1))) \n")
    println(io, "Projection Matrix:")
    show(io, "text/plain", P)
    println(io, "\n\nComponent Statistics:")
    println(io, "  Eigenvalues: ", ev)
    println(io, "  Cumulative Eigenvalues: ", ev_cum)
    println(io, "  Explained SNR: ", snr)
    print(io, "  Cumulative SNR: ", snr_cum)
end

"""
    fit_mnf(raster; noise_sample=raster, smooth=true)

Fit a Minimum Noise Fraction (MNF) transformation to the given `AbstractRasterStack` or `AbstractRaster`.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to fit the MNF transformation.
- `noise_sample`: A homogenous (spectrally uniform) region extracted from `raster` for calculating the noise covariance matrix.
- `smooth`: The MNF transform cannot be computed if any band in `noise_sample` has zero variance. To correct this, you may wish to introduce a small smoothing term (false by default).
"""
function fit_mnf(raster::Union{<:AbstractRasterStack, <:AbstractRaster};  noise_sample=raster, smooth=true)
    # Check Arguments
    ((noise_sample isa AbstractRasterStack) || (noise_sample isa AbstractRaster)) || throw(ArgumentError("`noise_sample` must be a Raster!"))

    # Fit MNF
    bands = raster isa AbstractRasterStack ? collect(names(raster)) : Symbol[]
    return _fit_mnf(raster, noise_sample, bands, smooth)
end

"""
    forward_mnf(transformation::MNF, raster, components::Int)

Perform a forward Minimum Noise Fraction (MNF) rotation on the given raster, retaining only the specified number of components.

# Parameters
- `transformation`: A previously fitted MNF transformation.
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to perform the MNF transformation.
- `components`: The number of bands to retain in the transformed image. All band numbers exceeding this value will be discarded.
"""
function forward_mnf(transformation::MNF, raster::AbstractRasterStack, components::Int)
    return forward_mnf(transformation, tocube(raster), components)
end

function forward_mnf(transformation::MNF, raster::AbstractRaster, components::Int)
    # Project To New Axes
    P = projection(transformation)[:,1:components]
    output_dims = (size(raster, 1), size(raster, 2), components)
    transformed = @pipe Float32.(raster.data) |> reshape(_, (:, size(raster, Rasters.Band))) |> (_ * P) |> reshape(_, output_dims) |> _copy_dims(_, raster)

    # Mask Missing Values
    t = eltype(transformed)
    return @pipe mask!(transformed; with=(@view raster[Rasters.Band(1)]), missingval=typemax(t)) |> rebuild(_, missingval=typemax(t))
end

"""
    inverse_mnf(transformation::MNF, raster::AbstractRaster)

Perform an inverse Minimum Noise Fraction (MNF) transformation to recover the original image.

# Parameters
- `transformation`: A previously fitted MNF transformation.
- `raster`: An `AbstractRaster` representing a previously transformed image. The number of bands should be less than or equal to that of the original image.
"""
function inverse_mnf(transformation::MNF, raster::AbstractRaster)
    # Check Arguments
    1 <= nbands(raster) <= size(projection(transformation), 1) || throw(ArgumentError("nbands(raster) must be less than or equal to the number of bands in the original image!"))

    # Prepare Inverse Projection
    components = nbands(raster)
    P = projection(transformation)
    D = LinearAlgebra.inv(P)[1:components,:]

    # Invert Transformation
    restored = @pipe reshape(raster.data, (:, size(raster, Rasters.Band))) |> (_ * D) |> reshape(_, (size(raster.data)[1:2]..., size(P, 1)))

    # Write Results Into a Raster
    restored_raster = _copy_dims(restored, raster)

    # Mask Missing Values
    t = eltype(restored_raster)
    restored_raster = rebuild(restored_raster, missingval=typemax(t))
    mask!(restored_raster, with=(@view raster[Rasters.Band(1)]))

    # Restore Band Names
    return restored_raster
end

function _compute_diff(raster::AbstractRaster; smooth=false)
    # Extract (0, 1) Offset Views
    height = size(raster, Rasters.Y)
    r1 = @view raster[Rasters.Y(1:height-1)]
    r2 = @view raster[Rasters.Y(2:height)]

    # Prepare Smoothing Term
    t = eltype(raster)
    s = size(r1)
    smoothing = smooth ? (t <: Integer ? rand(t.([0, 1]), s) : rand(t.([0.0, 0.0001]), s)) : zeros(t, s)

    # Compute Diff
    diff = r1 .- r2
    diff .+= smoothing
    return diff
end

function _compute_diff(raster::AbstractRasterStack; smooth=false)
    return map(x -> _compute_diff(x, smooth=smooth), raster)
end

function _compute_ncm(raster::Union{<:AbstractRasterStack, <:AbstractRaster}; smooth=false)
    # Compute Covariance Of Noise
    Σ = _compute_diff(raster, smooth=smooth) |> RasterTable |> Tables.matrix .|> Float64 |> cov
    Σ .*= 0.5

    # Check If Any Variances Are Zero
    @assert all([Σ[i,i] for i in axes(Σ)[1]] .!= 0) "Zero variance encountered in noise estimate! Set smooth=true to fix this error."

    # Return NCM
    return Σ
end

function _fit_mnf(raster, noise_sample, bands, smooth)
    # Compute NCM
    Σₙ = _compute_ncm(noise_sample; smooth=smooth)

    # Compute Renormalization Matrix To Whiten Noise
    λ, E = _eigen(Σₙ)
    F = E * (LinearAlgebra.Diagonal(λ .^ -0.5))

    # Extract Data
    data = RasterTable(raster) |> dropmissing |> Tables.matrix .|> Float64

    # Compute Data Covariance
    Σ = cov(data)

    # Normalize Data Covariance
    Σ_normalized = F' * Σ * F
    
    # Compute Eigenvalues and Eigenvectors of Covariance/Correlation Matrix
    λ_data, G = _eigen(Σ_normalized)

    # Get Projection Matrix
    H = F * G

    # Return MNF Transform
    return MNF(Float32.(Σₙ), Σ, Float32.(H), Float32.(λ_data))
end