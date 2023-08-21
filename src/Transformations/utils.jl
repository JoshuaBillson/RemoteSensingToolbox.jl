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

function _eigen(A)
    eigs, vecs = LinearAlgebra.eigen(A)
    return reverse(eigs), reverse(vecs, dims=2)
end