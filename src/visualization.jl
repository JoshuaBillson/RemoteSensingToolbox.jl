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
    visualize(img::AbstractBandSet, ::Type{TrueColor{AbstractBandset}}; kwargs...)
    visualize(img::AbstractBandSet, ::Type{ColorInfrared{AbstractBandset}}; kwargs...)
    visualize(img::AbstractBandSet, ::Type{SWIR{AbstractBandset}}; kwargs...)
    visualize(img::AbstractBandSet, ::Type{Agriculture{AbstractBandset}}; kwargs...)
    visualize(img::AbstractBandSet, ::Type{Geology{AbstractBandset}}; kwargs...)

Visualize a satellite image after applying a histogram stretch. Returns either an RGB or grayscale image compatible with the `Images.jl` ecosystem.

A number of band combinations are supported for types implementing the `AbstractBandSet` interface.

# Example 1
```julia
landsat = read(Landsat8, "LC08_L2SP_043024_20200802_20200914_02_T1/")
img = mndwi(landsat, Landsat8) |> visualize
save("mndwi.png", img)
```

# Example 2
```julia
landsat = read(Landsat8, "LC08_L2SP_043024_20200802_20200914_02_T1/")
img = visualize(landsat, TrueColor{Landsat8}; upper=0.90)
save("truecolor.png", img)
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
    return @pipe map(x -> linear_stretch(x, lower, upper), (r, g, b)) |> cat(_..., dims=Rasters.Band) |> raster_to_image
end

function visualize(g::AbstractRaster{Float32}; lower=0.02, upper=0.98)
    return linear_stretch(g, lower, upper) |> raster_to_image
end

function plot_mask(mask, classes)
    # Create Plot
    fig, ax, plt = CairoMakie.plot(mask)
    CairoMakie.hidedecorations!(ax)

    # Create Legend
    colors = CairoMakie.cgrad(:viridis, length(classes), categorical=true)
    elements = [CairoMakie.PolyElement(color=color, strokecolor=:transparent) for color in colors]
    CairoMakie.Legend(fig[1,2], elements, classes, "Legend")

    return fig
end