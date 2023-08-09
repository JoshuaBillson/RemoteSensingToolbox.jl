module Transformations

using Rasters
using DocStringExtensions
using Statistics
using Pipe: @pipe

import Tables
import Random
import LinearAlgebra
import RemoteSensingToolbox: _copy_dims, tocube, _map_index, _copy_dims, nbands, RasterTable, dropmissing

"""
The supertype of all transformations. Subtypes are expected to implement the `fit` and `transform` methods.
"""
abstract type AbstractTransformation end

"""
    fit_transform(transformation::Type{AbstractTransformation}, raster; kwargs...)
    fit_transform(transformation::Type{Normalize}, raster)
    fit_transform(transformation::Type{PCA}, raster; components=nbands(raster), method=:cov, stats_fraction=1.0)

Fit the specified transformation to the given `AbstractRasterStack` or `AbstractRaster`.

# Parameters
- `transformation`: The transformation we want to fit.
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to fit the specified transformation.

# Supported Transformations
- `Normalize`: Scales and shifts the data so that each band has a mean of 0 and a standard deviation of 1.
- `PCA`: Rotates each pixel into a new orthogonal color-space, which may have fewer dimensions than the original.

# PCA Parameters
- `components`: The number of principal components to use.
- `method`: One of either `:cov` or `:cor`, depending on whether we want to run PCA on the covariance or the correlation matrix.
- `stats_fraction`: The fraction of pixels to use in the calculation. Setting `stats_fraction < 1` will produce faster but less accurate results. 
"""
fit_transform(::Type{T}, raster; kwargs...) where {T <: AbstractTransformation} = error("`fit_transform()` not defined for `$T`!")

"""
    transform(transformation::AbstractTransformation, raster; kwargs...)
    transform(transformation::Normalize, raster)
    transform(transformation::PCA, raster; output_type=Float32)

Performs the fitted transformation to the provided `AbstractRaster` or `AbstractRasterStack`.

# Parameters
- `transformation`: The transformation we want to apply.
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to perform the given transformation.

# Supported Transformations
- `Normalize`: Scales and shifts the data so that each band has a mean of 0 and a standard deviation of 1.
- `PCA`: Rotates each pixel into a new orthogonal color-space, which may have fewer dimensions than the original.

# Normalize Parameters
- `output_type`: The element type for the transformed raster. Rounds to the nearest integer if an `Integer` type is given.

# PCA Parameters
- `output_type`: The element type for the transformed raster. Rounds to the nearest integer if an `Integer` type is given.
"""
transform(transformation::T, raster; kwargs...) where {T <: AbstractTransformation} = error("`transform()` not defined for `$T`!")

"""
    inverse_transform(transformation::AbstractTransformation, raster)
    inverse_transform(transformation::Normalize, raster; output_type=Float32)
    inverse_transform(transformation::PCA, raster; output_type=Float32)

Undo a previously applied transformation.

# Parameters
- `transformation`: Some previously applied transformation that we want to reverse.
- `raster`: A previously transformed `AbstractRaster` or `AbstractRasterStack` from which we want to recover the original.

# Supported Transformations
- `Normalize`: Scales and shifts the data so that each band has a mean of 0 and a standard deviation of 1.
- `PCA`: Rotates each pixel into a new orthogonal color-space, which may have fewer dimensions than the original.

# Normalize Parameters
- `output_type`: The element type for the restored raster. Rounds to the nearest integer if an `Integer` type is given.

# PCA Parameters
- `output_type`: The element type for the restored raster. Rounds to the nearest integer if an `Integer` type is given.
"""
inverse_transform(transformation::T, raster, kwargs...) where {T <: AbstractTransformation} = error("`inverse_transform()` not defined for `$T`!")

include("utils.jl")
include("normalize.jl")
include("pca.jl")
include("mnf.jl")

export AbstractTransformation, Normalize, PCA, fit_transform, transform, inverse_transform

end