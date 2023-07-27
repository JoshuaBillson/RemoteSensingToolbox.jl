"Return the number of bands in a raster."
function nbands(raster::AbstractRaster)
    return any(isa.(dims(raster), Rasters.Band)) ? size(raster, Rasters.Band) : 1
end

function nbands(raster::AbstractRasterStack)
    return length(raster)
end

"Resample a collection of rasters to a common extent and resolution"
function align_rasters(rasters::Vararg{Raster})
    max_size = argmax(x->x[1], size.(rasters))
    map(rasters) do r
        size(r) == max_size ? efficient_read(r) : resample(r; size=max_size[1:2])
    end
end

"Read a raster from disk into memory. Return immediately if raster has already been read."
function efficient_read(r::Raster)
    return r.data isa Rasters.DiskArrays.AbstractDiskArray ? read(r) : r
end

function _copy_dims(data::AbstractArray{<:Number,3}, reference::AbstractRaster)
    band_dim = Rasters.Band(LookupArrays.Categorical(1:size(data, 3), order=LookupArrays.ForwardOrdered()))
    ref_dims = (dims(reference, :X), dims(reference, :Y), band_dim)
    return Raster(data; crs=crs(reference), dims=ref_dims)
end

function _copy_dims(data::AbstractArray{<:Number,2}, reference::AbstractRaster)
    ref_dims = (dims(reference, :X), dims(reference, :Y))
    return Raster(data; crs=crs(reference), dims=ref_dims)
end

function _raster_to_df(raster::AbstractRasterStack)
    data = [reshape(replace_missing(raster[layer]).data, :) for layer in names(raster)]
    return DataFrames.DataFrame(data, collect(names(raster)))
end

function _raster_to_df(raster::AbstractRaster)
    return _raster_to_df(RasterStack(raster, layersfrom=Rasters.Band))
end

function _drop_nan(raster)
    return ifelse.(isnan.(raster), missingval(raster), raster)
end

function _map_index(f::Function, raster::AbstractRasterStack)
    i = 0
    map(raster) do x
        i += 1
        f(i, x)
    end
end

_second(x) = x[2]