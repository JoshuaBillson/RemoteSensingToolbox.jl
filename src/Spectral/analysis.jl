"""
    labelled_signatures(rs::AbstractSensor, shp::DataFrame, label::Symbol)
    labelled_signatures(rs::RasterStack, shp::DataFrame, label::Symbol)

Extract signatures from the given `RasterStack` or `AbstractSensor` within regions specified by a given shapefile.

# Parameters
- `rs`: The `RasterStack` or `AbstractSensor` from which to extract spectral signatures.
- `shp`: A shapefile stored as a `DataFrame` with a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `label`: The column in `shp` in which the land cover class is stored.

# Returns
A `DataFrame` consisting of rows for each extracted signature and columns storing the respective bands and land cover type.

# Example
```julia-repl
julia> landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance;

julia> shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame;

julia> labelled_signatures(landsat, shp, :cover)
2860×8 DataFrame
  Row │ B1         B2         B3         B4         B5        B6        B7        label      
      │ Float32    Float32    Float32    Float32    Float32   Float32   Float32   String     
──────┼──────────────────────────────────────────────────────────────────────────────────────
    1 │ 0.0514875  0.073845   0.119742   0.128817   0.2466    0.256005  0.221905  Built Up
    2 │ 0.0759625  0.10228    0.152963   0.170865   0.27575   0.300115  0.26387   Built Up
    3 │ 0.113747   0.134263   0.212747   0.237497   0.32756   0.32041   0.28851   Built Up
    4 │ 0.09359    0.117955   0.18522    0.19743    0.302453  0.3148    0.277125  Built Up
    5 │ 0.0793725  0.104507   0.133658   0.1377     0.311555  0.2873    0.23824   Built Up
    6 │ 0.0641375  0.086      0.11724    0.115315   0.353272  0.291755  0.221878  Built Up
    7 │ 0.240688   0.271735   0.254245   0.299648   0.376895  0.500067  0.460797  Built Up
    8 │ 0.06554    0.0865225  0.14265    0.16245    0.272478  0.283697  0.238515  Built Up
    9 │ 0.0979625  0.131732   0.190747   0.230402   0.312793  0.369112  0.327148  Built Up
  ⋮   │     ⋮          ⋮          ⋮          ⋮         ⋮         ⋮         ⋮          ⋮
 2853 │ 0.0355925  0.0422475  0.0688675  0.0711225  0.24385   0.287245  0.180792  Bare Earth
 2854 │ 0.0494525  0.05674    0.0867975  0.09612    0.277703  0.311665  0.192728  Bare Earth
 2855 │ 0.0473075  0.053      0.0815725  0.0860825  0.264998  0.291672  0.183075  Bare Earth
 2856 │ 0.04673    0.05267    0.08039    0.083195   0.25716   0.285787  0.184175  Bare Earth
 2857 │ 0.0465925  0.05289    0.0809675  0.0854225  0.268627  0.299345  0.189565  Bare Earth
 2858 │ 0.0471975  0.052835   0.08094    0.0856975  0.266097  0.302783  0.189097  Bare Earth
 2859 │ 0.0453275  0.050745   0.075055   0.0795925  0.247095  0.293323  0.185962  Bare Earth
 2860 │ 0.036335   0.0434025  0.06884    0.070985   0.2422    0.282845  0.179995  Bare Earth
                                                                            2843 rows omitted
```
"""
function labelled_signatures(rs::RasterStack, shp::DataFrame, label::Symbol)
    # Extract Signatures
    sigs = with_logger(NullLogger()) do
        [_extract_signatures(rs, shp, row) for row in 1:nrow(shp)]
    end

    # Create DataFrame
    df = reduce(vcat, sigs)

    # Add Labels
    labels = reduce(vcat, repeat([shp[i,label]], nrow(sigs[i])) for i in 1:nrow(shp))
    df.label = labels
    return df
end

