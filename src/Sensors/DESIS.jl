"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for DESIS.
"""
struct DESIS <: AbstractSensor
    stack::RasterStack
end

function DESIS(filename::String)
    return DESIS(RasterStack(Raster(filename), layersfrom=Rasters.Band))
end

function BandSet(::Type{DESIS})
    return BandSet(Symbol.(["Band_$i" for i in 1:235]), collect(400:2.56:1000))
end

blue(X::DESIS) = X[:Band_25]

green(X::DESIS) = X[:Band_52]

red(X::DESIS) = X[:Band_90]

nir(X::DESIS) = X[:Band_175]

dn2rs(::Type{DESIS}) = (scale=0.0001, offset=0.0)