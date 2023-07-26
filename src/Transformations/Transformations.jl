module Transformations

using Rasters
using DataFrames
using DocStringExtensions
using Statistics
using Pipe: @pipe

import Random
import LinearAlgebra
import RemoteSensingToolbox: _copy_dims, tocube, _map_index, _raster_to_df, _copy_dims, nbands

"""
The supertype of all transformations. Subtypes are expected to implement the `fit` and `transform` methods.
"""
abstract type AbstractTransformation end

"""
    fit_transform(::Type{<:AbstractTransformation}, raster; kwargs...)

Fit a transformation to the given raster.
"""
fit_transform(::Type{T}, raster; kwargs...) where {T <: AbstractTransformation} = error("`fit_transform()` not defined for `$T`!")

"""
    transform(transformation::AbstractTransformation, raster)

Apply a transformation to the given raster.
"""
transform(transformation::T, raster; kwargs...) where {T <: AbstractTransformation} = error("`transform()` not defined for `$T`!")

"""
    inverse_transform(transformation::AbstractTransformation, raster)

Undo a previously applied transformation.
"""
inverse_transform(transformation::T, raster, kwargs...) where {T <: AbstractTransformation} = error("`inverse_transform()` not defined for `$T`!")

include("utils.jl")
include("normalize.jl")
include("pca.jl")

export AbstractTransformation, Normalize, PCA, fit_transform, transform, inverse_transform

end