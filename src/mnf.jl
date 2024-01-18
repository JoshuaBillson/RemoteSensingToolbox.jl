"""
The Minimum Noise Fraction (MNF) transform is a linear transformation used to reduce the spectral dimensionality of image data and 
segregate noise. MNF consists of two separate principal component rotations. The first rotation uses the principal components 
of the noise covariance matrix to decorrelate and rescale the noise (a process known as noise whitening), resulting in a transformed 
image in which the noise has unit variance and no band-to-band correlations. The second rotation is a standard PCA rotation 
applied to the noise-whitened image.

The bands in the transformed image will be ordered according to their Signal to Noise Ratio (SNR), with the highest SNR being 
placed first. The result is that the noise becomes concentrated in the higher bands. Thus, the transform can be used to separate 
noise from data by performing a forward transform, determining which bands contain coherent images, and running an inverse 
transform after either discarding or denoising the remaining bands. The number of bands to keep in the inverse transform can be determined by a number 
of methods. The simplest approach is to look at the sorted transformed bands and threshold at the band where no recognizable 
features can be observed. An alternative method is to threshold at a desired cumulative SNR.

# Example
```julia-repl
julia> src = DESIS("data/DESIS-HSI-L2A-DT0485529167_001-20220712T223540-V0220")

julia> desis = decode(DESIS, Raster(src, :Bands))

julia> roi = @view desis[X(1019:1040), Y(550:590)];

julia> mnf = fit_mnf(desis, roi)
MNF(dimensions=235) 

Projection Matrix:
235×235 Matrix{Float32}:
 -2.135    2.3502   0.3612   0.5912   0.5217  -0.0917   0.0043  …   0.0002  -0.0001  -0.0004  -0.0004  -0.0      0.0004
 -0.0959   0.0422  -0.0047  -0.2362  -0.3962  -0.2313  -0.1685      0.0001   0.0004   0.0002   0.0003   0.0001  -0.0001
  0.0043   0.0058  -0.0032   0.0023  -0.0061  -0.0048   0.0028     -0.0001   0.0001  -0.0001  -0.0      0.0      0.0001
  0.0039   0.002   -0.002    0.0012  -0.0032  -0.004    0.006      -0.0006   0.0002  -0.0001  -0.0     -0.0003  -0.0
  0.0024   0.0018  -0.003   -0.0008   0.0038  -0.0003   0.0057      0.0009  -0.0007   0.0002  -0.0012   0.0012  -0.0
  0.0019  -0.003    0.0038  -0.002   -0.0001  -0.0003  -0.0     …   0.0021   0.0009  -0.0004   0.0014  -0.0011  -0.0006
  0.0047   0.0055   0.006   -0.0014  -0.0011   0.0021   0.0053     -0.0035   0.0006   0.0002  -0.0026   0.0014   0.0019
  0.0072   0.0042   0.0012   0.0016   0.0011  -0.002   -0.001       0.0     -0.0026   0.0012   0.0034  -0.0006  -0.0009
  ⋮                                            ⋮                ⋱            ⋮                                  
 -0.0004  -0.0012   0.0007   0.0006  -0.0      0.0002   0.0005      0.0005   0.0002  -0.0004  -0.0002  -0.0001   0.0001
 -0.0014  -0.0005  -0.0005   0.0019  -0.0002  -0.0005   0.0017      0.0003   0.0005   0.0      0.0004   0.0005   0.0
 -0.0004   0.0008  -0.0003   0.0013   0.0004   0.0014   0.0004      0.0002  -0.0001   0.0002   0.0001  -0.0002  -0.0002
 -0.0008  -0.0015   0.0021  -0.0004  -0.0004   0.0012   0.0006  …  -0.0011   0.0002  -0.0007   0.0001   0.0005  -0.0001
  0.0008  -0.0004   0.0009   0.0019  -0.0022  -0.0014   0.0013      0.0003  -0.0001  -0.0003  -0.0      0.0003   0.0002
  0.0005   0.0006  -0.0022  -0.0003   0.0     -0.0022   0.0016     -0.001    0.0002  -0.0003   0.0003  -0.0005   0.0005
  0.001   -0.0005  -0.0007   0.0025  -0.0019   0.0005   0.0015      0.0002  -0.0005   0.0     -0.0005   0.0002  -0.0002
 -0.0003   0.0002  -0.0021  -0.0008  -0.0012   0.0003   0.0003     -0.0001  -0.0      0.0001   0.0      0.0      0.0

Component Statistics:
  Eigenvalues: 7975.439  4040.6348  2092.866  717.8178  468.5496  247.5029  202.2003  176.8452  87.3302  ...  0.3602
  Cumulative Eigenvalues: 0.4779  0.72  0.8454  0.8884  0.9165  0.9313  0.9434  0.954  0.9593  ...  1.0
  Explained SNR: 7974.4385  4039.6353  2091.8635  716.8176  467.55  246.5022  201.1985  175.845  86.3301  ...  -0.6399
  Cumulative SNR: 0.4839  0.729  0.856  0.8995  0.9278  0.9428  0.955  0.9657  0.9709  ...  0.9985

julia> transformed = forward_mnf(mnf, desis, 12);

julia> size(transformed)
(1131, 1120, 12)

julia> recovered = inverse_mnf(mnf, transformed);

julia> size(recovered)
(1131, 1120, 235)
```
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
    snr(x::MNF)

Return the estimated SNR associated with each principal components of the fitted MNF transform.
"""
function snr(x::MNF)
    P = projection(x)
    n = size(P, 1)
    ([P[:,i]' * (x.data_cov * P[i,:]) for i in 1:n] ./ [P[:,i]' * (x.noise_cov * P[i,:]) for i in 1:n]) .- 1
