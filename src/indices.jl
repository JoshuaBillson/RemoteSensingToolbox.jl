"""
    mndwi(green::AbstractRaster, swir::AbstractRaster)
    mndwi(stack::AbstractRasterStack, ::Type{AbstractBandset})

Compute the Modified Normalised Difference Water Index (Xu 2006).

MNDWI = (green - swir) / (green + swir)
"""
function mndwi(green::AbstractRaster, swir::AbstractRaster)
    return mndwi(encode(green, Float32), encode(swir, Float32))
end
 
function mndwi(green::AbstractRaster{Float32}, swir::AbstractRaster{Float32})
    index = (green .- swir) ./ (green .+ swir)
    return mask(index; with=green, missingval=-Inf32) |> _drop_nan
end

function mndwi(stack::AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset}
    return mndwi(green(stack, T), swir1(stack, T))
end

"""
    ndwi(green::AbstractRaster, nir::AbstractRaster)
    ndwi(stack::AbstractRasterStack, ::Type{AbstractBandset})

Compute the Normalized Difference Water Index (McFeeters 1996).

NDWI = (green - nir) / (green + nir)
"""
function ndwi(green::AbstractRaster, nir::AbstractRaster)
    return ndwi(encode(green, Float32), encode(nir, Float32))
end
 
function ndwi(green::AbstractRaster{Float32}, nir::AbstractRaster{Float32})
    index = (green .- nir) ./ (green .+ nir)
    return mask(index; with=green, missingval=-Inf32) |> _drop_nan
end

function ndwi(stack::AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset}
    return ndwi(green(stack, T), nir(stack, T))
end

"""
    ndvi(nir::AbstractRaster, red::AbstractRaster)
    ndvi(stack::AbstractRasterStack, ::Type{AbstractBandset})

Compute the Normalized Difference Vegetation Index.

NDVI = (nir - red) / (nir + red)
"""
function ndvi(nir::AbstractRaster, red::AbstractRaster)
    return ndvi(encode(nir, Float32), encode(red, Float32))
end
 
function ndvi(nir::AbstractRaster{Float32}, red::AbstractRaster{Float32})
    index = (nir .- red) ./ (nir .+ red)
    return mask(index; with=nir, missingval=-Inf32) |> _drop_nan
end

function ndvi(stack::AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset}
    return ndvi(nir(stack, T), red(stack, T))
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
    return savi(encode(nir, Float32), encode(red, Float32); L=L)
end
 
function savi(nir::AbstractRaster{Float32}, red::AbstractRaster{Float32}; L=0.33)
    index = ((nir .- red) ./ (nir .+ red .+ Float32(L))) .* (1.0f0 + Float32(L))
    return mask(index; with=nir, missingval=-Inf32) |> _drop_nan
end

function savi(stack::AbstractRasterStack, ::Type{T}; L=0.33) where {T <: AbstractBandset}
    return savi(nir(stack, T), red(stack, T); L=L)
end

"""
    ndmi(nir::AbstractRaster, swir1::AbstractRaster)
    ndmi(stack::AbstractRasterStack, ::Type{AbstractBandset})

Compute the Normalized Difference Moisture Index.

NDMI is sensitive to the moisture levels in vegetation. It is used to monitor droughts and fuel levels in fire-prone areas.

NDMI = (nir - swir1) / (nir + swir1)
"""
function ndmi(nir::AbstractRaster, swir1::AbstractRaster)
    return ndmi(encode(nir, Float32), encode(swir1, Float32))
end
 
function ndmi(nir::AbstractRaster{Float32}, swir1::AbstractRaster{Float32})
    index = (nir .- swir1) ./ (nir .+ swir1)
    return mask(index; with=nir, missingval=-Inf32) |> _drop_nan
end

function ndmi(stack::AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset}
    return ndmi(nir(stack, T), swir1(stack, T))
end

"""
    nbri(nir::AbstractRaster, swir2::AbstractRaster)
    nbri(stack::AbstractRasterStack, ::Type{AbstractBandset})

Compute the Normalized Burn Ratio Index.

NBRI is used to emphasize burned areas.

NBRI = (nir - swir2) / (nir + swir2)
"""
function nbri(nir::AbstractRaster, swir2::AbstractRaster)
    return nbri(encode(nir, Float32), encode(swir2, Float32))
end
 
function nbri(nir::AbstractRaster{Float32}, swir2::AbstractRaster{Float32})
    index = (nir .- swir2) ./ (nir .+ swir2)
    return mask(index; with=nir, missingval=-Inf32) |> _drop_nan
end

function nbri(stack::AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset}
    return nbri(nir(stack, T), swir2(stack, T))
end

"""
    ndbi(swir1::AbstractRaster, nir::AbstractRaster)
    ndbi(stack::AbstractRasterStack, ::Type{AbstractBandset})

Compute the The Normalized Difference Built-up Index

NDBI is used to emphasize urban and built-up areas.

NDBI = (swir1 - nir) / (swir1 + nir)
"""
function ndbi(swir1::AbstractRaster, nir::AbstractRaster)
    return ndbi(encode(swir1, Float32), encode(nir, Float32))
end
 
function ndbi(swir1::AbstractRaster{Float32}, nir::AbstractRaster{Float32})
    index = (swir1 .- nir) ./ (swir1 .+ nir)
    return mask(index; with=nir, missingval=-Inf32) |> _drop_nan
end

function ndbi(stack::AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset}
    return ndbi(swir1(stack, T), nir(stack, T))
end