"""
$TYPEDFIELDS

Implements the `AbstractSensor` interface for Sentinel-2A.
"""
struct Sentinel2{T<:AbstractRasterStack} <: AbstractSensor{T}
    stack::T
end

function Sentinel2(dir::String; ext="jp2")
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
    return Sentinel2(RasterStack(rasters; name=bands))
end

unwrap(X::Sentinel2) = X.stack

blue(X::Sentinel2) = X[:B02]

green(X::Sentinel2) = X[:B03]

red(X::Sentinel2) = X[:B04]

nir(X::Sentinel2) = X[:B08]

swir1(X::Sentinel2) = X[:B11]

swir2(X::Sentinel2) = X[:B12]

dn2rs(::Type{<:Sentinel2}) = (scale=0.0001, offset=0.0)

function bandset(::Type{<:Sentinel2})
    bands = [:B01, :B02, :B03, :B04, :B05, :B06, :B07, :B08, :B8A, :B09, :B10, :B11, :B12]
    wavelengths = [(433, 453), (458, 523), (543, 578), (650, 680), (698, 713), (733, 748), (773, 793), (785, 900), (855, 875), (935, 955), (1360, 1390), (1565, 1655), (2100, 2280)]
    return BandSet(bands, map(x -> Interval(x...), wavelengths))
end

function parse_files(::Type{Sentinel}, dir::String)
    return @pipe readdir(dir, join=true) |> _chain_parse.(_, _parse_band, _parse_landsat_qa) |> skipmissing |> DataFrame
end