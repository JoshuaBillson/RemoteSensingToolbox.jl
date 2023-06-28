"""
$TYPEDFIELDS

Implements the `AbstractBandset` interface for Landsat 8.
"""
struct Landsat7{T} <: AbstractBandset{T}
    stack::T
end

function Landsat7(dir::String)
    files = @pipe bands(Landsat7) |> string.(_) |> map(x -> _parse_band(_, x), readdir(dir, join=true)) |> skipmissing |> collect
    RasterStack(map(x -> x.src, files), name=map(x -> x.band, files)) |> Landsat7
end
    
unwrap(X::Landsat7) = X.stack

bands(::Type{<:Landsat7}) = [:B1, :B2, :B3, :B4, :B5, :B7]

wavelengths(::Type{<:Landsat7}) = [483, 560, 660, 835, 1650, 2220]

blue(X::Landsat7) = X[:B1]

green(X::Landsat7) = X[:B2]

red(X::Landsat7) = X[:B3]

nir(X::Landsat7) = X[:B4]

swir1(X::Landsat7) = X[:B5]

swir2(X::Landsat7) = X[:B7]

#dn2rs(::Type{<:Landsat8}) = (scale=0.0000275, offset=-0.2)