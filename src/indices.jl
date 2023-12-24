"""
    mndwi(green::AbstractRaster, swir::AbstractRaster)
    mndwi(::Type{AbstractBandset}, stack::AbstractRasterStack)

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
    ndwi(green::AbstractRaster, nir::AbstractRaster)
    ndwi(::Type{AbstractBandset}, stack::AbstractRasterStack)

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
    ndvi(nir::AbstractRaster, red::AbstractRaster)
    ndvi(::Type{AbstractBandset}, stack::AbstractRasterStack)

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
    savi(nir::AbstractRaster, red::AbstractRaster; L=0.33)
    savi(stack::AbstractRasterStack, ::Type{AbstractBandset}; L=0.33)

Compute the Soil Adjusted Vegetation Index (Huete 1988).

SAVI is a vegetation index which attempts to minimize soil brightness influences by introducing a soil-brightness correction factor (L).

L represents the amount of green vegetation cover, which is set to 0.33 by default.

SAVI = ((nir - red) / (nir + red + L)) * (1 + L)
"""
function savi(nir::AbstractRaster, red::AbstractRaster; L=0.33)
    return savi(Float32.(nir), Float32.(red); L=L)
end
 
function savi(nir::AbstractRaster{Float32}, red::AbstractRaster{Float32}; L=0.33)
    norm_diff = @pipe ((nir .- red) ./ (nir .+ red .+ Float32(L))) .* (1.0f0 + Float32(L)) |> rebuild(_, missingval=Inf32)
    return @pipe mask!(norm_diff, with=nir) |> RemoteSensingToolbox.mask_nan!
end

function savi(x::T; L=0.33) where {T <: AbstractSatellite}
    return savi(Raster(x, :nir), Raster(x, :red); L=L)
end

"""
    ndmi(nir::AbstractRaster, swir1::AbstractRaster)
    ndmi(::Type{AbstractBandset}, stack::AbstractRasterStack)

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
    nbri(nir::AbstractRaster, swir2::AbstractRaster)
    nbri(::Type{AbstractBandset}, stack::AbstractRasterStack)

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
    ndbi(swir1::AbstractRaster, nir::AbstractRaster)
    ndbi(::Type{AbstractBandset}, stack::AbstractRasterStack)

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