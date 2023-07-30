"""
$TYPEDFIELDS

Implements the `AbstractBandset` interface for Landsat 7.
"""
struct Landsat7 <: AbstractBandset end

bands(::Type{Landsat7}) = [:B1, :B2, :B3, :B4, :B5, :B7]

wavelengths(::Type{Landsat7}) = [483, 560, 660, 835, 1650, 2220]

blue(::Type{Landsat7}) = :B1

green(::Type{Landsat7}) = :B2

red(::Type{Landsat7}) = :B3

nir(::Type{Landsat7}) = :B4

swir1(::Type{Landsat7}) = :B5

swir2(::Type{Landsat7}) = :B7

dn2rs(::Type{Landsat7}) = (scale=0.0000275, offset=-0.2)

function read_qa(::Type{Landsat7}, src::String)
    if isdir(src)
        files = readdir(src, join=true)
        reg = BEGIN * zero_or_more(ANY) * "QA_PIXEL." * either("TIF", "tif", "jp2") * END
        return @pipe map(x -> match(reg, x), files) |> filter(x -> !isnothing(x), _) |> first |> _.match |> string |> Raster |> _parse_landsat_qa
    end
    return Raster(src) |> _parse_landsat_qa
end

function dn_to_reflectance(::Type{Landsat7}, raster; clamp_values=false)
    return _decode_dn(raster, 0.0000275f0, -0.2f0; clamp_values=clamp_values)
end