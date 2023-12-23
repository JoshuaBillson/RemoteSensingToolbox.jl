abstract type AbstractCombination{T<:AbstractSatellite} end

"""True color band composite."""
struct TrueColor{T} <: AbstractCombination{T} end

"""Color infrared band composite."""
struct ColorInfrared{T} <: AbstractCombination{T} end

"""SWIR band composite."""
struct SWIR{T} <: AbstractCombination{T} end

"""Agriculture band composite."""
struct Agriculture{T} <: AbstractCombination{T} end

"""Geology band composite."""
struct Geology{T} <: AbstractCombination{T} end

"""
    visualize(g::AbstractRaster; lower=0.02, upper=0.98)
    visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; lower=0.02, upper=0.98)
    visualize(::Type{AbstractCombination{AbstractSatellite}}, img::AbstractRasterStack; kwargs...)

Visualize a satellite image by applying a histogram stretch.

Returns either an RGB or grayscale image compatible with the `Images.jl` ecosystem.

# Example
```julia
using RemoteSensingToolbox, ArchGDAL, Rasters, FileIO, JpegTurbo

# Lazily Read Bands Into a RasterStack
src = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1")
stack = RasterStack(src, lazy=true)

# Display True Color Image
img = visualize(TrueColor{Landsat8}, stack; upper=0.90)
FileIO.save("truecolor.jpg", img)
```
```
"""
function visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; lower=0.02, upper=0.98)
    return @pipe map(x -> _linear_stretch(x, lower, upper), (r, g, b)) |> cat(_..., dims=Rasters.Band) |> _raster_to_image
end

function visualize(g::AbstractRaster; lower=0.02, upper=0.98)
    return _linear_stretch(g, lower, upper) |> _raster_to_image
end
    
function visualize(::Type{TrueColor{T}}, raster::Union{<:AbstractRasterStack, <:AbstractRaster}; kwargs...) where {T <: AbstractSatellite}
    visualize(raster[red_band(T)], raster[green_band(T)], raster[blue_band(T)]; kwargs...)
end

function visualize(::Type{ColorInfrared{T}}, raster::AbstractRasterStack; kwargs...) where {T <: AbstractSatellite}
    visualize(raster[nir_band(T)], raster[red_band(T)], raster[green_band(T)]; kwargs...)
end

function visualize(::Type{SWIR{T}}, raster::AbstractRasterStack; kwargs...) where {T <: AbstractSatellite}
    visualize(raster[swir2_band(T)], raster[swir1_band(T)], raster[red_band(T)]; kwargs...)
end

function visualize(::Type{Agriculture{T}}, raster::AbstractRasterStack; kwargs...) where {T <: AbstractSatellite}
    visualize(raster[swir1_band(T)], raster[nir_band(T)], raster[blue_band(T)]; kwargs...)
end

function visualize(::Type{Geology{T}}, raster::AbstractRasterStack; kwargs...) where {T <: AbstractSatellite}
    visualize(raster[swir2_band(T)], raster[swir1_band(T)], raster[blue_band(T)]; kwargs...)
end

"Adjust image histogram by performing a linear stretch to squeeze all values between the percentiles `lower` and `upper` into the range [0,1]."
function _linear_stretch(img::AbstractRaster, lower, upper)
    return _linear_stretch(Float32.(img |> efficient_read), lower, upper)
end

function _linear_stretch(img::AbstractRaster{Float32}, lower, upper)
    # Read Image Into Memory
    img = img |> efficient_read
    
    # Get Sorted Values
    values = img |> skipmissing |> collect |> sort!

    # Find Lower And Upper Bounds
    lb = Float32(quantile(values, lower, sorted=true))
    ub = Float32(quantile(values, upper, sorted=true))

    # Adjust Histogram
    adjusted = img .- lb
    adjusted ./= (ub - lb)
    clamp!(adjusted, 0.0f0, 1.0f0)
    return mask!(adjusted, with=img)
end

"Turn a raster into an image compatible with Images.jl."
function _raster_to_image(raster::Raster)
    # Set Missing Values To Zero (Black)
    raster = replace_missing(raster, 0)

    # Dispatch Based On Element Type and Shape
    return ImageCore.N0f8.(raster.data) |> _raster_to_image
end

function _raster_to_image(raster::Array{ImageCore.N0f8})
    if size(raster, 3) == 1
        return _raster_to_image(raster[:,:,1])
    end
    return @pipe permutedims(raster, (3,2,1)) |> ImageCore.colorview(ImageCore.RGB, _)
end

function _raster_to_image(raster::Matrix{ImageCore.N0f8})
    return @pipe permutedims(raster, (2, 1)) |> ImageCore.colorview(ImageCore.Gray, _)
end