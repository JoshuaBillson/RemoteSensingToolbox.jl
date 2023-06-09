"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Landsat 8.
"""
struct Landsat8{T<:AbstractRasterStack} <: AbstractSensor{T}
    stack::T
end
    
function Landsat8(dir::String; ext="TIF")
    # Read Files
    landsat_bands = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]
    files = [f for f in readdir(dir, join=true) if split(f, ".")[end] == ext]

    # Filter Files
    files = filter(x->split(x, "_")[end][1:2] in string.(landsat_bands), files)
    files = filter(x->!contains(x, "_B10"), files)

    # Read Bands
    bands = map(x->split(x, "_")[end][1:2], files) .|> Symbol

    # Construct Landsat8
    return Landsat8(RasterStack(files; name=bands))
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