end

"""
    cumulative_snr(x::MNF)

Return the cumulative SNR associated with each principal components of the fitted MNF transform.
"""
function cumulative_snr(x::MNF)
    s = snr(x) |> cumsum
    return s ./ maximum(s)
end

function Base.show(io::IO, ::MIME"text/plain", x::MNF)
    # Extract Projection, Eigenvalues, and SNR
    P = round.(projection(x), digits=4)
    ev = round.(eigenvalues(x), digits=4)
    snr_ = round.(snr(x), digits=4)
    snr_cum = round.(cumulative_snr(x), digits=4)
    ev_cum = round.(cumulative_eigenvalues(x), digits=4)

    # Split EV and SNR
    ev = length(ev) > 10 ? vcat(ev[1:9], ["..."], ev[end:end]) : ev
    snr_ = length(snr_) > 10 ? vcat(snr_[1:9], ["..."], snr_[end:end]) : snr_
    snr_cum = length(snr_cum) > 10 ? vcat(snr_cum[1:9], ["..."], snr_cum[end:end]) : snr_cum
    ev_cum = length(ev_cum) > 10 ? vcat(ev_cum[1:9], ["..."], ev_cum[end:end]) : ev_cum

    # Turn EV and SNR Into Strings
    ev = @pipe ev |> string.(_) |> join(_, "  ")
    snr_ = @pipe snr_ |> string.(_) |> join(_, "  ")
    snr_cum = @pipe snr_cum |> string.(_) |> join(_, "  ")
    ev_cum = @pipe ev_cum |> string.(_) |> join(_, "  ")

    # Display MNF
    println(io, "MNF(dimensions=$(size(P, 1))) \n")
    println(io, "Projection Matrix:")
    show(io, "text/plain", P)
    println(io, "\n\nComponent Statistics:")
    println(io, "  Eigenvalues: ", ev)
    println(io, "  Cumulative Eigenvalues: ", ev_cum)
    println(io, "  Explained SNR: ", snr_)
    print(io, "  Cumulative SNR: ", snr_cum)
end

"""
    fit_mnf(raster::Union{<:AbstractRasterStack, <:AbstractRaster}, noise_covariance::Matrix; stats_fraction=1.0)
    fit_mnf(signatures::Matrix, noise_covariance::Matrix; stats_fraction=1.0)

Fit a Minimum Noise Fraction (MNF) transformation to the given `AbstractRasterStack` or `AbstractRaster`.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to fit the MNF transformation.
- `signatures`: An n x b matrix of spectral signatures where n is the number of signatures and b is the number of bands.
- `noise_sample`: A homogenous (spectrally uniform) region extracted from `raster` for calculating the noise covariance matrix.
- `smooth`: The MNF transform cannot be computed if any band in `noise_sample` has zero variance. To correct this, you may wish to introduce a small smoothing term (true by default).
"""
function fit_mnf(raster::RasterOrStack, noise_covariance::Matrix; stats_fraction=1.0)
    signatures = sample(raster; fraction=stats_fraction) |> Tables.matrix .|> Float32
    return fit_mnf(signatures, noise_covariance; stats_fraction=1.0)
