"""
    bands(::Type{AbstractBandset})

Return the band names in order from shortest to longest wavelength.
"""
function bands(::Type{T}) where {T <: AbstractBandset}
    error("Error: `bands` not defined for '$(T)'!")
end

"""
    wavelengths(::Type{AbstractBandset})

Return the central wavelengths for all bands in order from shortest to longest.
"""
function wavelengths(::Type{T}) where {T <: AbstractBandset}
    error("Error: `wavelengths` not defined for '$(T)'!")
end

"""
    blue(::Type{AbstractBandset})
    blue(raster, ::Type{AbstractBandset})

Return the blue band for the given sensor.
"""
blue(::Type{T}) where {T <: AbstractBandset} = error("Error: Band 'blue' not defined for $(T)!")

"""
    green(::Type{AbstractBandset})
    green(raster, ::Type{AbstractBandset})

Return the green band for the given sensor.
"""
green(::Type{T}) where {T <: AbstractBandset} = error("Error: Band 'green' not defined for $(T)!")

"""
    red(::Type{AbstractBandset})
    red(raster, ::Type{AbstractBandset})

Return the red band for the given sensor.
"""
red(::Type{T}) where {T <: AbstractBandset} = error("Error: Band 'red' not defined for $(T)!")

"""
    nir(::Type{AbstractBandset})
    nir(raster, ::Type{AbstractBandset})

Return the nir band for the given sensor.
"""
nir(::Type{T}) where {T <: AbstractBandset} = error("Error: Band 'nir' not defined for $(T)!")

"""
    swir1(::Type{AbstractBandset})
    swir1(raster, ::Type{AbstractBandset})

Return the swir1 band for the given sensor.
"""
swir1(::Type{T}) where {T <: AbstractBandset} = error("Error: Band 'swir1' not defined for $(T)!")

"""
    swir2(::Type{AbstractBandset})
    swir2(raster, ::Type{AbstractBandset})

Return the swir2 band for the given sensor.
"""
swir2(::Type{T}) where {T <: AbstractBandset} = error("Error: Band 'swir2' not defined for $(T)!")

"""
    parse_band(::Type{AbstractBandset}, filename::String)

Parses the band name from the given file path. 

Returns either the band as a `Symbol` or nothing if no band could be parsed.

If the file is a multi-band raster, returns the names of all bands as a `Vector{Symbol}`.
"""
function parse_band(::Type{T}, filename::String) where {T <: AbstractBandset}
    reg = "_" * capture(either(string.(bands(T))...), as="band") * "." * ["TIF", "tif", "tiff", "TIFF", "JP2", "jp2"] * END
    m = match(reg, filename)
    return !isnothing(m) ? Symbol(m[:band]) : nothing
end

"""
    read_qa(bandset::Type{AbstractBandSet}, src::String)

Read and decode the quality assurance mask for the given `AbstractBandset`.

# Parameters
- `bandset`: A subtype of `AbstractBandset`.
- `src`: Either a directory containing the quality assurance mask named according to standard conventions or the file itself.

# Returns
The decoded quality assurance mask as a `RasterStack`. Encodes masked values as 1 and non-masked values as 0.

# Example
```julia-repl
julia> qa = read_qa(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/")
RasterStack with dimensions: 
  X Projected{Float64} LinRange{Float64}(493785.0, 728385.0, 7821) ForwardOrdered Regular Points crs: WellKnownText,
  Y Projected{Float64} LinRange{Float64}(5.84638e6, 5.60878e6, 7921) ReverseOrdered Regular Points crs: WellKnownText
and 7 layers:
  :dilated_cloud UInt8 dims: X, Y (7821×7921)
  :cirrus        UInt8 dims: X, Y (7821×7921)
  :cloud         UInt8 dims: X, Y (7821×7921)
  :cloud_shadow  UInt8 dims: X, Y (7821×7921)
  :snow          UInt8 dims: X, Y (7821×7921)
  :clear         UInt8 dims: X, Y (7821×7921)
  :water         UInt8 dims: X, Y (7821×7921)
```
"""
read_qa(::Type{T}, src::String) where {T <: AbstractBandset} = error("Error: 'read_qa' not defined for $(T)!")

"""
    dn_to_reflectance(bandset::Type{AbstractBandset}, raster; clamp_values=false)

Transform the raster from Digital Numbers (DN) to reflectance.

# Parameters
- `bandset`: A subtype of `AbstractBandset`.
- `raster`: The `AbstractRasterStack` or `AbstractRaster` to be converted to reflectance.
- `clamp_values`: Indicates whether to clamp reflectances into the range (0.0, 1.0] (default = false).

# Example
```julia
landsat = read(Landsat8, "LC08_L2SP_043024_20200802_20200914_02_T1/")
landsat_sr = dn_to_reflectance(Landsat8, landsat)
```
"""
function dn_to_reflectance(::Type{T}, raster; clamp_values=false) where {T <: AbstractBandset}
    return _decode_dn(raster, 0.0001f0, 0.0f0; clamp_values=clamp_values)
end