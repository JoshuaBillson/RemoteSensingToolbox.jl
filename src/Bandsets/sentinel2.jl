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

nir(raster::Rasters.AbstractRasterStack, ::Type{Sentinel2}) = :B8A in names(raster) ? raster[:B8A] : raster[:B08]

swir1(::Type{Sentinel2}) = :B11

swir2(::Type{Sentinel2}) = :B12

function parse_band(::Type{Sentinel2}, filename::String)
    reg = "_" * capture(either(string.(bands(Sentinel2))...), as="band") * zero_or_more(ANY) * "." * ["TIF", "tif", "jp2"] * END
    m = match(reg, filename)
    return !isnothing(m) ? Symbol(m[:band]) : nothing
end

function read_qa(::Type{Sentinel2}, src::String)
    # Read SCL Mask Into Raster
    raster = if isdir(src)
        files = readdir(src, join=true)
        reg = BEGIN * zero_or_more(ANY) * "SCL_" * either("60m", "20m", "10m") * "." * either("TIF", "tif", "jp2") * END
        @pipe map(x -> match(reg, x), files) |> filter(x -> !isnothing(x), _) |> first |> _.match |> string |> Raster(_, missingval=0x00)
    else
        Raster(src, missingval=0x00)
    end

    # Decode SCL Bits
    rasters = [ifelse.(raster .== i, 0x01, 0x00) for i in 3:11]

    # Return RasterStack
    return RasterStack(rasters..., name=(:cloud_shadow, :vegetation, :soil, :water, :clouds_low, :clouds_med, :clouds_high, :cirrus, :snow))
end