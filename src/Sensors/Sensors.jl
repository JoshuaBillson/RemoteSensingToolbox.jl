module Sensors

using Rasters
using DocStringExtensions
using Pipe: @pipe

import Statistics
import RSToolbox: align_rasters, efficient_read

"""
The supertype of all sensor types. 

Subtypes should wrap a RasterStack under the field 'stack' and implement the following interface:

    blue(X::Sensor)

    green(X::Sensor)

    red(X::Sensor) 

    nir(X::Sensor) 

    swir1(X::Sensor)

    swir2(X::Sensor)

    dn2rs(::Type{<:AbstractSensor})

    BandSet(::Type{Landsat8})

# Example Implementation
```julia
struct Landsat8 <: AbstractSensor
    stack::RasterStack
end

function BandSet(::Type{Landsat8})
    bands = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]
    wavelengths = [440, 480, 560, 655, 865, 1610, 2200]
    return BandSet(bands, wavelengths)
end
    
blue(X::Landsat8) = X[:B2]

green(X::Landsat8) = X[:B3]

red(X::Landsat8) = X[:B4]

nir(X::Landsat8) = X[:B5]

swir1(X::Landsat8) = X[:B6]

swir2(X::Landsat8) = X[:B7]

dn2rs(::Type{Landsat8}) = (scale=0.0000275, offset=-0.2)
```
"""
abstract type AbstractSensor end

"""
A struct for storing the band names and associated wavelengths of a particular sensor.

It is expected that instances of `AbstractSensor` implement a `BandSet` constructor.

The central wavelength for a given band can be recovered by calling the `BandSet`.

# Example
```julia-repl
julia> bandset = BandSet(Sentinel2A);
julia> bandset(:B8A)
842.0
```
"""
struct BandSet
    bands::Vector{Symbol}
    wavelengths::Vector{Float64}
end

function BandSet(::Type{T}) where {T <: AbstractSensor}
    error("Error: BandSet not defined for '$T'!")
end

function (bandset::BandSet)(band::Symbol)
    return @pipe zip(bandset.bands, bandset.wavelengths) |> Dict |> _[band]
end

function (bandset::BandSet)(band::String)
    return bandset(Symbol(band))
end

"""
    blue(X::AbstractSensor)

Return the blue band for the given sensor.
"""
blue(X::AbstractSensor) = error("Error: Band 'blue' not defined for $(typeof(X))!")

"""
    green(X::AbstractSensor)

Return the green band for the given sensor.
"""
green(X::AbstractSensor) = error("Error: Band 'green' not defined for $(typeof(X))!")

"""
    red(X::AbstractSensor)

Return the red band for the given sensor.
"""
red(X::AbstractSensor) = error("Error: Band 'red' not defined for $(typeof(X))!")

"""
    nir(X::AbstractSensor)

Return the nir band for the given sensor.
"""
nir(X::AbstractSensor) = error("Error: Band 'nir' not defined for $(typeof(X))!")

"""
    swir1(X::AbstractSensor)

Return the swir1 band for the given sensor.
"""
swir1(X::AbstractSensor) = error("Error: Band 'swir1' not defined for $(typeof(X))!")

"""
    swir2(X::AbstractSensor)

Return the swir2 band for the given sensor.
"""
swir2(X::AbstractSensor) = error("Error: Band 'swir2' not defined for $(typeof(X))!")

"""
    dn2rs(::Type{<:AbstractSensor})

Return the scale and offset required to convert DN to reflectance for the given sensor type.

# Example
```julia-repl
julia> dn2rs(Landsat8)
(scale = 2.75e-5, offset = -0.2)
```
"""
dn2rs(::Type{T}) where {T <: AbstractSensor} = error("Error: 'dn2rs' not defined for $T!")

"""
    dn_to_reflectance(X::AbstractSensor)

Transform the raster from Digital Numbers (DN) to reflectance.
"""
function dn_to_reflectance(X::T) where {T <: AbstractSensor}
    scale, offset = dn2rs(T)
    T(dn_to_reflectance(X.stack, scale, offset))
