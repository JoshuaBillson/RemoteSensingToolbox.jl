"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Landsat 7.
"""
struct Landsat7 <: AbstractSensor
    stack::RasterStack
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

blue(X::Landsat7) = X[:B1]

green(X::Landsat7) = X[:B2]

red(X::Landsat7) = X[:B3]

nir(X::Landsat7) = X[:B4]

swir1(X::Landsat7) = X[:B5]

swir2(X::Landsat7) = X[:B7]

dn_to_reflectance(X::Landsat7) = map(x -> mask((x .* 0.0000275f0) .- 0.2f0; with=x, missingval=Float32(missingval(x))), X)