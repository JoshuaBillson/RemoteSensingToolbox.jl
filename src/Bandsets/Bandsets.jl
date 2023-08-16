module Bandsets

using Rasters
using ReadableRegex
using DocStringExtensions
using Pipe: @pipe

import Tables
import RemoteSensingToolbox: align_rasters, efficient_read

"""
The supertype of all sensor types. Provides sensor-specific information to many `RemoteSensingToolbox` methods.
"""
abstract type AbstractBandset end

include("utils.jl")
include("interface.jl")

"""
    wavelength(::Type{AbstractBandset}, band::Symbol)

Return the central wavelength for the corresponding band.
"""
function wavelength(::Type{T}, band::Symbol) where {T <: AbstractBandset}
    !(band in bands(T)) && throw(ArgumentError("$band not found in bands $(bands(T))!"))
    return @pipe findfirst(isequal(band), bands(T)) |> wavelengths(T)[_]
end

"""
    function read_bands(bandset::Type{AbstractBandset}, dir::String)

Read the bands from the given directory into a `RasterStack`.

# Parameters
- `bandset`: The sensor type to which the bands belong.
- `dir`: The directory in which the bands can be read.

# Example
```julia-repl
julia> landsat = read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/")
RasterStack with dimensions: 
  X Projected{Float64} LinRange{Float64}(493785.0, 728385.0, 7821) ForwardOrdered Regular Points crs: WellKnownText,
  Y Projected{Float64} LinRange{Float64}(5.84638e6, 5.60878e6, 7921) ReverseOrdered Regular Points crs: WellKnownText
and 7 layers:
  :B1 UInt16 dims: X, Y (7821×7921)
  :B2 UInt16 dims: X, Y (7821×7921)
  :B3 UInt16 dims: X, Y (7821×7921)
  :B4 UInt16 dims: X, Y (7821×7921)
  :B5 UInt16 dims: X, Y (7821×7921)
  :B6 UInt16 dims: X, Y (7821×7921)
  :B7 UInt16 dims: X, Y (7821×7921)
```
"""
function read_bands(::Type{T}, dir::String) where {T <: AbstractBandset}
    # Parse Bands From Files
    files = readdir(dir, join=true)
    parsed_bands = parse_band.(T, files)
    filtered = filter(x -> !isnothing(x[2]), zip(files, parsed_bands) |> collect)

    # Construct RasterStack
    if isempty(filtered)
        error("Error: No valid files could be parsed from the provided directory!")
    elseif first(filtered)[2] isa AbstractVector
        filename = first(filtered)[1]
        layers = first(filtered)[2]
        raster = Raster(filename) |> _ensure_missing
        return RasterStack([raster[Rasters.Band(i)] for i in eachindex(layers)]..., name=layers)
    else
        rasters = @pipe first.(filtered) |> Raster.(_) |> align_rasters(_...) |> _ensure_missing.(_)
        return RasterStack(rasters..., name=map(x -> x[2], filtered))
    end
end

for op = (:blue, :green, :red, :nir, :swir1, :swir2)
    @eval $op(raster::Rasters.AbstractRasterStack, ::Type{T}) where {T <: AbstractBandset} = raster[$op(T)]
end

include("landsat8.jl")
include("landsat7.jl")
include("sentinel2.jl")
include("DESIS.jl")

export AbstractBandset, Landsat8, Landsat7, Sentinel2, DESIS
export red, green, blue, nir, swir1, swir2, bands, wavelengths, wavelength, parse_band, read_bands, read_qa, dn_to_reflectance

end