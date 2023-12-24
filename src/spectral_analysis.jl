"""
    function extract_signatures([agg], raster, shp, label::Symbol)

Extract signatures from the given `RasterStack` within regions specified by a provided shapefile.

# Parameters
- `agg`: A function to aggregate signatures belonging to the same class (ex. `mean`, `median`, `maximum`).
- `raster`: An `AbstractRaster` or `AbstractRasterStack` from which to extract the spectral signatures.
- `shp`: A table with a `:geometry` column of `GeoInterface.jl` geometries and a label column indicating the land cover type.
- `label`: The column in `shp` corresponding to the land cover type.

# Returns
A `Tables.columntable` containing all labelled signatures or their aggregation if `agg` is provided.

# Example
```julia
julia> src = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1/");

julia> sr = decode(Landsat8, RasterStack(src, [:B1, :B2, :B3, :B4, :B5]));

julia> shp = GeoDataFrames.read("data/landcover/landcover.shp");

julia> extract_signatures(sr, shp, :C_name) |> DataFrame
1925×6 DataFrame
  Row │ label      B1         B2         B3        B4        B5       
      │ String     Float32    Float32    Float32   Float32   Float32  
──────┼───────────────────────────────────────────────────────────────
    1 │ Hail Scar  0.058005   0.10613    0.19028   0.25177   0.51577
    2 │ Hail Scar  0.057895   0.10888    0.19358   0.257215  0.520198
    3 │ Hail Scar  0.06026    0.111795   0.197265  0.263045  0.523855
    4 │ Hail Scar  0.0595175  0.109375   0.195257  0.258315  0.522287
    5 │ Hail Scar  0.059215   0.108468   0.191655  0.254327  0.51401
  ⋮   │     ⋮          ⋮          ⋮         ⋮         ⋮         ⋮
 1921 │ Built Up   0.0633125  0.0914725  0.145565  0.165227  0.255153
 1922 │ Built Up   0.0764025  0.100878   0.154392  0.176063  0.24363
 1923 │ Built Up   0.09788    0.126342   0.180738  0.19941   0.25958
 1924 │ Built Up   0.0973025  0.133163   0.1894    0.198475  0.278775
 1925 │ Built Up   0.06345    0.089685   0.145042  0.158243  0.272505
                                                     1915 rows omitted

julia> extract_signatures(mean, sr, shp, :C_name) |> DataFrame
7×6 DataFrame
 Row │ label       B1          B2          B3         B4          B5       
     │ String      Float32     Float32     Float32    Float32     Float32  
─────┼─────────────────────────────────────────────────────────────────────
   1 │ Hail Scar   0.0618124   0.107894    0.187857   0.24683     0.507976
   2 │ Bare Earth  0.0484324   0.053983    0.0775185  0.0886341   0.231951
   3 │ Road        0.0400183   0.0534427   0.0938634  0.0958244   0.245025
   4 │ Lake        0.00137886  0.00423271  0.0135606  0.00652965  0.031825
   5 │ Trees       0.0183338   0.0203976   0.0401544  0.024148    0.318622
   6 │ Vegetation  0.00441971  0.0157759   0.0787841  0.0463343   0.495117
   7 │ Built Up    0.0845031   0.113944    0.174032   0.197151    0.283717
```
"""
function extract_signatures(raster::RasterOrStack, shp, label::Symbol)
    # Prepare Labels
    labels = Tables.getcolumn(shp, label)
    bijection = Bijection([label => i for (i, label) in enumerate(Set(labels))])  # Label Mapping

    # Crop Raster To Extent Of Labels
    features = Rasters.crop(raster, to=shp)

    # Rasterize Labels
    fill = [bijection[l] for l in labels]
    label_raster = _rasterize(shp, features, fill)

    # Pair Signatures With Labels
    feature_table = table(features, DataFrame) |> dropmissing!
    label_table = table(label_raster, DataFrame) |> dropmissing!
    joined_table = leftjoin!(label_table, feature_table, on=:geometry) |> dropmissing!
    transform!(joined_table, :label => ByRow(x -> bijection(x)) => :label)

    # Return Signatures
    joined_table[!, Not(:geometry)] |> Tables.columntable
end

