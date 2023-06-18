"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for DESIS.
"""
struct DESIS{T<:AbstractRasterStack} <: AbstractSensor{T}
    stack::T
end

function DESIS(filename::String)
    return DESIS(RasterStack(Raster(filename), layersfrom=Rasters.Band))
end

unwrap(X::DESIS) = X.stack

blue(X::DESIS) = X[:Band_25]

green(X::DESIS) = X[:Band_52]

red(X::DESIS) = X[:Band_90]

nir(X::DESIS) = X[:Band_175]

dn2rs(::Type{<:DESIS}) = (scale=0.0001, offset=0.0)

function bandset(::Type{<:DESIS})
    return BandSet(Symbol.(["Band_$i" for i in 1:235]), collect(401.275:2.553:998.75))
end
