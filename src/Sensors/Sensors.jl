module Sensors

using Rasters
using DocStringExtensions
using Pipe: @pipe

import Statistics
import Tables
import RemoteSensingToolbox: align_rasters, efficient_read

"""
The supertype of all sensor types. 

Subtypes should wrap a RasterStack under the field 'stack' and implement the following interface:

    unwrap(X::Sensor)

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
struct Landsat8{T<:AbstractRasterStack} <: AbstractSensor{T}
    stack::T
end
    
unwrap(X::Landsat8) = X.stack

blue(X::Landsat8) = X[:B2]

green(X::Landsat8) = X[:B3]

red(X::Landsat8) = X[:B4]

nir(X::Landsat8) = X[:B5]

swir1(X::Landsat8) = X[:B6]

swir2(X::Landsat8) = X[:B7]

dn2rs(::Type{<:Landsat8}) = (scale=0.0000275, offset=-0.2)

function bandset(::Type{<:Landsat8})
    bands = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]
    wavelengths = [440, 480, 560, 655, 865, 1610, 2200]
    return BandSet(bands, wavelengths)
end

```
"""
abstract type AbstractSensor{T} end

include("bandset.jl")

include("interface.jl")

# Base Interface

Base.show(io::IO, X::AbstractSensor) = Base.show(io, unwrap(X))

Base.show(io::IO, d::MIME"text/plain", X::AbstractSensor) = Base.show(io, d, unwrap(X))

Base.write(filename::AbstractString, X::AbstractSensor; kwargs...) = Base.write(unwrap(X); kwargs...)

Base.map(f, X::AbstractSensor) = asraster(x -> Base.map(f, x), X)

for op = (:size, :length, :names, :keys)
    @eval Base.$op(X::AbstractSensor, args...) = Base.$op(unwrap(X), args...)
end

for op = (:getindex, :view)
    @eval begin
        Base.$op(X::AbstractSensor, a::Symbol) = unwrap(X)[a]
        Base.$op(X::AbstractSensor, args...) = asraster(Base.$op, X, args...)
    end
end


# Rasters Interface

Rasters.modify(f, X::AbstractSensor) = asraster(x -> Rasters.modify(f, x), X)

Rasters.zonal(f, X::AbstractSensor; kwargs...) = Rasters.zonal(f, unwrap(X); kwargs...)

for op = (:resample, :crop, :extend, :trim, :mask, :mask!, :replace_missing, :replace_missing!)
    @eval Rasters.$op(X::AbstractSensor; kwargs...) = asraster(Rasters.$op, X; kwargs...)
end


# Statistics Interface

for op = (:mean, :median, :std)
    @eval Statistics.$op(X::AbstractSensor; kwargs) = Statistics.$op(unwrap(X); kwargs...)
end


# Tables Interface

Tables.columnaccess(::Type{<:AbstractSensor}) = true

Tables.columns(X::AbstractSensor) = unwrap(X) |> Tables.columns


# Exports

include("landsat8.jl")
include("landsat7.jl")
include("sentinel2a.jl")
include("DESIS.jl")

export AbstractSensor, BandSet, Landsat8, Landsat7, Sentinel2A, DESIS
export red, green, blue, nir, swir1, swir2, dn2rs, asraster, unwrap, bandset

end