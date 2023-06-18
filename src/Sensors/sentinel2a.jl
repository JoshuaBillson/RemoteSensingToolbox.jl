"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Sentinel-2A.
"""
struct Sentinel2A{T<:AbstractRasterStack} <: AbstractSensor{T}
    stack::T
end

function Sentinel2A(dir::String; ext="jp2")
    # Get Files
    files = [f for f in readdir(dir, join=true) if split(f, ".")[end] == ext]

    # Get Bands
    bands = map(x->split(x, "_")[end][1:3], files) .|> Symbol

    # Move :B8A To Correct Position
    first = [(band, file) for (band, file) in zip(bands, files) if !(band in (:B8A, :B09, :B10, :B11, :B12))]
    middle = [(band, file) for (band, file) in zip(bands, files) if band == :B8A]
    last = [(band, file) for (band, file) in zip(bands, files) if !(band in (:B01, :B02, :B03, :B04, :B05, :B06, :B07, :B08, :B8A))]
    files = [file for (_, file) in vcat(first, middle, last)]
    bands = [band for (band, _) in vcat(first, middle, last)]

    # Resize Rasters To Common Resolution
    rasters = @pipe align_rasters(Raster.(files)...)

    # Add Missing Value
    rasters = Tuple(rebuild(x, missingval=typemax(eltype(x))) for x in rasters)

    # Return
    return Sentinel2A(RasterStack(rasters; name=bands))
end

unwrap(X::Sentinel2A) = X.stack

blue(X::Sentinel2A) = X[:B02]

green(X::Sentinel2A) = X[:B03]

red(X::Sentinel2A) = X[:B04]

nir(X::Sentinel2A) = X[:B08]

swir1(X::Sentinel2A) = X[:B11]

swir2(X::Sentinel2A) = X[:B12]

dn2rs(::Type{<:Sentinel2A}) = (scale=0.0001, offset=0.0)

function bandset(::Type{<:Sentinel2A})
    bands = [:B01, :B02, :B03, :B04, :B05, :B06, :B07, :B08, :B8A, :B09, :B10, :B11, :B12]
    wavelengths = [443, 490, 560, 665, 705, 740, 783, 842, 865, 945, 1375, 1610, 2190]
    return BandSet(bands, wavelengths)
end