end

function fit_mnf(signatures::Matrix, noise_covariance::Matrix; kwargs...)
    return fit_mnf(Float32.(signatures), Float32.(noise_covariance); kwargs...)
end

function fit_mnf(signatures::Matrix{Float32}, noise_covariance::Matrix{Float32}; stats_fraction=1.0)
    # Draw Sample
    n = size(signatures, 1)
    n_samples = round(Int, n * stats_fraction)
    samples = Random.randperm(n)[1:n_samples]
    X = @view signatures[samples,:]

    # Compute Renormalization Matrix To Whiten Noise
    λ, E = _eigen(noise_covariance)
    F = E * (LinearAlgebra.Diagonal(λ .^ -0.5))

    # Compute Data Covariance
    Σ = Statistics.cov(X)

    # Normalize Data Covariance
    Σ_normalized = F' * Σ * F
    
    # Compute Eigenvalues and Eigenvectors of Covariance/Correlation Matrix
    λ, G = _eigen(Σ_normalized)

    # Get Projection Matrix
    H = F * G

    # Return MNF Transform
    return MNF(Float32.(noise_covariance), Float32.(Σ), Float32.(H), Float32.(λ))
end

"""
    forward_mnf(transformation::MNF, raster, components::Int)
    forward_mnf(transformation::MNF, signatures::Matrix, components::Int)

Perform a forward Minimum Noise Fraction (MNF) rotation on the given raster or signatures, retaining only the specified number of components.

# Parameters
- `transformation`: A previously fitted MNF transformation.
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to perform the MNF transformation.
- `signatures`: An n x b matrix of spectral signatures where n is the number of signatures and b is the number of bands.
- `components`: The number of bands to retain in the transformed image. All band numbers exceeding this value will be discarded.
"""
function forward_mnf(transformation::MNF, raster::AbstractRasterStack, components::Int)
    return forward_mnf(transformation, Raster(raster), components)
end

function forward_mnf(transformation::MNF, raster::AbstractRaster, components::Int)
    # Project To New Axes
    transformed = @pipe raster |>
        Rasters.replace_missing(_, 0) |>  # Replace Missing Values with Zero
        reshape(_.data, (:, nbands(raster))) |>  # Reshape Data Into a Matrix
        forward_mnf(transformation, _, components) |>  # Project to new Coordinates
        reshape(_, (size(raster, 1), size(raster, 2), components)) |>  # Restore Shape of Raster
        Rasters.Raster(_, (Rasters.dims(raster)[1:2]..., Rasters.Band))  # Restore Raster Dimensions
    
    # Mask Missing Values
    bmask = Rasters.boolmask(@view raster[Rasters.Band(1)])
    return mask!(transformed, with=bmask, missingval=Inf32)
end

function forward_mnf(transformation::MNF, signatures::Matrix, components::Int)
    return forward_mnf(transformation, Float32.(signatures), components)
end

function forward_mnf(transformation::MNF, signatures::Matrix{Float32}, components::Int)
    return signatures * projection(transformation)[:,1:components]
end