function labelled_signatures(rs::AbstractSensor, shp::DataFrame, label::Symbol)
    return labelled_signatures(rs.stack, shp, label)
end

"""
    plot_signatures(rs::AbstractSensor, shp::DataFrame, label::Symbol; colors=wong_colors())
    plot_signatures(rs::RasterStack, shp::DataFrame, bandset::BandSet, label::Symbol; colors=wong_colors())

Plot spectral signatures for each land cover type specified in a given shapefile.

# Parameters
- `rs`: The `RasterStack` or `AbstractSensor` from which to extract spectral signatures.
- `shp`: A shapefile stored as a `DataFrame` with a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `bandset`: The `BandSet` for the provided sensor specifying the available bands and associated wavelengths in nm. Inferred for `AbstractSensor`.
- `label`: The column in `shp` in which the land cover class is stored.
- `colors`: The color scheme used by the plot.

# Example
```julia
# Read Landsat And Convert DNs To Reflectance
landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Plot Signatures
plot_signatures(landsat, shp, :C_name; colors=cgrad(:tab10))
```
"""
function plot_signatures(rs::RasterStack, shp::DataFrame, bandset::BandSet, label::Symbol; colors=wong_colors())
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
    plot_signatures!(ax, rs, shp, bandset, label; colors=colors)

    # Add Legend
    Legend(fig[1,2], ax, "Classification")

    # Return Figure
    return fig
end

function plot_signatures(rs::T, shp::DataFrame, label::Symbol; colors=wong_colors()) where {T <: AbstractSensor}
    plot_signatures(rs.stack, shp, BandSet(T), label; colors=colors)
end

"""
    plot_signatures!(ax::Axis, rs::AbstractSensor, shp::DataFrame, label::Symbol; colors=wong_colors())
    plot_signatures!(ax::Axis, rs::RasterStack, shp::DataFrame, bandset::BandSet, label::Symbol; colors=wong_colors())

Plot spectral signatures for each land cover type specified in a given shapefile by mutating a `Makie.Axis` object.

# Parameters
- `ax`: The `Makie.Axis` into which we want to draw our plot.
- `rs`: The `RasterStack` or `AbstractSensor` from which to extract spectral signatures.
- `shp`: A shapefile stored as a `DataFrame` with a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `bandset`: The `BandSet` for the provided sensor specifying the available bands and associated wavelengths in nm. Inferred for `AbstractSensor`.
- `label`: The column in `shp` in which the land cover class is stored.
- `colors`: The color scheme used by the plot.

# Example
```julia
# Read Landsat And Convert DNs To Reflectance
landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Create Axes
fig = Figure();
ax1 = Axis(fig[1,1]);
ax2 = Axis(fig[2,1]);

# Plot Signatures
plot_signatures!(ax1, landsat, shp, :C_name; colors=cgrad(:tab10));
plot_signatures!(ax2, landsat, shp, :MC_name; colors=cgrad(:tab10));

# Add Legend
Legend(fig[1,2], ax1);
Legend(fig[2,2], ax2);

# Save Figure
save("landsat_signatures.png", fig)
```
"""
function plot_signatures!(ax::Axis, rs::RasterStack, shp::DataFrame, bandset::BandSet, label::Symbol; colors=wong_colors())
    # Extract Signatures
    sigs = labelled_signatures(rs, shp, label)

    # Average Bands For Each Land Cover Type
    df = _summarize_signatures(mean, sigs, :label)

    # Plot Signatures
    x = @pipe sigs[:,Not(:label)] |> names |> [bandset(b) for b in _]
    for i in 1:DataFrames.nrow(df)
        lines!(ax, x, df[i,Not(:label)] |> Vector, label=df[i,:label], color=colors[i])
    end

    return ax
end

function plot_signatures!(ax::Axis, rs::T, shp::DataFrame, label::Symbol; colors=wong_colors()) where {T <: AbstractSensor}
    plot_signatures!(ax, rs.stack, shp, BandSet(T), label; colors=colors)
end