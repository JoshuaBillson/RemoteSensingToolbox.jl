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
function linear_stretch(img, lower, upper)
    lb = @pipe img |> skipmissing |> quantile(_, lower)
    ub = @pipe img |> skipmissing |> quantile(_, upper)
    return Images.adjust_histogram(img, Images.LinearStretching((lb,ub)=>nothing))
end

"Turn a raster into an image compatible with Images.jl."
function raster_to_image(raster::Array{<:Number,3})
    if size(raster, 3) == 1
        return raster_to_image(raster[:,:,1])
    else
        return @pipe permutedims(raster, (3,2,1)) |> Images.colorview(Images.RGB, _)
    end
end

function raster_to_image(raster::Matrix{<:Number})
    @pipe permutedims(raster, (2, 1)) |> Images.colorview(Images.Gray, _)
end

function raster_to_image(raster::Raster)
    return raster_to_image(raster.data)
end

"Extract the raw raster data, discarding all dimensional information."
function extract_raster_data(raster::Array)
    return raster
end

function extract_raster_data(raster::Raster)
    return raster.data
end

function create_patches(raster, patchsize::Tuple{Int,Int}, stride::Tuple{Int,Int})
    sizex, sizey = patchsize
    stridex, stridey = stride
    xlim = size(raster,1)
    ylim = size(raster,2)
    [@view raster[X(x:x+sizex-1), Y(y:y+sizey-1)] for x in 1:stridex:xlim-stridex+1 for y in 1:stridey:ylim-stridey+1]
end
