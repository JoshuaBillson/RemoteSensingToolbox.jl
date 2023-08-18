"""
    extract_signatures(stack::AbstractRasterStack, shp, label::Symbol; drop_missing=true)

Extract signatures from the given `RasterStack` within regions specified by a provided shapefile.

# Parameters
- `stack`: The `RasterStack` from which to extract spectral signatures.
- `shp`: A `Tables.jl` compatible object containing a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `label`: The column in `shp` corresponding to the land cover type.
- `drop_missing`: Drop all rows with at least one missing value in either the bands or labels (default = true).

# Returns
A `RasterTable` consisting of rows for each observed signature and columns storing the respective bands and land cover type.

# Example
```julia-repl
julia> landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)

julia> shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

julia> extract_signatures(landsat, shp, :C_name) |> DataFrame
1925×8 DataFrame
  Row │ B1         B2         B3        B4        B5        B6        B7        label     
      │ Float32    Float32    Float32   Float32   Float32   Float32   Float32   String    
──────┼───────────────────────────────────────────────────────────────────────────────────
    1 │ 0.057235   0.10547    0.188932  0.24847   0.513405  0.315323  0.166107  Hail Scar
    2 │ 0.0574     0.105415   0.188712  0.24946   0.513735  0.317908  0.167593  Hail Scar
    3 │ 0.0584175  0.107175   0.19182   0.253887  0.515577  0.319585  0.168087  Hail Scar
    4 │ 0.0583625  0.10723    0.190995  0.253393  0.514615  0.317715  0.167097  Hail Scar
    5 │ 0.05806    0.10745    0.189895  0.250368  0.50774   0.315048  0.165475  Hail Scar
  ⋮   │     ⋮          ⋮         ⋮         ⋮         ⋮         ⋮         ⋮          ⋮
 1921 │ 0.077145   0.112097   0.17081   0.19677   0.25705   0.320877  0.28015   Built Up
 1922 │ 0.10712    0.136765   0.19666   0.225068  0.268655  0.33284   0.302288  Built Up
 1923 │ 0.0856425  0.123235   0.185853  0.211675  0.273     0.373623  0.351072  Built Up
 1924 │ 0.088145   0.119578   0.17059   0.204442  0.27487   0.355857  0.325553  Built Up
 1925 │ 0.0518725  0.0816275  0.148673  0.15189   0.28774   0.309218  0.29786   Built Up
                                                                         1915 rows omitted
```
"""
function extract_signatures(stack::AbstractRasterStack, shp, label::Symbol; drop_missing=true)
    # Prepare Labels
    labels = Tables.getcolumn(shp, label)
    fill_to_label = Set(labels) |> enumerate |> Dict
    label_to_fill = Set(labels) |> enumerate .|> reverse |> Dict

    # Crop Raster To Extent Of Labels
    stack = drop_missing ? map(x -> Rasters.crop(x, to=shp) |> copy, stack) : stack

    # Rasterize Labels
    fill_vals = [label_to_fill[label] for label in labels]
    labels = rebuild(_rasterize(shp, stack, fill_vals), name=:label)

    # Pair Signatures With Labels
    table = RasterTable(stack, labels)

    # Drop Missing
    table = drop_missing ? dropmissing(table) : table

    # Add Label Names
    return transform_column(x -> fill_to_label[x], table, :label)
end

"""
    plot_signatures(bandset::Type{<:AbstractBandset}, raster::AbstractRasterStack, shp, label::Symbol; colors=wong_colors())

Plot the spectral signatures for one or more land cover types.

# Parameters
- `bandset`: The sensor type to which the signatures belong.
- `raster`: A `RasterStack` from which we want to extract the spectral signatures.
- `shp`: A `Tables.jl` compatible object containing a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `label`: The column in `shp` corresponding to the land cover type.
- `colors`: The color scheme used by the plot.

# Example
```julia
# Read Landsat And Convert DNs To Reflectance
landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Plot Signatures
plot_signatures(Landsat8, landsat, shp, :MC_name)
```
"""
function plot_signatures(args...; kwargs...)
    error("`plot_signatures` requires `CairoMakie` to be activated in your environment! Run `import CairoMakie` to fix this problem.")
end

"""
    plot_signatures!(ax, bandset::Type{<:AbstractBandset}, raster::AbstractRasterStack, shp, label::Symbol; colors=wong_colors())

Plot spectral signatures for each land cover type specified in a given shapefile by mutating a `Makie.Axis` object.

Accepts the same keywords as `Makie.lines!`.

# Parameters
- `ax`: The `Makie.Axis` into which we want to draw our plot.
- `bandset`: The sensor type to which the signatures belong.
- `raster`: A `RasterStack` from which we want to extract the spectral signatures.
- `shp`: A `Tables.jl` compatible object containing a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `label`: The column in `shp` corresponding to the land cover type.
- `colors`: The color scheme used by the plot.

# Example
```julia
# Read Images And Convert DNs To Reflectance
landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)
sentinel = @pipe read_bands(Sentinel2, "data/T11UPT_20200804T183919/R60m/") |> dn_to_reflectance(Sentinel2, _)

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Create Axes
fig = Figure();
ax1 = Axis(fig[1,1], xlabel="Wavelength (nm)", ylabel="Reflectance", title="Landsat Signatures");
ax2 = Axis(fig[2,1], xlabel="Wavelength (nm)", ylabel="Reflectance", title="Sentinel Signatures");

# Plot Signatures
plot_signatures!(ax1, Landsat8, landsat, shp, :MC_name; colors=cgrad(:tab10))
plot_signatures!(ax2, Sentinel2, sentinel, shp, :MC_name; colors=cgrad(:tab10))

# Add Legend
Legend(fig[:,2], ax1)
```
"""
function plot_signatures!(args...; kwargs...)
    error("`plot_signatures!` requires `CairoMakie` to be activated in your environment! Run `import CairoMakie` to fix this problem.")
end