end

function dn_to_reflectance(X::AbstractRasterStack, scale, offset)
    dn_to_reflectance(X, Float32(scale), Float32(offset))
end

function dn_to_reflectance(X::AbstractRasterStack, scale::Float32, offset::Float32)
    map(x -> mask((x .* scale) .+ offset; with=x, missingval=Float32(missingval(x))), X)
end

"""
    asraster(f, X::AbstractSensor)

Operate on the AbstractSensor as if it was a regular `Rasters.RasterStack`.
    
# Example
```julia
landsat = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1/")
asraster(landsat) do stack
    map(x -> x .* 0.0001f0, stack)
end
```
"""
asraster(f, X::T) where {T <: AbstractSensor} = T(f(X.stack))

Base.size(X::AbstractSensor) = Base.size(X.stack)

Base.size(X::AbstractSensor, i) = Base.size(X.stack, i)

Base.length(X::AbstractSensor) = X.stack |> keys |> length

Base.show(io::IO, x::AbstractSensor) = Base.show(io, x.stack)

Base.show(io::IO, d::MIME"text/plain", x::AbstractSensor) = Base.show(io, d, x.stack)

Base.getindex(X::T, a) where {T <: AbstractSensor} = wrap_raster(X.stack[a], T)

Base.getindex(X::T, a, b) where {T <: AbstractSensor} = wrap_raster(X.stack[a,b], T)

Base.getindex(X::T, a, b, c) where {T <: AbstractSensor} = wrap_raster(X.stack[a,b,c], T)

Base.view(X::T, a) where {T <: AbstractSensor} = wrap_raster((@view X.stack[a]), T)

Base.view(X::T, a, b) where {T <: AbstractSensor} = wrap_raster((@view X.stack[a,b]), T)

Base.view(X::T, a, b, c) where {T <: AbstractSensor} = wrap_raster((@view X.stack[a,b,c]), T)

Base.map(f, c::T) where {T <: AbstractSensor} = T(map(f, c.stack))

Rasters.resample(x::T; kwargs...) where {T <: AbstractSensor} = T(Rasters.resample(x.stack; kwargs...))

Rasters.crop(x::T; kwargs...) where {T <: AbstractSensor} = T(Rasters.crop(x.stack; kwargs...))

Rasters.extend(x::T; kwargs...) where {T <: AbstractSensor} = T(Rasters.extend(x.stack; kwargs...))

Rasters.trim(x::T; kwargs...) where {T <: AbstractSensor} = T(Rasters.trim(x.stack; kwargs...))

Rasters.mask(x::T; kwargs...) where {T <: AbstractSensor} = T(Rasters.mask(x.stack; kwargs...))

Rasters.replace_missing(x::T; kwargs...) where {T <: AbstractSensor} = T(Rasters.replace_missing(x.stack; kwargs...))

Rasters.zonal(f, x::AbstractSensor; kwargs...) = Rasters.zonal(f, x.stack; kwargs...)

Base.write(filename::AbstractString, s::AbstractSensor; kwargs...) = Base.write(s.stack; kwargs...)

Statistics.mean(x::T; kwargs...) where {T <: AbstractSensor} = T(Statistics.mean(x.stack; kwargs...))

Statistics.median(x::T; kwargs...) where {T <: AbstractSensor} = T(Statistics.median(x.stack; kwargs...))

wrap_raster(x::RasterStack, T::Type{<:AbstractSensor}) = T(x)

wrap_raster(x, T::Type{<:AbstractSensor}) = x

include("landsat8.jl")
include("landsat7.jl")
include("sentinel2a.jl")
include("DESIS.jl")

export AbstractSensor, BandSet, Landsat8, Landsat7, Sentinel2A, DESIS
export red, green, blue, nir, swir1, swir2, dn2rs, dn_to_reflectance, asraster

end