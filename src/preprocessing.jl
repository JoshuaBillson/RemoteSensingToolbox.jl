"""
    tocube(rs::RasterStack; layers=names(rs))
    tocube(rs::AbstractBandset; layers=names(rs))

Transform the multi-layer `RasterStack` to a multi-band raster.

# Parameters
- `X`: The `RasterStack` or `AbstractBandset` to be transformed into a multi-band raster.
- `layers`: The layers to include in the new raster.

# Example
```julia-repl
julia> landsat = read_bands(Landsat8, "LC08_L2SP_043024_20200802_20200914_02_T1/");

julia> tocube(landsat)
7821×7921×7 Raster{Float32,3} B1 with dimensions: 
  X Projected{Float64} LinRange{Float64}(493785.0, 728385.0, 7821) ForwardOrdered Regular Points crs: WellKnownText,
  Y Projected{Float64} LinRange{Float64}(5.84638e6, 5.60878e6, 7921) ReverseOrdered Regular Points crs: WellKnownText,
  Band Categorical{Int64} 1:7 ForwardOrdered
extent: Extent(X = (493785.0, 728385.0), Y = (5.608785e6, 5.846385e6), Band = (1, 7))
missingval: 0.0f0
crs: PROJCS["WGS 84 / UTM zone 11N",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",0],PARAMETER["central_meridian",-117],PARAMETER["scale_factor",0.9996],PARAMETER["false_easting",500000],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","32611"]]
parent:
[:, :, 1]
           5.84638e6  5.84636e6  5.84632e6  5.8463e6  5.84626e6  …  5.60894e6  5.6089e6  5.60888e6  5.60884e6  5.60882e6  5.60878e6
 493785.0  0.0        0.0        0.0        0.0       0.0           0.0        0.0       0.0        0.0        0.0        0.0
      ⋮                                               ⋮          ⋱                                             ⋮          
 728355.0  0.0        0.0        0.0        0.0       0.0           0.0        0.0       0.0        0.0        0.0        0.0
 728385.0  0.0        0.0        0.0        0.0       0.0           0.0        0.0       0.0        0.0        0.0        0.0
[and 6 more slices...]
```
"""
function tocube(rs::RasterStack; layers=names(rs))
    cube = cat([rs[l] for l in layers]..., dims=Band)
    band_dim = Band(LookupArrays.Categorical((keys(rs) |> collect .|> string), order=LookupArrays.Unordered()))
    return rebuild(cube; dims=(dims(cube)[1], dims(cube)[2], band_dim))
end

"""
    create_tiles(raster, tile::Tuple{Int,Int}; stride=tile)

Slice the given raster into tiles with size `tile`.

# Parameters
- `raster`: The raster to be cut into tiles.
- `tile`: The size of the generated tiles in terms of width x height.
- `stride`: The distance between the top-left corner of each tile. Is equal to `tile` by default, which produces non-overlapping tiles.
"""
function create_tiles(raster, tile::Tuple{Int,Int}; stride=tile)
    sizex, sizey = tile
    stridex, stridey = stride
    xlim = size(raster,1)
    ylim = size(raster,2)
    [@view raster[X(x:x+sizex-1), Y(y:y+sizey-1)] for y in 1:stridey:ylim-sizey+1 for x in 1:stridex:xlim-sizex+1]
end

"""
    mask_pixels(raster, mask; invert_mask=false)

Drop pixels from a raster according to a given mask. The mask and raster must have the same extent and size.

# Parameters
- `raster`: The raster to be masked.
- `mask`: A mask defining which pixels we want to drop. By default, we drop pixels corresponding to mask values of `1`.
- `invert_mask`: Treat mask values of `1` as `0` and vice-versa.
"""
function mask_pixels(raster::AbstractRaster, mask; invert_mask=false)
    missing_value = invert_mask ? eltype(mask)(0) : eltype(mask)(1)
    return Rasters.mask(raster; with=rebuild(mask; missingval=missing_value))
end

function mask_pixels(raster::AbstractRasterStack, mask; kwargs...)
    return map(x -> mask_pixels(x, mask; kwargs...), raster)
end

"""
    mask_pixels!(raster, mask; invert_mask=false)

Drop pixels from a raster according to a given mask. The mask and raster must have the same extent and size.

# Parameters
- `raster`: The raster to be masked.
- `mask`: A mask defining which pixels we want to drop. By default, we drop pixels corresponding to mask values of `1`.
- `invert_mask`: Treat mask values of `1` as `0` and vice-versa.
"""
function mask_pixels!(raster::AbstractRaster, mask; invert_mask=false)
    missing_value = invert_mask ? eltype(mask)(0) : eltype(mask)(1)
    return Rasters.mask!(raster; with=rebuild(mask; missingval=missing_value))
end

function mask_pixels!(raster::AbstractRasterStack, mask; kwargs...)
    return map(x -> mask_pixels!(x, mask; kwargs...), raster)
end