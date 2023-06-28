module Bandsets

using Rasters
using ReadableRegex
using DocStringExtensions
using Pipe: @pipe

import Tables
import RemoteSensingToolbox: align_rasters, efficient_read

"""
The supertype of all BandSet types. 

Subtypes should wrap a RasterStack and implement the following interface:

    unwrap(X::BandSet)

    bands(::Type{<:Bandset})

    wavelengths(::Type{<:Bandset})

    blue(X::BandSet)

    green(X::BandSet)

    red(X::BandSet) 

    nir(X::BandSet) 

    swir1(X::BandSet)

    swir2(X::BandSet)

# Example Implementation
```julia
struct Landsat8{T} <: AbstractBandset{T}
    stack::T
end

unwrap(X::Landsat8) = X.stack

bands(::Type{<:Landsat8}) = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]

wavelengths(::Type{<:Landsat8}) = [443, 483, 560, 660, 865, 1650, 2220]

blue(X::Landsat8) = X[:B2]

green(X::Landsat8) = X[:B3]

red(X::Landsat8) = X[:B4]

nir(X::Landsat8) = X[:B5]

swir1(X::Landsat8) = X[:B6]

swir2(X::Landsat8) = X[:B7]
```
"""
abstract type AbstractBandset{T} end

"""
    unwrap(x::AbstractBandset)

Retrieve the wrapped `RasterStack` from the bandset.
"""
function unwrap(::T) where {T <: AbstractBandset}
    error("Error: `unwrap` not defined for '$(T.name.wrapper)'!")
end

"""
    bands(::Type{AbstractBandset})
    bands(x::AbstractBandset)

Return the band names in order from shortest to longest wavelength.
"""
function bands(::Type{T}) where {T <: AbstractBandset}
    error("Error: `bands` not defined for '$(T.name.wrapper)'!")
end

function bands(x::T) where {T <: AbstractBandset}
    return filter(a -> a in keys(x), bands(T))
end

"""
    wavelengths(::Type{AbstractBandset})
    wavelengths(x::AbstractBandset)

Return the central wavelengths for all bands in order from shortest to longest.
"""
function wavelengths(::Type{T}) where {T <: AbstractBandset}
    error("Error: `wavelengths` not defined for '$(T.name.wrapper)'!")
end

function wavelengths(x::T) where {T <: AbstractBandset}
    return [wavelength(T, b) for b in bands(x)]
end

"""
    wavelength(::Type{AbstractBandset}, band::Symbol)
    wavelength(x::AbstractBandset, band::Symbol)

Return the central wavelength for the corresponding band.
"""
function wavelength(::Type{T}, band::Symbol) where {T <: AbstractBandset}
    !(band in bands(T)) && throw(ArgumentError("$band not found in bands $(bands(T))!"))
    return @pipe findfirst(isequal(band), bands(T)) |> wavelengths(T)[_]
end

function wavelength(x::T, band::Symbol) where {T <: AbstractBandset}
    !(band in keys(unwrap(x))) && throw(ArgumentError("$band not found in bands $(keys(unwrap(x)))!"))
    return wavelength(T, band)
end

function Base.view(x::T, args...) where {T <: AbstractRasterStack}
    x = Base.view(unwrap(x), args...)
    x isa AbstractRasterStack ? T(x) : x
end

Base.getindex(x::AbstractBandset, args...) = Base.getindex(unwrap(x), args...)

Base.keys(x::AbstractBandset, args...) = Base.keys(unwrap(x))


# Tables Interface

Tables.columnaccess(::Type{<:AbstractBandset}) = true

Tables.columns(X::AbstractBandset) = unwrap(X) |> Tables.columns


# Exports

include("utils.jl")
include("landsat8.jl")
include("landsat7.jl")
include("sentinel2.jl")
#include("DESIS.jl")

export AbstractBandset,Landsat8, Landsat7, Sentinel2 # DESIS
export red, green, blue, nir, swir1, swir2, unwrap, wavelength, wavelengths, bands

end