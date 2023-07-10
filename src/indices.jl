"""
    mndwi(green::AbstractRaster, swir::AbstractRaster)
    mndwi(sensor::AbstractBandset)

Compute the Modified Normalised Difference Water Index (Xu 2006).

MNDWI = (green - swir) / (green + swir)
"""
function mndwi(green::AbstractRaster, swir::AbstractRaster)
    return mndwi(green .* 1.0f0, swir .* 1.0f0)
end
 
function mndwi(green::AbstractRaster{Float32}, swir::AbstractRaster{Float32})
    green, swir = align_rasters(green, swir)
    index = (green .- swir) ./ (green .+ swir)
    return mask(index; with=green, missingval=-Inf32)
end

function mndwi(sensor::AbstractBandset)
    return mndwi(green(sensor), swir1(sensor))
end

"""
    ndwi(green::AbstractRaster, nir::AbstractRaster)
    ndwi(sensor::AbstractBandset)

Compute the Normalized Difference Water Index (McFeeters 1996).

NDWI = (green - nir) / (green + nir)
"""
function ndwi(green::AbstractRaster, nir::AbstractRaster)
    return ndwi(green .* 1.0f0, nir .* 1.0f0)
end
 
function ndwi(green::AbstractRaster{Float32}, nir::AbstractRaster{Float32})
    green, nir = align_rasters(green, nir)
    index = (green .- nir) ./ (green .+ nir)
    return mask(index; with=green, missingval=-Inf32)
end

function ndwi(sensor::AbstractBandset)
    return ndwi(green(sensor), nir(sensor))
end

"""
    ndvi(nir::AbstractRaster, red::AbstractRaster)
    ndvi(sensor::AbstractBandset)

Compute the Normalized Difference Vegetation Index.

NDVI = (nir - red) / (nir + red)
"""
function ndvi(nir::AbstractRaster, red::AbstractRaster)
    return ndvi(nir .* 1.0f0, red .* 1.0f0)
end
 
function ndvi(nir::AbstractRaster{Float32}, red::AbstractRaster{Float32})
    nir, red = align_rasters(nir, red)
    index = (nir .- red) ./ (nir .+ red)
    return mask(index; with=nir, missingval=-Inf32)
end

function ndvi(sensor::AbstractBandset)
    return ndvi(nir(sensor), red(sensor))
end

"""
    savi(nir::AbstractRaster, red::AbstractRaster; L=0.33)
    savi(sensor::AbstractBandset; L=0.33)

Compute the Soil Adjusted Vegetation Index (Huete 1988).

SAVI is a vegetation index which attempts to minimize soil brightness influences by introducing a soil-brightness correction factor (L).

L represents the amount of green vegetation cover, which is set to 0.33 by default.

SAVI = ((nir - red) / (nir + red + L)) * (1 + L)
"""
function savi(nir::AbstractRaster, red::AbstractRaster; L=0.33)
    return savi(nir .* 1.0f0, red .* 1.0f0; L=L)
end
 
function savi(nir::AbstractRaster{Float32}, red::AbstractRaster{Float32}; L=0.33)
    nir, red = align_rasters(nir, red)
    index = ((nir .- red) ./ (nir .+ red .+ Float32(L))) .* (1.0f0 + Float32(L))
    return mask(index; with=nir, missingval=-Inf32)
end

function savi(sensor::AbstractBandset; L=0.33)
    return savi(nir(sensor), red(sensor); L=L)
end

"""
    ndmi(nir::AbstractRaster, swir1::AbstractRaster)
    ndmi(sensor::AbstractBandset)

Compute the Normalized Difference Moisture Index.

NDMI is sensitive to the moisture levels in vegetation. It is used to monitor droughts and fuel levels in fire-prone areas.

NDMI = (nir - swir1) / (nir + swir1)
"""
function ndmi(nir::AbstractRaster, swir1::AbstractRaster)
    return ndmi(nir .* 1.0f0, swir1 .* 1.0f0)
end
 
function ndmi(nir::AbstractRaster{Float32}, swir1::AbstractRaster{Float32})
    nir, swir1 = align_rasters(nir, swir1)
    index = (nir .- swir1) ./ (nir .+ swir1)
    return mask(index; with=nir, missingval=-Inf32)
end

function ndmi(sensor::AbstractBandset)
    return ndmi(nir(sensor), swir1(sensor))
end

"""
    nbri(nir::AbstractRaster, swir2::AbstractRaster)
    nbri(sensor::AbstractBandset)

Compute the Normalized Burn Ratio Index.

NBRI is used to emphasize burned areas.

NBRI = (nir - swir2) / (nir + swir2)
"""
function nbri(nir::AbstractRaster, swir2::AbstractRaster)
    return nbri(nir .* 1.0f0, swir2 .* 1.0f0)
end
 
function nbri(nir::AbstractRaster{Float32}, swir2::AbstractRaster{Float32})
    nir, swir2 = align_rasters(nir, swir2)
    index = (nir .- swir2) ./ (nir .+ swir2)
    return mask(index; with=nir, missingval=-Inf32)
end

function nbri(sensor::AbstractBandset)
    return nbri(nir(sensor), swir2(sensor))
end

"""
    ndbi(swir1::AbstractRaster, nir::AbstractRaster)
    ndbi(sensor::AbstractBandset)

Compute the The Normalized Difference Built-up Index

NDBI is used to emphasize urban and built-up areas.

NDBI = (swir1 - nir) / (swir1 + nir)
"""
function ndbi(swir1::AbstractRaster, nir::AbstractRaster)
    return ndbi(swir1 .* 1.0f0, nir .* 1.0f0)
end
 
function ndbi(swir1::AbstractRaster{Float32}, nir::AbstractRaster{Float32})
    swir1, nir = align_rasters(swir1, nir)
    index = (swir1 .- nir) ./ (swir1 .+ nir)
    return mask(index; with=nir, missingval=-Inf32)
end

function ndbi(sensor::AbstractBandset)
    return ndbi(swir1(sensor), nir(sensor))
end