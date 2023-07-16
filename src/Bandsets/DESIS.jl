"""
$TYPEDFIELDS

Implements the `AbstractBandset` interface for Landsat 7.
"""
struct DESIS <: AbstractBandset end

bands(::Type{DESIS}) = Symbol.(["B_$i" for i in 1:235])

wavelengths(::Type{DESIS}) = collect(401.275:2.553:998.75)

blue(::Type{DESIS}) = :B_25

green(::Type{DESIS}) = :B_52

red(::Type{DESIS}) = :B_90

nir(::Type{DESIS}) = :B_175

dn2rs(::Type{DESIS}) = (scale=0.0001, offset=0.0)

function parse_band(::Type{DESIS}, filename::String)
    reg = "SPECTRAL_IMAGE." * either("TIF", "tif", "jp2") * END
    return isnothing(match(reg, filename)) ? nothing : bands(DESIS)
end

function read_qa(::Type{DESIS}, src::String)
    if isdir(src)
        files = readdir(src, join=true)
        reg = BEGIN * zero_or_more(ANY) * "QA_PIXEL." * either("TIF", "tif", "jp2") * END
        return @pipe map(x -> match(reg, x), files) |> filter(x -> !isnothing(x), _) |> first |> _.match |> string |> Raster |> _parse_landsat_qa
    end
    return Raster(src) |> _parse_landsat_qa
end

function dn_to_reflectance(stack::AbstractRasterStack, ::Type{DESIS}; clamp_values=false)
    return map(x -> _decode_dn(x, 0.0001, 0.0; clamp_values), stack)
end