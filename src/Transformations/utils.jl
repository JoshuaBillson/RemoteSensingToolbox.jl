function _mean(raster::AbstractRaster)
    return [(view(raster, Rasters.Band(i)) |> skipmissing |> mean) for i in 1:size(raster, Rasters.Band)]
end

function _mean(raster::AbstractRasterStack)
    return [(layer |> skipmissing |> mean) for layer in raster]
end

function _std(raster::AbstractRaster)
    return [(view(raster, Rasters.Band(i)) |> skipmissing |> std) for i in 1:size(raster, Rasters.Band)]
end

function _std(raster::AbstractRasterStack)
    return [(layer |> skipmissing |> std) for layer in raster]
end

function _centralize(raster, μ::AbstractVector)
    return _centralize(raster, Float32.(μ))
end

function _centralize(raster::AbstractRaster, μ::AbstractVector{Float32})
    return @pipe raster .- reshape(μ, (1,1,:)) |> Rasters.mask!(_, with=raster)
end

function _centralize(raster::AbstractRasterStack, μ::AbstractVector{Float32})
    _map_index(raster) do i, x
        @pipe x .- μ[i] |> Rasters.mask!(_, with=x)
    end
end