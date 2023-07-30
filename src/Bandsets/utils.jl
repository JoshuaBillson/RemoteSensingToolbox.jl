function _parse_landsat_qa(filename::String)
    reg = "_QA_PIXEL." * either("TIF", "tif") * END
    m = match(reg, filename)
    return !isnothing(m) ? (band=:QA, src=filename) : missing
end

function _read_bit(x, pos; bits=16)
    return UInt8.((x .<< (bits - pos)) .>> 15)
end

function _parse_landsat_qa(qa::AbstractRaster)
    # Read Bits
    fill = @pipe _read_bit(qa, 1) |> rebuild(_; missingval=0x01)
    dilated_cloud = @pipe _read_bit(qa, 2) |> rebuild(_; missingval=0xff)
    cirrus = @pipe _read_bit(qa, 3) |> rebuild(_; missingval=0xff)
    cloud = @pipe _read_bit(qa, 4) |> rebuild(_; missingval=0xff)
    cloud_shadow = @pipe _read_bit(qa, 5) |> rebuild(_; missingval=0xff)
    snow = @pipe _read_bit(qa, 6) |> rebuild(_; missingval=0xff)
    clear = @pipe _read_bit(qa, 7) |> rebuild(_; missingval=0xff)
    water = @pipe _read_bit(qa, 8) |> rebuild(_; missingval=0xff)

    # Mask Missing Pixels
    rasters = [dilated_cloud, cirrus, cloud, cloud_shadow, snow, clear, water]
    for raster in rasters
        mask!(raster; with=fill)
    end
    
    # Return RasterStack
    names = (:dilated_cloud, :cirrus, :cloud, :cloud_shadow, :snow, :clear, :water)
    return RasterStack(rasters..., name=names)
end

function _decode_dn(raster::AbstractRaster, scale::Float32, offset::Float32; clamp_values=false)
    # Apply Scale And Offset
    reflectance = (raster .* scale) .+ offset

    # Clamp Reflectance
    clamp_values && clamp!(reflectance, 0.0f0, 1.0f0)

    # Mask Missing Pixels
    mask!(reflectance; with=raster, missingval=Inf32)

    # Set Missing Value
    rebuild(reflectance, missingval=Inf32)
end

function _decode_dn(raster::AbstractRasterStack, scale::Float32, offset::Float32; kwargs...)
    return map(x -> _decode_dn(x, Float32(scale), Float32(offset); kwargs...), raster)
end

function _decode_dn(raster, scale, offset; kwargs...)
    return _decode_dn(raster, Float32(scale), Float32(offset); kwargs...)
end

function _ensure_missing(raster)
    if isnothing(missingval(raster))
        return rebuild(raster; missingval=typemax(eltype(raster)))
    end
    return raster
end