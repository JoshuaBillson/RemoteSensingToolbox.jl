"""True color band composite."""
struct TrueColor end

"""Color infrared band composite."""
struct ColorInfrared end

"""SWIR band composite."""
struct SWIR end

"""Agriculture band composite."""
struct Agriculture end

"""Geology band composite."""
struct Geology end

"""
    visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; lower=0.02, upper=0.98)
    visualize(g::AbstractRaster; lower=0.02, upper=0.98)
    visualize(img::AbstractSensor, ::Type{TrueColor}; lower=0.02, upper=0.98)
    visualize(img::AbstractSensor, ::Type{ColorInfrared}; lower=0.02, upper=0.98)
    visualize(img::AbstractSensor, ::Type{SWIR}; lower=0.02, upper=0.98)
    visualize(img::AbstractSensor, ::Type{Agriculture}; lower=0.02, upper=0.98)
    visualize(img::AbstractSensor, ::Type{Geology}; lower=0.02, upper=0.98)

Visualize a remotely sensed image by applying a histogram stretch. Returns either an RGB or grayscale image compatible with the `Images.jl` ecosystem.

A number of band combinations are supported for types implementing the `AbstractSensor` interface.

# Example 1
```julia
landsat = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1/")
img = visualize(red(landsat), green(landsat), blue(landsat))
save("truecolor.png", img)
```

# Example 2
```julia
landsat = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1/")
img = visualize(landsat, TrueColor)
save("truecolor.png", img)
```
"""
function visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; lower=0.02, upper=0.98)
    visualize(r .* 1.0f0, g .* 1.0f0, b .* 1.0f0; lower=lower, upper=upper)
end
    
function visualize(r::AbstractRaster{Float32}, g::AbstractRaster{Float32}, b::AbstractRaster{Float32}; lower=0.02, upper=0.98)
    @pipe map(img->linear_stretch(img, lower, upper), align_rasters(r, g, b)) |>
    cat(extract_raster_data.(_)..., dims=3) |>
    raster_to_image
end

function visualize(g::AbstractRaster; lower=0.02, upper=0.98)
    visualize(g .* 1.0f0; lower=lower, upper=upper)
end
    
function visualize(g::AbstractRaster{Float32}; lower=0.02, upper=0.98)
    @pipe efficient_read(g) |>
    linear_stretch(_, lower, upper) |>
    extract_raster_data |>
    raster_to_image
end

function visualize(img::AbstractSensor, ::Type{TrueColor}; lower=0.02, upper=0.98)
    visualize(red(img), green(img), blue(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{ColorInfrared}; lower=0.02, upper=0.98)
    visualize(nir(img), red(img), green(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{SWIR}; lower=0.02, upper=0.98)
    visualize(swir2(img), swir1(img), red(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{Agriculture}; lower=0.02, upper=0.98)
    visualize(swir1(img), nir(img), blue(img), lower=lower, upper=upper)
end

function visualize(img::AbstractSensor, ::Type{Geology}; lower=0.02, upper=0.98)
    visualize(swir2(img), swir1(img), blue(img), lower=lower, upper=upper)
end

function Images.mosaicview(sensor::AbstractSensor; lower=0.02, upper=0.98, ratio=0.1, kwargs...)
    layers = keys(sensor.stack)
    imgs = [Images.imresize(visualize(sensor.stack[layer]; lower=lower, upper=upper); ratio=ratio) for layer in layers]
    return Images.mosaicview(imgs...; kwargs...)
end