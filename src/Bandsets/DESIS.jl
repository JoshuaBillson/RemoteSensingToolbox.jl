"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for DESIS.
"""
struct DESIS{T<:AbstractRasterStack} <: AbstractBandset{T}
    stack::T
end

function DESIS(dir::String)
    filename = @pipe readdir(dir, join=true) |> _parse_bands.(_) |> skipmissing |> first
    return DESIS(RasterStack(filename, layersfrom=Rasters.Band))
end
    
unwrap(X::DESIS) = X.stack

bands(::Type{<:DESIS}) = Symbol.(["Band_$i" for i in 1:235])

wavelengths(::Type{<:DESIS}) = collect(401.275:2.553:998.75)

blue(X::DESIS) = X[:Band_25]

green(X::DESIS) = X[:Band_52]

red(X::DESIS) = X[:Band_90]

nir(X::DESIS) = X[:Band_175]

function _parse_bands(filename::String)
    reg = "SPECTRAL_IMAGE." * either("TIF", "tif", "jp2") * END
    return isnothing(match(reg, filename)) ? missing : filename
end