"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Landsat 8.
"""
struct Landsat8 <: AbstractSensor
    stack::RasterStack
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

blue(X::Landsat8) = X[:B2]

green(X::Landsat8) = X[:B3]

red(X::Landsat8) = X[:B4]

nir(X::Landsat8) = X[:B5]

swir1(X::Landsat8) = X[:B6]

swir2(X::Landsat8) = X[:B7]

dn_to_reflectance(X::Landsat8) = map(x -> mask((x .* 0.0000275f0) .- 0.2f0; with=x, missingval=Float32(missingval(x))), X)