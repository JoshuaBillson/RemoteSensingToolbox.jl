"""
    visualize(g::AbstractRaster; lower=0.02, upper=0.98)
    visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; lower=0.02, upper=0.98)

Visualize an RGB or grayscale satellite image.

Returns a `Raster` of either `RGB{N0f8}` or `Gray{N0f8}` elements.

# Keywords
- `lower`: The lower percentile to use for adjusting the image histogram.
- `upper`: The upper percentile to use for adjusting the image histogram.

# Example
```julia
using RemoteSensingToolbox, ArchGDAL, Rasters, FileIO, JpegTurbo

# Prepare a Landsat 8 Image
src = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1")

# Display True Color Image
r, g, b = RasterStack(src, [:red, :green, :blue])
img = visualize(r, g, b; upper=0.90)
FileIO.save("truecolor.jpg", img)
```
"""
function visualize(r::AbstractRaster, g::AbstractRaster, b::AbstractRaster; lower=0.02, upper=0.98)
    return @pipe map(x -> _linear_stretch(x, lower, upper), (r, g, b)) |> cat(_..., dims=Rasters.Band) |> _raster_to_image
end

function visualize(g::AbstractRaster; lower=0.02, upper=0.98)
    return _linear_stretch(g, lower, upper) |> _raster_to_image
end
    
