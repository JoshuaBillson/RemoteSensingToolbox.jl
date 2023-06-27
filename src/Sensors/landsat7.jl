"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Landsat 7.
"""
struct Landsat7{T<:AbstractRasterStack} <: AbstractSensor{T}
    stack::T
end
    
function Landsat7(dir::String; ext="TIF", lazy=true)
    # Read Files
    landsat_bands = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]
    files = [f for f in readdir(dir, join=true) if split(f, ".")[end] == ext]

    # Filter Files
    files = filter(x->split(x, "_")[end][1:2] in string.(landsat_bands), files)

    # Read Bands
    bands = map(x->split(x, "_")[end][1:2], files) .|> Symbol

    # Construct Landsat7
    return Landsat7(RasterStack(files; name=bands))
end

unwrap(X::Landsat7) = X.stack

blue(X::Landsat7) = X[:B1]

green(X::Landsat7) = X[:B2]

red(X::Landsat7) = X[:B3]

nir(X::Landsat7) = X[:B4]

swir1(X::Landsat7) = X[:B5]

swir2(X::Landsat7) = X[:B7]

dn2rs(::Type{<:Landsat7}) = (scale=0.0000275, offset=-0.2)

function bandset(::Type{<:Landsat7})
    bands = [:B1, :B2, :B3, :B4, :B5, :B7]
    wavelengths = [483, 560, 660, 835, 1650, 2220]
    return BandSet(bands, wavelengths)
end

function parse_files(::Type{Landsat7}, dir::String)
    bands = bandset(Landsat7).bands .|> string
    return @pipe readdir(dir, join=true) |> _chain_parse.(_, x -> _parse_band(bands, x), _parse_landsat_qa) |> skipmissing |> DataFrame
end