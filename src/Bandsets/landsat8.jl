"""
$TYPEDFIELDS

Implements the `AbstractBandset` interface for Landsat 8.
"""
struct Landsat8{T} <: AbstractBandset{T}
    stack::T
end

function Landsat8(dir::String)
    files = @pipe bands(Landsat8) |> string.(_) |> map(x -> _parse_band(_, x), readdir(dir, join=true)) |> skipmissing |> collect
    RasterStack(map(x -> x.src, files), name=map(x -> x.band, files)) |> Landsat8
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

dn2rs(::Type{<:Landsat8}) = (scale=0.0000275, offset=-0.2)