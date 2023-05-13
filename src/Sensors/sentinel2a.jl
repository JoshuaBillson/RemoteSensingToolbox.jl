"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Sentinel-2A.
"""
struct Sentinel2A <: AbstractSensor
    stack::RasterStack
end

function Sentinel2A(dir::String; ext="jp2", missingval=0)
    files = [f for f in readdir(dir, join=true) if split(f, ".")[end] == ext]
    bands = map(x->split(x, "_")[end][1:3], files) .|> Symbol
    rasters = align_rasters(Raster.(files, missingval=missingval)...)
    return Sentinel2A(RasterStack(rasters; name=bands))
end

blue(X::Sentinel2A) = X[:B02]

green(X::Sentinel2A) = X[:B03]

red(X::Sentinel2A) = X[:B04]

nir(X::Sentinel2A) = X[:B08]

swir1(X::Sentinel2A) = X[:B11]

swir2(X::Sentinel2A) = X[:B12]

dn_to_reflectance(X::Sentinel2A) = map(x -> mask(x .* 0.0001f0; with=x, missingval=Float32(missingval(x))), X)