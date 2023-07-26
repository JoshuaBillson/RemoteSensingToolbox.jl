"""
A struct for storing the parameters necessary to perform a normalization transformation.
"""
struct Normalize <: AbstractTransformation
    μ::Vector{Float64}
    σ::Vector{Float64}
end

function Base.show(io::IO, ::MIME"text/plain", x::Normalize)
    μ = @pipe round.(x.μ, digits=4) |> string.(_) |> join(_, " ")
    σ = @pipe round.(x.σ, digits=4) |> string.(_) |> join(_, " ")
    println("Normalize with parameters:")
    println(io, "  μ: ", μ)
    print(io, "  σ: ", σ)
end

"""
    fit_transform(transformation::Type{Normalize}, raster)

Fit a PCA transformation to the given raster.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to perform a normalization transformation.
"""
function fit_transform(::Type{Normalize}, raster::AbstractRasterStack)
    stats = map(keys(raster)) do layer
        x = raster[layer]
        μ = x |> skipmissing |> mean |> Float32
        σ = x |> skipmissing |> std |> Float32
        return μ, σ
    end
    return Normalize(map(first, stats) |> collect, map(_second, stats) |> collect)
end

function fit_transform(::Type{Normalize}, raster::AbstractRaster)
    return fit(Normalize, RasterStack(raster, layersfrom=Rasters.Band))
end

"""
    transform(transformation::Normalize, raster)

Perform a PCA transformation to the given raster.

# Parameters
- `transformation`: The fitted `Normalize` transformation to apply.
- `raster`: The `AbstractRaster` or `AbstractRasterStack` on which to perform a normalization transformation.
"""
function transform(transformation::Normalize, raster::AbstractRasterStack)
    i = 0
    map(raster) do x
        i += 1
        μ = Float32(transformation.μ[i])
        σ = Float32(transformation.σ[i])
        normalized = (x .- μ) ./ σ
        mask!(normalized; with=x, missingval=eltype(normalized)(-Inf))
        return rebuild(normalized, missingval=eltype(normalized)(-Inf))
    end
end

function transform(transformation::Normalize, raster::AbstractRaster)
    μ = @pipe transformation.μ |> reshape(_, (1, 1, :)) |> Float32.(_)
    σ = @pipe transformation.σ |> reshape(_, (1, 1, :)) |> Float32.(_)
    normalized = (raster .- μ) ./ σ
    mask!(normalized; with=raster, missingval=eltype(normalized)(-Inf))
    return rebuild(normalized, missingval=eltype(normalized)(-Inf))
end
