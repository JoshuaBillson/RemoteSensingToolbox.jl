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

"Adjust image histogram by performing a linear stretch to squeeze all values between the percentiles `lower` and `upper` into the range [0,1]."
function linear_stretch(img::AbstractRaster, lower, upper)
    return linear_stretch(Float32.(efficient_read(img)), lower, upper)
end

function linear_stretch(img::AbstractRaster{Float32}, lower, upper)
    img = img |> efficient_read
    values = img |> skipmissing |> collect |> sort!
    lb = quantile(values, lower, sorted=true)
    ub = quantile(values, upper, sorted=true)
    normalized = Rasters.modify(x -> Images.adjust_histogram(x, Images.LinearStretching((lb,ub)=>nothing)), img)
    return mask!(normalized; with=img)
end

"Turn a raster into an image compatible with Images.jl."
function raster_to_image(raster::Raster)
    # Set Missing Values To Zero (Black)
    raster = replace_missing(raster, eltype(raster)(0))

    # Dispatch Based On Element Type and Shape
    return _raster_to_image(raster.data)
end

function _raster_to_image(raster::Array)
    return _raster_to_image(Images.N0f8.(raster))
end

function _raster_to_image(raster::Array{Images.N0f8})
    if size(raster, 3) == 1
        return _raster_to_image(raster[:,:,1])
    end
    return @pipe permutedims(raster, (3,2,1)) |> Images.colorview(Images.RGB, _)
end

function _raster_to_image(raster::Matrix{Images.N0f8})
    return @pipe permutedims(raster, (2, 1)) |> Images.colorview(Images.Gray, _)
end

"Extract the raw raster data, discarding all dimensional information."
function extract_raster_data(raster::AbstractArray)
    return raster
end

function extract_raster_data(raster::Raster)
    return raster.data
end

function contains_bands(raster)
    return @pipe dims(raster) |> isa.(_, Rasters.Band) |> any
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

function _stack_to_df(stack::AbstractRasterStack)
    data = [reshape(replace_missing(stack[layer]).data, :) for layer in names(stack)]
    return DataFrames.DataFrame(data, collect(names(stack)))
end

function DataFrames.DataFrame(stack::AbstractRasterStack)
    return _stack_to_df(stack)
end

function _drop_nan(raster)
    return ifelse.(isnan.(raster), missingval(raster), raster)
end

_second(x) = x[2]