"""
    inverse_mnf(transformation::MNF, raster::AbstractRaster)
    inverse_mnf(transformation::MNF, signatures::Matrix)

Perform an inverse Minimum Noise Fraction (MNF) transformation to recover the original image or signatures.

# Parameters
- `transformation`: A previously fitted MNF transformation.
- `raster`: An `AbstractRaster` representing a previously transformed image. The number of bands should be less than or equal to that of the original image.
- `signatures`: An n x p matrix of transformed signatures where n is the number of signatures and p is the number of retained components.
"""
function inverse_mnf(transformation::MNF, raster::AbstractRaster)
    # Check Arguments
    1 <= nbands(raster) <= size(projection(transformation), 1) || throw(ArgumentError("nbands(raster) must be less than or equal to the number of bands in the original image!"))

    # Invert Projection
    P = projection(transformation)
    restored = @pipe raster |>
        replace_missing(_, 0) |>  # Replace Missing Values with Zero
        reshape(_.data, (:, nbands(raster))) |>  # Reshape Raster Into a Matrix
        inverse_mnf(transformation, _) |>  # Reverse Transformation
        reshape(_, (size(raster)[1:2]..., size(P, 1))) |>  # Restore Shape of Raster
        Raster(_, (dims(raster)[1:2]..., Rasters.Band))  # Restore Raster Dimensions

    # Mask Missing Values
    bmask = boolmask(@view raster[Rasters.Band(1)])
    return mask!(restored, with=bmask, missingval=Inf32)
end

function inverse_mnf(transformation::MNF, signatures::Matrix)
    return inverse_mnf(transformation, Float32.(signatures))
end

function inverse_mnf(transformation::MNF, signatures::Matrix{Float32})
    # Prepare Inverse Projection
    components = size(signatures, 2)
    P = projection(transformation)
    D = LinearAlgebra.inv(P)[1:components,:]

    # Run Inverse Transformation
    return signatures * D
end

"""
    estimate_noise(raster::Union{<:AbstractRaster, <:AbstractRasterStack}; smooth=false)

Estimate the noise covariance matrix for the given raster.

Uses the Minimum/Maximum Autocorrelation Factor proposed by [Switzer and Green](https://www.researchgate.net/publication/239665649_MinMax_Autocorrelation_factors_for_multivariate_spatial_imagery_Technical_Report_6).

For best results, the provided raster should be spectrally homoegenous (e.g., an open field or body of water).

# Parameters
- `raster`: An `AbstractRaster` or `AbstractRasterStack`.
- `smooth`: Numerical stability requires that no bands have a variance of zero. A smoothing term can be applied to ensure that this is the case.

# Example
```julia
using RemoteSensingToolbox, Rasters

# Load Data
src = DESIS("DESIS-HSI-L2A-DT0485529167_001-20220712T223540-V0220")
desis = decode(DESIS, Raster(src, :Bands))

# Extract Homogenous Region of Interest
roi = desis[X(1019:1040), Y(550:590)]

# Estimate Noise
ncm = estimate_noise(roi, smooth=true)
```
"""
function estimate_noise(raster::RasterOrStack; smooth=false)
    residuals = _compute_residuals(raster, smooth)
    return _compute_ncm(residuals)
end

function _compute_residuals(raster::AbstractRasterStack, smooth::Bool)
    return _compute_residuals(Rasters.Raster(efficient_read(raster)), smooth)
end

function _compute_residuals(raster::AbstractRaster, smooth::Bool)
    return @pipe raster |> Float32.(_) |> Rasters.replace_missing!(_, Inf32) |> _compute_residuals(_, smooth)
end

function _compute_residuals(raster::AbstractRaster{Float32}, smooth::Bool)
    # Extract (0, 1) Offset Views
    height = size(raster, Rasters.Y)
    r1 = @view raster[Rasters.Y(1:height-1)]
    r2 = @view raster[Rasters.Y(2:height)]

    # Prepare Smoothing Term
    s = size(r1)
    smoothing = smooth ? rand([0.0f0, 0.0001f0], s) : zeros(Float32, s)

    # Compute Diff
    diff = r1 .- r2
    diff .+= smoothing

    # Mask Missing
    m = Rasters.boolmask(r1) .&& Rasters.boolmask(r2)
    Rasters.mask!(diff, with=m)

    # Return Residuals
    return table(diff, DataFrame)[!,Not(:geometry)] |> dropmissing! |> Tables.matrix
end

function _compute_ncm(residuals::Matrix)
    return _compute_ncm(Float32.(residuals))
end

function _compute_ncm(residuals::Matrix{Float32})
    # Compute Covariance Of Noise
    Σ = Statistics.cov(residuals)
    Σ .*= 0.5

    # Check If Any Variances Are Zero
    @assert all(LinearAlgebra.diag(Σ) .!= 0) "Zero variance encountered in noise estimate! Set smooth=true to fix this error."

    # Return NCM
    return Σ
end
