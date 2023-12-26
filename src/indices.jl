"""
    mndwi(src::AbstractSatellite)
    mndwi(green::AbstractRaster, swir::AbstractRaster)

Compute the Modified Normalised Difference Water Index (Xu 2006).

MNDWI = (green - swir) / (green + swir)
"""
function mndwi(green::AbstractRaster, swir::AbstractRaster)
    return _normalized_difference(green, swir)
end
 
function mndwi(x::T) where {T <: AbstractSatellite}
    return mndwi(Raster(x, :green), Raster(x, :swir1))
end

"""
    ndwi(src::AbstractSatellite)
    ndwi(green::AbstractRaster, nir::AbstractRaster)

Compute the Normalized Difference Water Index (McFeeters 1996).

NDWI = (green - nir) / (green + nir)
"""
function ndwi(green::AbstractRaster, nir::AbstractRaster)
    return _normalized_difference(green, nir)
end
 
function ndwi(x::T) where {T <: AbstractSatellite}
    return ndwi(Raster(x, :green), Raster(x, :nir))
end

"""
    ndvi(src::AbstractSatellite)
    ndvi(nir::AbstractRaster, red::AbstractRaster)

Compute the Normalized Difference Vegetation Index.

NDVI = (nir - red) / (nir + red)
"""
function ndvi(nir::AbstractRaster, red::AbstractRaster)
    return _normalized_difference(nir, red)
end
 
function ndvi(x::T) where {T <: AbstractSatellite}
    return ndvi(Raster(x, :nir), Raster(x, :red))
end

"""
    savi(src::AbstractSatellite; L=0.33)
    savi(nir::AbstractRaster, red::AbstractRaster; L=0.33, scale=1.0, offset=0.0)

Compute the Soil Adjusted Vegetation Index (Huete 1988).

SAVI is a vegetation index which attempts to minimize soil brightness influences by introducing a soil-brightness correction factor (L).

SAVI = ((nir - red) / (nir + red + L)) * (1 + L)

# Keywords
- `L`: The ammount of vegetative cover, where 1.0 means no vegetation and 0.0 means high vegetation.
- `scale`: The scaling factor to convert digital numbers to reflectance.
- `offset`: The offset to convert digital numbers to reflectance.
"""
function savi(nir::AbstractRaster, red::AbstractRaster; kwargs...)
    return savi(Float32.(nir), Float32.(red); kwargs...)
end
 
function savi(nir::AbstractRaster{Float32}, red::AbstractRaster{Float32}; L=0.33, scale=1.0, offset=0.0)
    # Convert DNs to Reflectance
    nir_sr = @pipe ((nir .* Float32(scale)) .+ Float32(offset)) |> clamp!(_, 0.0f0, 1.0f0)
    red_sr = @pipe ((red .* Float32(scale)) .+ Float32(offset)) |> clamp!(_, 0.0f0, 1.0f0)

    # Calculate SAVI
    norm_diff = ((nir_sr .- red_sr) ./ (nir_sr .+ red_sr .+ Float32(L))) .* (1.0f0 + Float32(L))
    return @pipe mask!(norm_diff, with=nir, missingval=Inf32) |> RemoteSensingToolbox.mask_nan!
end

function savi(x::T; L=0.33, kwargs...) where {T <: AbstractSatellite}
    nir = Raster(x, :nir)
    red = Raster(x, :red)
    return savi(nir, red; L=L, scale=dn_scale(T, nir.name), offset=dn_offset(T, nir.name))
end

"""
    ndmi(src::AbstractSatellite)
    ndmi(nir::AbstractRaster, swir1::AbstractRaster)

Compute the Normalized Difference Moisture Index.

NDMI is sensitive to the moisture levels in vegetation. It is used to monitor droughts and fuel levels in fire-prone areas.

NDMI = (nir - swir1) / (nir + swir1)
"""
function ndmi(nir::AbstractRaster, swir1::AbstractRaster)
    return _normalized_difference(nir, swir1)
end
 
function ndmi(x::T) where {T <: AbstractSatellite}
    return ndmi(Raster(x, :nir), Raster(x, :swir1))
end

"""
    nbri(src::AbstractSatellite)
    nbri(nir::AbstractRaster, swir2::AbstractRaster)

Compute the Normalized Burn Ratio Index.

NBRI is used to emphasize burned areas.

NBRI = (nir - swir2) / (nir + swir2)
"""
function nbri(nir::AbstractRaster, swir2::AbstractRaster)
    return _normalized_difference(nir, swir2)
end
 
function nbri(x::T) where {T <: AbstractSatellite}
    return nbri(Raster(x, :nir), Raster(x, :swir2))
end

"""
    ndbi(src::AbstractSatellite)
    ndbi(swir1::AbstractRaster, nir::AbstractRaster)

Compute the The Normalized Difference Built-up Index

NDBI is used to emphasize urban and built-up areas.

NDBI = (swir1 - nir) / (swir1 + nir)
"""
function ndbi(swir1::AbstractRaster, nir::AbstractRaster)
    return _normalized_difference(swir1, nir)
end
 
function ndbi(x::T) where {T <: AbstractSatellite}
    return ndbi(Raster(x, :swir1), Raster(x, :nir))
end

function _normalized_difference(a::AbstractRaster, b::AbstractRaster)
    return _normalized_difference(Float32.(a), Float32.(b))
end

function _normalized_difference(a::AbstractRaster{Float32}, b::AbstractRaster{Float32})
    norm_diff = rebuild((a .- b) ./ (a .+ b), missingval=Inf32)
    return @pipe mask!(norm_diff; with=a) |> RemoteSensingToolbox.mask_nan!
end