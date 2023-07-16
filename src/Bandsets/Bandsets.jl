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
abstract type AbstractBandset end

include("utils.jl")
include("interface.jl")

"""
    wavelength(::Type{AbstractBandset}, band::Symbol)

Return the central wavelength for the corresponding band.
"""
function wavelength(::Type{T}, band::Symbol) where {T <: AbstractBandset}
    !(band in bands(T)) && throw(ArgumentError("$band not found in bands $(bands(T))!"))
    return @pipe findfirst(isequal(band), bands(T)) |> wavelengths(T)[_]
end

function read_bands(::Type{T}, dir::String) where {T <: AbstractBandset}
    # Parse Bands From Files
    files = readdir(dir, join=true)
    parsed_bands = parse_band.(T, files)
    filtered = filter(x -> !isnothing(x[2]), zip(files, parsed_bands) |> collect)

    # Construct RasterStack
    if isempty(filtered)
        error("Error: No valid files could be parsed from the provided directory!")
    elseif first(filtered)[2] isa AbstractVector
        filename = first(filtered)[1]
        layers = first(filtered)[2]
        raster = Raster(filename) |> _ensure_missing
        return RasterStack([raster[Rasters.Band(i)] for i in eachindex(layers)]..., name=layers)
    else
        rasters = @pipe first.(filtered) |> Raster.(_) |> align_rasters(_...) |> _ensure_missing.(_)
        return RasterStack(rasters..., name=map(x -> x[2], filtered))
    end
end

for op = (:blue, :green, :red, :nir, :swir1, :swir2)
    @eval $op(raster::Rasters.AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset} = raster[$op(T)]
end

include("landsat8.jl")
include("landsat7.jl")
include("sentinel2.jl")
include("DESIS.jl")

export AbstractBandset, Landsat8, Landsat7, Sentinel2, DESIS
export red, green, blue, nir, swir1, swir2, bands,wavelengths, wavelength, read_bands, read_qa, dn_to_reflectance

end