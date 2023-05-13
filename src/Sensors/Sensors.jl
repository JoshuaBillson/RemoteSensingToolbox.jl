module Sensors

using Rasters
using DocStringExtensions
using Pipe: @pipe

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

    dn_to_reflectance(X::AbstractSensor)

# Example Implementation
```julia
struct Landsat8 <: AbstractSensor
    stack::RasterStack
end
    
blue(X::Landsat8) = X[:B2]

green(X::Landsat8) = X[:B3]

red(X::Landsat8) = X[:B4]

nir(X::Landsat8) = X[:B5]

swir1(X::Landsat8) = X[:B6]

swir2(X::Landsat8) = X[:B7]

dn_to_reflectance(X::Landsat8) = map(x -> mask((x .* 0.0000275f0) .- 0.2f0; with=x), X)
```
"""
abstract type AbstractSensor end

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
    dn_to_reflectance(X::AbstractSensor)

Transform the raster from Digital Numbers (DN) to reflectance.
"""
dn_to_reflectance(X::AbstractSensor) = error("Error: 'dn_to_reflectance' not defined for $(typeof(X))!")

function Base.getindex(X::AbstractSensor, i::Symbol)
    @assert i in keys(X.stack) "Band $i Not Found!"
    return X.stack[i]
end

function Base.length(X::AbstractSensor)
    return X.stack |> keys |> length
end

function Base.map(f, c::T) where {T <: AbstractSensor}
    return T(map(f, c.stack))
end

function Base.show(io::IO, x::AbstractSensor)
    Base.show(io, x.stack)
end

function Base.show(io::IO, d::MIME"text/plain", x::AbstractSensor)
    Base.show(io, d, x.stack)
end

function Rasters.resample(x::T; kwargs...) where {T <: AbstractSensor}
    T(Rasters.resample(x.stack; kwargs...))
end

function Rasters.crop(x::T; kwargs...) where {T <: AbstractSensor}
    T(Rasters.crop(x.stack; kwargs...))
end

function Rasters.extend(x::T; kwargs...) where {T <: AbstractSensor}
    T(Rasters.extend(x.stack; kwargs...))
end

function Rasters.trim(x::T; kwargs...) where {T <: AbstractSensor}
    T(Rasters.trim(x.stack; kwargs...))
end

function Rasters.mask(x::T; kwargs...) where {T <: AbstractSensor}
    T(Rasters.mask(x.stack; kwargs...))
end

function Rasters.replace_missing(x::T; kwargs...) where {T <: AbstractSensor}
    T(Rasters.replace_missing(x.stack; kwargs...))
end

include("landsat8.jl")
include("landsat7.jl")
include("sentinel2a.jl")

export AbstractSensor, Landsat8, Landsat7, Sentinel2A, red, green, blue, nir, swir1, swir2, dn_to_reflectance

end