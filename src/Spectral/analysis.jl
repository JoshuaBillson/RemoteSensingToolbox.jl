"""
    extract_signatures(stack::AbstractRasterStack, shp, label::Symbol; label_name=nothing)

Extract signatures from the given `RasterStack` or `AbstractSensor` within regions specified by a given shapefile.

# Parameters
- `stack`: The `RasterStack` from which to extract spectral signatures.
- `shp`: A `Tables.jl` compatible object containing a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `label`: The column in `shp` in which the land cover class is stored.

# Returns
A `DataFrame` consisting of rows for each extracted signature and columns storing the respective bands and land cover type.

# Example
```julia-repl
julia> landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)

julia> shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

julia> extract_signatures(landsat, shp, :C_name)
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
function extract_signatures(stack::AbstractRasterStack, shp, label::Symbol)
    # Prepare Labels
    labels = shp[:,label]
    fill_to_label = Set(labels) |> enumerate |> Dict
    label_to_fill = Set(labels) |> enumerate .|> reverse |> Dict

    # Crop Raster To Extent Of Labels
    stack = map(x -> Rasters.crop(x, to=shp), stack)

    # Rasterize Labels
    fill_vals = [label_to_fill[label] for label in labels]
    labels = rebuild(_rasterize(shp, stack, fill_vals), name=:label)

    # Pair Signatures With Labels
    df = hcat(_raster_to_df(stack), _raster_to_df(labels)) |> dropmissing!

    # Add Label Names
    df.label = [fill_to_label[x] for x in df.label]
    return df
end

"""
    summarize_signatures([reducer], sigs::DataFrame, [label])

Summarize a collection of spectral signatures by grouping according to their land cover type, then reducing each group to a single summary statistic.

# Parameters
- `reducer`: A function that reduces a collection of values to a single statistic (defaults to `mean`).
- `sigs`: A `DataFrame` of signatures, where each row contains the band measurements for a single pixel and the corresponding land cover type.
- `label`: The column in `sigs` which stores the land cover type (default is `:label`).

# Returns
A `DataFrame` consisting of rows for each land cover type's summarized signature.

# Example
```julia-repl
julia> landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)

julia> shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

julia> sigs = extract_signatures(landsat, shp, :C_name)

julia> summarize_signatures(sigs, :label)
7×8 DataFrame
 Row │ label       B1           B2          B3         B4          B5        B6          B7         
     │ String      Float32      Float32     Float32    Float32     Float32   Float32     Float32    
─────┼──────────────────────────────────────────────────────────────────────────────────────────────
   1 │ Hail Scar   0.0617346    0.107954    0.188092   0.247114    0.508847  0.322815    0.173574
   2 │ Bare Earth  0.0483927    0.0539072   0.0773476  0.0883738   0.231219  0.307681    0.199805
   3 │ Road        0.0396956    0.0530674   0.0933762  0.0952315   0.245672  0.205506    0.142639
   4 │ Lake        0.000517442  0.00360272  0.0132789  0.00628491  0.031176  0.00697667  0.00377249
   5 │ Trees       0.0182846    0.0204864   0.0404257  0.0245542   0.319328  0.139772    0.0585171
   6 │ Vegetation  0.00442494   0.015797    0.0789011  0.0464686   0.49601   0.0964562   0.0407997
   7 │ Built Up    0.0892711    0.118764    0.177746   0.200785    0.293111  0.33917     0.304133
```
"""
function summarize_signatures(reducer, sigs::DataFrame, label=:label)
    @pipe DataFrames.groupby(sigs, label) |> DataFrames.combine(_, DataFrames.Not(label) .=> reducer, renamecols=false)
end

function summarize_signatures(sigs::DataFrame, label=:label)
    return summarize_signatures(mean, sigs, label)
end

"""
    plot_signatures(bandset::Type{<:AbstractBandset}, sigs::DataFrame; label=:label, colors=wong_colors())

Plot the spectral signatures for one or more land cover types.

# Parameters
- `bandset`: The sensor type to which the signatures belong.
- `sigs`: A `DataFrame` of signatures with columns corresponding to bands and labels.
- `label`: The column of `sigs` in which the land cover type is stored (default = :label).
- `colors`: The color scheme used by the plot.

# Example
```julia
# Read Landsat And Convert DNs To Reflectance
landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Extract Signatures
sigs = extract_signatures(landsat, shp, :C_name) |> summarize_signatures

# Plot Signatures
plot_signatures(Landsat8, sigs)
```
"""
function plot_signatures(bandset::Type{<:AbstractBandset}, sigs::DataFrame; label=:label, colors=wong_colors())
    # Create Figure
    fig = Figure(resolution=(1000,500))

    # Create Axis
    ax = Axis(
        fig[1,1], 
        xlabel="Wavelength (nm)", 
        ylabel="Reflectance", 
        xlabelfont=:bold, 
        ylabelfont=:bold, 
        xlabelpadding=10.0, 
        ylabelpadding=10.0, 
    )
    
    # Plot Signatures
    plot_signatures!(ax, bandset, sigs; label=label, colors=colors)

    # Add Legend
    Legend(fig[1,2], ax, "Classification")

    # Return Figure
    return fig
end

"""
    plot_signatures!(ax, bandset::Type{<:AbstractBandset}, sigs::DataFrame; label=:label, colors=wong_colors())

Plot spectral signatures for each land cover type specified in a given shapefile by mutating a `Makie.Axis` object.

Accepts the same keywords as `Makie.lines!`.

# Parameters
- `ax`: The `Makie.Axis` into which we want to draw our plot.
- `bandset`: The sensor type to which the signatures belong.
- `sigs`: A `DataFrame` of signatures with columns corresponding to bands and labels.
- `label`: The column of `sigs` in which the land cover type is stored (default = :label).
- `colors`: The color scheme used by the plot.

# Example
```julia
# Read Images And Convert DNs To Reflectance
landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)
sentinel = @pipe read_bands(Sentinel2, "data/T11UPT_20200804T183919/R60m/") |> dn_to_reflectance(Sentinel2, _)

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Extract Signatures
landsat_sigs = extract_signatures(landsat, shp, :MC_name) |> summarize_signatures
sentinel_sigs = extract_signatures(sentinel, shp, :MC_name) |> summarize_signatures

# Create Axes
fig = Figure();
ax1 = Axis(fig[1,1], xlabel="Wavelength (nm)", ylabel="Reflectance", title="Landsat Signatures");
ax2 = Axis(fig[2,1], xlabel="Wavelength (nm)", ylabel="Reflectance", title="Sentinel Signatures");

# Plot Signatures
plot_signatures!(ax1, Landsat8, landsat_sigs; colors=cgrad(:tab10))
plot_signatures!(ax2, Sentinel2, sentinel_sigs; colors=cgrad(:tab10))

# Add Legend
Legend(fig[:,2], ax1)
```
"""
function plot_signatures!(ax, bandset::Type{<:AbstractBandset}, sigs::DataFrame; label=:label, colors=wong_colors())
    sigs_only = sigs[:, Not(label)]
    _plot_signatures!(ax, bandset, Matrix(sigs_only), Symbol.(names(sigs_only)), sigs[:, label]; colors=colors)
end