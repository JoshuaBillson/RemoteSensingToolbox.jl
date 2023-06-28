"""
$TYPEDFIELDS

Implements the `AbstractBandset` interface for Sentinel 2.
"""
struct Sentinel2{T} <: AbstractBandset{T}
    stack::T
end

function Sentinel2(dir::String)
    files = @pipe bands(Sentinel2) |> string.(_) |> map(x -> _parse_band(_, x), readdir(dir, join=true)) |> skipmissing |> collect
    rasters = @pipe map(x -> x.src, files) |> Raster.(_) |> map(x -> rebuild(x; missingval=typemax(eltype(x))), _) |> align_rasters(_...)
    RasterStack(rasters..., name=map(x -> x.band, files)) |> Sentinel2
end
    
unwrap(X::Sentinel2) = X.stack

bands(::Type{<:Sentinel2}) = [:B01, :B02, :B03, :B04, :B05, :B06, :B07, :B08, :B8A, :B09, :B10, :B11, :B12]

wavelengths(::Type{<:Sentinel2}) = [443, 490, 560, 665, 706, 740, 783, 842, 865, 945, 1375, 1610, 2190]

blue(X::Sentinel2) = X[:B02]

green(X::Sentinel2) = X[:B03]

red(X::Sentinel2) = X[:B04]

nir(X::Sentinel2) = X[:B08]

swir1(X::Sentinel2) = X[:B11]

swir2(X::Sentinel2) = X[:B12]