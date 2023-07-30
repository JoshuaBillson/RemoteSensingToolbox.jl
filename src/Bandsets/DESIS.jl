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
    # Read SCL Mask Into Raster
    raster = if isdir(src)
        files = readdir(src, join=true)
        reg = BEGIN * zero_or_more(ANY) * "QL_QUALITY-2." * either("TIF", "tif", "jp2") * END
        @pipe map(x -> match(reg, x), files) |> filter(x -> !isnothing(x), _) |> first |> _.match |> string |> Raster(_, missingval=0x00)
    else
        Raster(src, missingval=0x00)
    end

    # Decode Mask
    shadow = raster[Rasters.Band(1)]
    land = raster[Rasters.Band(2)]
    snow = raster[Rasters.Band(3)]
    haze = raster[Rasters.Band(4)] .| raster[Rasters.Band(5)]
    cloud = raster[Rasters.Band(6)] .| raster[Rasters.Band(7)]
    water = raster[Rasters.Band(8)]

    # Return RasterStack
    return RasterStack(land, water, snow, cloud, shadow, haze; name=(:land, :water, :snow, :cloud, :shadow, :haze))
end