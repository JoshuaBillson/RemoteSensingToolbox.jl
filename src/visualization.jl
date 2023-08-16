"""True color band composite."""
struct TrueColor{T<:AbstractBandset} end

"""Color infrared band composite."""
struct ColorInfrared{T<:AbstractBandset} end

"""SWIR band composite."""
struct SWIR{T<:AbstractBandset} end

"""Agriculture band composite."""
struct Agriculture{T<:AbstractBandset} end

"""Geology band composite."""
struct Geology{T<:AbstractBandset} end

"""
    visualize(g::AbstractRaster; lower=0.02, upper=0.98)
    visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; lower=0.02, upper=0.98)
    visualize(img::AbstractRasterStack, ::Type{TrueColor{AbstractBandset}}; kwargs...)
    visualize(img::AbstractRasterStack, ::Type{ColorInfrared{AbstractBandset}}; kwargs...)
    visualize(img::AbstractRasterStack, ::Type{SWIR{AbstractBandset}}; kwargs...)
    visualize(img::AbstractRasterStack, ::Type{Agriculture{AbstractBandset}}; kwargs...)
    visualize(img::AbstractRasterStack, ::Type{Geology{AbstractBandset}}; kwargs...)

Visualize a satellite image after applying a histogram stretch. Returns either an RGB or grayscale image compatible with the `Images.jl` ecosystem.

A number of band combinations are supported for types implementing the `AbstractBandSet` interface.

# Example 1
```julia
landsat = read_bands(Landsat8, "LC08_L2SP_043024_20200802_20200914_02_T1/")
mndwi(landsat, Landsat8) |> visualize
```

# Example 2
```julia
landsat = read_bands(Landsat8, "LC08_L2SP_043024_20200802_20200914_02_T1/")
visualize(landsat, TrueColor{Landsat8}; upper=0.90)
```
"""
function visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; kwargs...)
    visualize(Float32.(r), Float32.(g), Float32.(b); kwargs...)
end

function visualize(g::AbstractRaster; kwargs...)
    visualize(Float32.(g); kwargs...)
end
    
function visualize(stack::AbstractRasterStack, ::Type{TrueColor{T}}; kwargs...) where {T <: AbstractBandset}
    visualize(red(stack, T), green(stack, T), blue(stack, T); kwargs...)
end

function visualize(stack::AbstractRasterStack ,::Type{ColorInfrared{T}}; kwargs...) where {T <: AbstractBandset}
    visualize(nir(stack, T), red(stack, T), green(stack, T); kwargs...)
end

function visualize(stack::AbstractRasterStack ,::Type{SWIR{T}}; kwargs...) where {T <: AbstractBandset}
    visualize(swir2(stack, T), swir1(stack, T), red(stack, T); kwargs...)
end

function visualize(stack::AbstractRasterStack ,::Type{Agriculture{T}}; kwargs...) where {T <: AbstractBandset}
    visualize(swir1(stack, T), nir(stack, T), blue(stack, T); kwargs...)
end

function visualize(stack::AbstractRasterStack ,::Type{Geology{T}}; kwargs...) where {T <: AbstractBandset}
    visualize(swir2(stack, T),swir1(stack, T), blue(stack, T); kwargs...)
end

function visualize(r::AbstractRaster{Float32}, g::AbstractRaster{Float32}, b::AbstractRaster{Float32}; lower=0.02, upper=0.98)
    return @pipe map(x -> _linear_stretch(x, lower, upper), (r, g, b)) |> cat(_..., dims=Rasters.Band) |> _raster_to_image
end

function visualize(g::AbstractRaster{Float32}; lower=0.02, upper=0.98)
    return _linear_stretch(g, lower, upper) |> _raster_to_image
end

function plot_mask(mask, classes, figure=(;), legend=(;))
    # Create Color Gradient
    colors = CairoMakie.cgrad(:viridis, length(classes), categorical=true)

    # Create Plot
    fig, ax, plt = CairoMakie.heatmap(mask, colormap=colors, figure=figure);
    CairoMakie.hidedecorations!(ax)

    # Create Legend
    elements = [CairoMakie.PolyElement(color=color, strokecolor=:transparent) for color in colors]
    CairoMakie.Legend(fig[1,2], elements, classes, "Legend", legend...)

    return fig
end

function plot_image(img)
    fig, ax, plt = @pipe img |> rotr90 |> CairoMakie.image(_, axis=(;aspect=CairoMakie.DataAspect()), figure=(; resolution=reverse(size(img)) .+ 64))
    CairoMakie.hidedecorations!(ax)
    return fig, ax, plt
end

"Adjust image histogram by performing a linear stretch to squeeze all values between the percentiles `lower` and `upper` into the range [0,1]."
function _linear_stretch(img::AbstractRaster, lower, upper)
    return _linear_stretch(Float32.(efficient_read(img)), lower, upper)
end

function _linear_stretch(img::AbstractRaster{Float32}, lower, upper)
    # Read Image Into Memory
    img = img |> efficient_read
    values = img |> skipmissing |> collect |> sort!

    # Find Lower And Upper Bounds
    lb = Float32(quantile(values, lower, sorted=true))
    ub = Float32(quantile(values, upper, sorted=true))

    # Adjust Histogram
    adjusted = img .- lb
    adjusted ./= (ub - lb)
    clamp!(adjusted, 0.0f0, 1.0f0)
    return mask!(adjusted; with=img)
end

"Turn a raster into an image compatible with Images.jl."
function _raster_to_image(raster::Raster)
    # Set Missing Values To Zero (Black)
    raster = replace_missing(raster, eltype(raster)(0))

    # Dispatch Based On Element Type and Shape
    return _raster_to_image(raster.data)
end

function _raster_to_image(raster::Array)
    return _raster_to_image(ImageCore.N0f8.(raster))
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
