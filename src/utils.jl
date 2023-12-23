function has_bands(raster)
    return any(isa.(dims(raster), Rasters.Band))
end

"Return the number of bands in a raster."
function nbands(raster::AbstractRaster)
    return has_bands(raster) ? size(raster, Rasters.Band) : 1
end

function nbands(raster::AbstractRasterStack)
    return length(raster)
end

"Returns the indices of all non-missing entries in the given `Raster` or `RasterStack`."
function nonmissing(raster::AbstractRaster)
    stack = has_bands(raster) ? RasterStack(raster, layersfrom=Rasters.Band) : RasterStack(raster)
    return nonmissing(stack)
end

function nonmissing(raster::AbstractRasterStack)
    bmasks = map(boolmask, raster)
    bmask = first(bmasks)
    for layer in names(bmasks)[2:end]
        bmask .*= bmasks[layer]
    end
    return [i for (i, x) in enumerate(bmask) if x]
end

"Read a raster from disk into memory. Return immediately if raster has already been read."
function efficient_read(r::Raster)
    return r.data isa Array ? r : read(r)
end

function efficient_read(r::AbstractRasterStack)
    return map(x -> efficient_read(x), r)
end

"""
    mask_nan!(raster)

Replace all `NaN` values with `missingval(raster)` in-place.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` from which we want to drop `NaN` values.
"""
function mask_nan!(raster)
    nan_mask = boolmask(raster, missingval=NaN)
    mask!(raster, with=nan_mask)
end

"""
    table(raster, [sink])

Convert the raster into a table compatible with `Tables.jl`.

Replaces all `missingvals` with `missing`.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` to read into a table.
- `sink`: A `Tables.jl` materializer (default =`Tables.columntable`).

# Example
```julia
julia> src = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1/");

julia> rs = RasterStack(src, [:blue, :green, :red, :nir]);

julia> table(rs, DataFrame) |> dropmissing!
40540174×5 DataFrame
      Row │ geometry               B2      B3      B4      B5     
          │ Tuple…                 UInt16  UInt16  UInt16  UInt16 
──────────┼───────────────────────────────────────────────────────
        1 │ (544335.0, 5.84578e6)    8345    8798    8216   14454
        2 │ (544335.0, 5.84576e6)    8064    8707    8106   15583
        3 │ (544365.0, 5.84576e6)    8247    8858    8135   17552
    ⋮     │           ⋮              ⋮       ⋮       ⋮       ⋮
 40540172 │ (676365.0, 5.60968e6)    8863    9867   10164   16688
 40540173 │ (676395.0, 5.60968e6)    8823    9684   10050   16210
 40540174 │ (676425.0, 5.60968e6)    8934    9898   10324   16947
                                             40540168 rows omitted
```
"""
function table(raster::Union{<:AbstractRaster, <:AbstractRasterStack}, sink=Tables.columntable)
    return @pipe replace_missing(raster) |> 
    efficient_read |> 
    DimTable(_, mergedims=(X,Y)=>:geometry, layersfrom=Rasters.Band) |> 
    sink
end

"""
    sample(raster, [sink]; fraction=0.1)

Randomly sample a percentage of non-missing values from the provided raster.

# Parameters
- `raster`: The `AbstractRaster` or `AbstractRasterStack` from which to sample.
- `sink`: A `Tables.jl` materializer (default =`Tables.columntable`).
- `fraction`: The fraction of values to sample (default = 10%).

# Example
```julia
julia> src = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1/");

julia> rs = RasterStack(src, [:blue, :green, :red, :nir]);

julia> sample(rs, DataFrame)
4054017×4 DataFrame
     Row │ B2      B3      B4      B5     
         │ UInt16  UInt16  UInt16  UInt16 
─────────┼────────────────────────────────
       1 │   7841    9082    8174   24372
       2 │   8117    8977    8372   15577
       3 │  26460   26601   26579   27023
    ⋮    │   ⋮       ⋮       ⋮       ⋮
 4054015 │   7735    8403    7929   18386
 4054016 │   6984    9559   10026   11986
 4054017 │   8036    8658    8328   13896
                      4054011 rows omitted
```
"""
function sample(raster::AbstractRasterStack; fraction=0.1)
    raster = efficient_read(raster)
    rows = nonmissing(raster)
    n = round(Int, length(rows) * fraction)
    i = Random.shuffle!(rows)[1:n]
    return @view raster[i]
end

function sample(raster::AbstractRaster; fraction=0.1)
    if has_bands(raster)
        if nbands(raster) > 25  # RasterStacks With Many Layers Has Poor Compiler Optimization
            df = @pipe table(raster, DataFrame) |> dropmissing! |> _[!, Not(:geometry)]
            indices = Random.randperm(nrow(df))[1:round(Int, nrow(df) * fraction)]
            return (@view df[indices,:]) |> Tables.columntable
        end
        return sample(RasterStack(raster, layersfrom=Rasters.Band); fraction=fraction)
    end
    return sample(RasterStack(raster); fraction=fraction)
end

function sample(raster::Union{<:AbstractRaster, <:AbstractRasterStack}, sink; kwargs...)
    return sample(raster; kwargs...) |> sink
end

function mean(raster::Union{<:AbstractRaster, <:AbstractRasterStack}; fraction=0.1)
    @pipe sample(raster, DataFrame; fraction=fraction) |> 
    Tables.matrix |> 
    Float32.(_) |> 
    Statistics.mean(_, dims=1)
end

function std(raster::Union{<:AbstractRaster, <:AbstractRasterStack})
    return @pipe matrix(raster) |> Statistics.std(_, dims=1)
end

function cov(raster::Union{<:AbstractRaster, <:AbstractRasterStack}; fraction=0.1)
    @pipe sample(raster, DataFrame; fraction=fraction) |> 
    Tables.matrix |> 
    Float64.(_) |> 
    Statistics.cov(_)
end

function cor(raster::Union{<:AbstractRaster, <:AbstractRasterStack}; fraction=0.1)
    @pipe sample(raster, DataFrame; fraction=fraction) |> 
    Tables.matrix |> 
    Float64.(_) |> 
    Statistics.cor(_)
end

function _copy_dims(data::AbstractArray{<:Number,3}, reference::AbstractRaster)
    band_dim = Rasters.Band(LookupArrays.Categorical(1:size(data, 3), order=LookupArrays.ForwardOrdered()))
    ref_dims = (dims(reference, :X), dims(reference, :Y), band_dim)
    return Raster(data; crs=crs(reference), dims=ref_dims)
end

function _copy_dims(data::AbstractArray{<:Number,2}, reference::AbstractRaster)
    ref_dims = (dims(reference, :X), dims(reference, :Y))
    return Raster(data; crs=crs(reference), dims=ref_dims)
end

function _map_index(f::Function, raster::AbstractRasterStack)
    i = 0
    map(raster) do x
        i += 1
        f(i, x)
    end
end