function extract_signatures(f::Function, raster::RasterOrStack, shp, label::Symbol)
    sigs = extract_signatures(raster, shp, label) |> DataFrame
    grps = groupby(sigs, :label)
    return DataFrames.combine(grps, valuecols(grps) .=> f, renamecols=false) |> Tables.columntable
end

"""
    plot_signatures(bandset::Type{<:AbstractSatellite}, sigs; kwargs...)
    plot_signatures(bandset::Vector{<:Pair}, sigs; colors=Makie.wong_colors(), label=:label)

Plot the spectral signatures for one or more land cover types.

# Parameters
- `bandset`: An `AbstractSatellite` or a vector of sorted `band => wavelength` pairs.
- `sigs`: A table whose rows consist of spectral signatures and their associated labels.

# Keywords
- `label`: The column in `sigs` containing the signature labels (default = `:label`).
- `colors`: The color scheme used by the plot (default = `Makie.wong_colors()`).

# Example
```julia
julia> src = Landsat8("LC08_L2SP_043024_20200802_20200914_02_T1");

julia> surface_reflectance = decode(Landsat8, RasterStack(src));

julia> shp = GeoDataFrames.read("data/landcover/landcover.shp");

julia> sigs = extract_signatures(mean, surface_reflectance, shp, :MC_name);

julia> plot_signatures(Landsat8, sigs, colors=[:brown, :orange, :blue, :green])
```
"""
function plot_signatures(args...; kwargs...)
    error("`plot_signatures` requires `CairoMakie` to be activated in your environment! Run `import CairoMakie` to fix this problem.")
end

"""
    plot_signatures!(ax, bandset::Type{<:AbstractSatellite}, sigs; kwargs...)
    plot_signatures!(ax, bandset::Vector{<:Pair}, sigs; colors=Makie.wong_colors(), label=:label)

Plot the spectral signatures for one or more land cover types onto an existing `Makie.Axis`.

# Parameters
- `ax`: The `Makie.Axis` onto which to plot the signatures.
- `bandset`: An `AbstractSatellite` or a vector of sorted `band => wavelength` pairs.
- `sigs`: A table whose rows consist of spectral signatures and their associated labels.

# Keywords
- `label`: The column in `sigs` containing the signature labels (default = `:label`).
- `colors`: The color scheme used by the plot (default = `Makie.wong_colors()`).

# Example
```julia
using RemoteSensingToolbox, Rasters, GeoDataFrames, Statistics, CairoMakie

# Read Images And Convert DNs To Reflectance
landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/")
sentinel = Sentinel2{20}("data/T11UPT_20200804T183919/")
landsat_reflectance = decode(Landsat8, RasterStack(landsat))
sentinel_reflectance = decode(Sentinel2, RasterStack(sentinel))

# Read Landcover Labels From Shapefile
shp = GeoDataFrames.read("data/landcover/landcover.shp")

# Extract Average Spectral Signature For Each Landcover Type
landsat_sigs = extract_signatures(mean, landsat_reflectance, shp, :MC_name)
sentinel_sigs = extract_signatures(mean, sentinel_reflectance, shp, :MC_name)

# Create Figure and Axis
fig = Figure(resolution=(800,550));
ax1 = Axis(fig[1,1], ylabel="Reflectance", title="Landsat Signatures")
ax2 = Axis(fig[2,1], xlabel="Wavelength (nm)", ylabel="Reflectance", title="Sentinel Signatures")

# Plot Signatures
plot_signatures!(ax1, Landsat8, landsat_sigs, colors=[:brown, :orange, :blue, :green])
plot_signatures!(ax2, Sentinel2{20}, sentinel_sigs, colors=[:brown, :orange, :blue, :green])

# Add Legend
Legend(fig[:,2], ax1)
```
"""
function plot_signatures!(args...; kwargs...)
    error("`plot_signatures!` requires `CairoMakie` to be activated in your environment! Run `import CairoMakie` to fix this problem.")
end

function _rasterize(shp, to::AbstractRaster, fill)
    to = has_bands(to) ? (@view to[Rasters.Band(1)]) : to
    return Rasters.rasterize(last, shp, to=to, fill=fill, name=:label, verbose=false, progress=false)
end

function _rasterize(shp, to::AbstractRasterStack, fill)
    return Rasters.rasterize(last, shp, to=to, fill=fill, name=:label, verbose=false, progress=false)
end
