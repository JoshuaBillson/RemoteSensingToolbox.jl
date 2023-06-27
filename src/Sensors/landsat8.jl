"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Landsat 8.
"""
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
    wavelengths = [(430, 450), (450, 510), (530, 590), (640, 670), (850, 880), (1570, 1650), (2110, 2290)]
    return BandSet(bands, map(x -> Interval(x...), wavelengths))
end

function parse_files(::Type{Landsat8}, dir::String)
    bands = bandset(Landsat8).bands .|> string
    return @pipe readdir(dir, join=true) |> _chain_parse.(_, x -> _parse_band(bands, x), _parse_landsat_qa) |> skipmissing |> DataFrame
end