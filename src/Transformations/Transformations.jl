module Transformations

using Rasters
using DataFrames
using DocStringExtensions
using Statistics
using Pipe: @pipe

import Random
import LinearAlgebra
import ..Sensors: AbstractSensor, dn2rs
import RemoteSensingToolbox: _second, _copy_dims, tocube

"""
The supertype of all transformations. Subtypes are expected to implement the `fit` and `transform` methods.
"""
abstract type AbstractTransformation end

"""
    fit(::Type{<:AbstractTransformation}, raster; kwargs...)

Fit a transformation to the given raster.
"""
fit(::Type{T}, raster; kwargs...) where {T <: AbstractTransformation} = error("`fit()` not defined for `$T`!")

"""
    transform(transformation::AbstractTransformation, raster)

Apply a transformation to the given raster.
"""
transform(transformation::T, raster) where {T <: AbstractTransformation} = error("`transform()` not defined for `$T`!")

include("normalize.jl")
include("pca.jl")

export AbstractTransformation, Normalize, PCA, fit, transform

end