"""
    true_color(src::AbstractSatellite; lower=0.02, upper=0.98)
    true_color(s::Type{AbstractSatellite}, raster::AbstractRasterStack; lower=0.02, upper=0.98)

Visualize a satellite image using the true-color band combination, which appears like a natural image.

Accepts either an `AbstractSatellite` or a combination of `Type{AbstractSatellite}` and `AbstractRasterStack`.

Returns a `Raster` of either `RGB{N0f8}` or `Gray{N0f8}` elements.

# Keywords
- `lower`: The lower percentile to use for adjusting the image histogram.
- `upper`: The upper percentile to use for adjusting the image histogram.

# Example
```julia
using RemoteSensingToolbox, ArchGDAL, Rasters

# Prepare a Landsat 8 Image
src = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1")

# Read Bands Directly from Disk
true_color(src; upper=0.90)

# Read Bands from a RasterStack
stack = RasterStack(src; lazy=true)
true_color(Landsat8, stack; upper=0.90)
```
"""
function true_color(::Type{T}, raster::AbstractRasterStack; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = translate_color.(T, (:red, :green, :blue))
    visualize(raster[r], raster[g], raster[b]; lower=lower, upper=upper)
end

function true_color(src::T; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = RasterStack(src, [:red, :green, :blue])
    visualize(r, g, b; lower=lower, upper=upper)
end

"""
    color_infrared(src::AbstractSatellite; lower=0.02, upper=0.98)
    color_infrared(s::Type{AbstractSatellite}, raster::AbstractRasterStack; lower=0.02, upper=0.98)

Visualize a satellite image using the color-infrared band combination, which highlight vegetation in red, water in blue, and urban areas in grey.

Accepts either an `AbstractSatellite` or a combination of `Type{AbstractSatellite}` and `AbstractRasterStack`.

Returns a `Raster` of either `RGB{N0f8}` or `Gray{N0f8}` elements.

# Keywords
- `lower`: The lower percentile to use for adjusting the image histogram.
- `upper`: The upper percentile to use for adjusting the image histogram.
"""
function color_infrared(::Type{T}, raster::AbstractRasterStack; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = translate_color.(T, (:nir, :red, :green))
    visualize(raster[r], raster[g], raster[b]; lower=lower, upper=upper)
end

function color_infrared(src::T; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = RasterStack(src, [:nir, :red, :green])
    visualize(r, g, b; lower=lower, upper=upper)
end

"""
    swir(src::AbstractSatellite; lower=0.02, upper=0.98)
    swir(s::Type{AbstractSatellite}, raster::AbstractRasterStack; lower=0.02, upper=0.98)

Visualize a satellite image using the SWIR band combination, which emphasizes dense vegetation as dark green.

Accepts either an `AbstractSatellite` or a combination of `Type{AbstractSatellite}` and `AbstractRasterStack`.

Returns a `Raster` of either `RGB{N0f8}` or `Gray{N0f8}` elements.

# Keywords
- `lower`: The lower percentile to use for adjusting the image histogram.
- `upper`: The upper percentile to use for adjusting the image histogram.
"""
function swir(::Type{T}, raster::AbstractRasterStack; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = translate_color.(T, (:swir2, :swir1, :red))
    visualize(raster[r], raster[g], raster[b]; lower=lower, upper=upper)
end

function swir(src::T; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = RasterStack(src, [:swir2, :swir1, :red])
    visualize(r, g, b; lower=lower, upper=upper)
end

"""
    agriculture(src::AbstractSatellite; lower=0.02, upper=0.98)
    agriculture(s::Type{AbstractSatellite}, raster::AbstractRasterStack; lower=0.02, upper=0.98)

Visualize a satellite image with the agricultural band combination, which is used for crop monitoring and emphasizes healthy vegetation.

Accepts either an `AbstractSatellite` or a combination of `Type{AbstractSatellite}` and `AbstractRasterStack`.

Returns a `Raster` of either `RGB{N0f8}` or `Gray{N0f8}` elements.

# Keywords
- `lower`: The lower percentile to use for adjusting the image histogram.
- `upper`: The upper percentile to use for adjusting the image histogram.
"""
function agriculture(::Type{T}, raster::AbstractRasterStack; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = translate_color.(T, (:swir1, :nir, :blue))
    visualize(raster[r], raster[g], raster[b]; lower=lower, upper=upper)
end

function agriculture(src::T; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = RasterStack(src, [:swir1, :nir, :blue])
    visualize(r, g, b; lower=lower, upper=upper)
end

"""
    geology(src::AbstractSatellite; lower=0.02, upper=0.98)
    geology(s::Type{AbstractSatellite}, raster::AbstractRasterStack; lower=0.02, upper=0.98)

Visualize a satellite image with the geology band combination, which emphasizes geological formations, lithology features, and faults.

Accepts either an `AbstractSatellite` or a combination of `Type{AbstractSatellite}` and `AbstractRasterStack`.

Returns a `Raster` of either `RGB{N0f8}` or `Gray{N0f8}` elements.

# Keywords
- `lower`: The lower percentile to use for adjusting the image histogram.
- `upper`: The upper percentile to use for adjusting the image histogram.
"""
function geology(::Type{T}, raster::AbstractRasterStack; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = translate_color.(T, (:swir2, :swir1, :blue))
    visualize(raster[r], raster[g], raster[b]; lower=lower, upper=upper)
end

function geology(src::T; lower=0.02, upper=0.98) where {T <: AbstractSatellite}
    r, g, b = RasterStack(src, [:swir2, :swir1, :blue])
    visualize(r, g, b; lower=lower, upper=upper)
end

"Adjust image histogram by performing a linear stretch to squeeze all values between the percentiles `lower` and `upper` into the range [0,1]."
function _linear_stretch(img::AbstractRaster, lower, upper)
    return _linear_stretch(replace_missing(img |> efficient_read, Inf32), lower, upper)
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
    raster = replace_missing(raster, 0)  # Set Missing Values To Zero (Black)
    return raster |> efficient_read .|> ImageCore.N0f8 |> _raster_to_image
end

function _raster_to_image(raster::Raster{ImageCore.N0f8})
    _dims = (dims(raster, Y), dims(raster, X))
    return @pipe raster.data |> _colorview |> Raster(_, _dims)
end

function _colorview(x::Matrix{ImageCore.N0f8})
    return @pipe permutedims(x, (2, 1)) |> ImageCore.colorview(ImageCore.Gray, _)
end

function _colorview(x::Array{ImageCore.N0f8})
    if size(x, 3) == 1
        return _colorview(x[:,:,1])
    end
    return @pipe permutedims(x, (3,2,1)) |> ImageCore.colorview(ImageCore.RGB, _)
end