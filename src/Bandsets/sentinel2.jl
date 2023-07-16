"""
$TYPEDFIELDS

Implements the `AbstractBandset` interface for Sentinel 2.
"""
struct Sentinel2 <: AbstractBandset end

bands(::Type{Sentinel2}) = [:B01, :B02, :B03, :B04, :B05, :B06, :B07, :B08, :B8A, :B09, :B10, :B11, :B12]

wavelengths(::Type{Sentinel2}) = [443, 490, 560, 665, 706, 740, 783, 842, 865, 945, 1375, 1610, 2190]

blue(::Type{Sentinel2}) = :B02

green(::Type{Sentinel2}) = :B03

red(::Type{Sentinel2}) = :B04

nir(::Type{Sentinel2}) = :B08

swir1(::Type{Sentinel2}) = :B11

swir2(::Type{Sentinel2}) = :B12

function parse_band(::Type{Sentinel2}, filename::String)
    reg = "_" * capture(either(string.(bands(Sentinel2))...), as="band") * zero_or_more(ANY) * "." * ["TIF", "tif", "jp2"] * END
    m = match(reg, filename)
    return !isnothing(m) ? Symbol(m[:band]) : nothing
end

function read_qa(::Type{Sentinel2}, src::String)
    if isdir(src)
        files = readdir(src, join=true)
        reg = BEGIN * zero_or_more(ANY) * "QA_PIXEL." * either("TIF", "tif", "jp2") * END
        return @pipe map(x -> match(reg, x), files) |> filter(x -> !isnothing(x), _) |> first |> _.match |> string |> Raster |> _parse_landsat_qa
    end
    return Raster(src) |> _parse_landsat_qa
end

function dn_to_reflectance(stack::AbstractRasterStack, ::Type{Sentinel2}; clamp_values=false)
    return map(x -> _decode_dn(x, 0.0001, 0.0; clamp_values), stack)
end