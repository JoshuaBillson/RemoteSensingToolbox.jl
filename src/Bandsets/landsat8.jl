"""
$TYPEDFIELDS

Implements the `AbstractBandset` interface for Landsat 8.
"""
struct Landsat8 <: AbstractBandset end

bands(::Type{Landsat8}) = [:B1, :B2, :B3, :B4, :B5, :B6, :B7]

wavelengths(::Type{Landsat8}) = [443, 483, 560, 660, 865, 1650, 2220]

blue(::Type{Landsat8}) = :B2

green(::Type{Landsat8}) = :B3

red(::Type{Landsat8}) = :B4

nir(::Type{Landsat8}) = :B5

swir1(::Type{Landsat8}) = :B6

swir2(::Type{Landsat8}) = :B7

function read_qa(::Type{Landsat8}, src::String)
    if isdir(src)
        files = readdir(src, join=true)
        reg = BEGIN * zero_or_more(ANY) * "QA_PIXEL." * either("TIF", "tif", "jp2") * END
        return @pipe map(x -> match(reg, x), files) |> filter(x -> !isnothing(x), _) |> first |> _.match |> string |> Raster |> _parse_landsat_qa
    end
    return Raster(src) |> _parse_landsat_qa
end

function dn_to_reflectance(::Type{Landsat8}, raster; clamp_values=false)
    return _decode_dn(raster, 0.0000275f0, -0.2f0; clamp_values=clamp_values)
end