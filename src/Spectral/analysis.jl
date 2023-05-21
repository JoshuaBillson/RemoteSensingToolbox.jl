"""
    extract_signatures(rs::AbstractSensor, shp::DataFrame, label::Symbol)
    extract_signatures(rs::RasterStack, shp::DataFrame, label::Symbol)

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

julia> extract_signatures(landsat, shp, :cover)
3195×8 DataFrame
  Row │ B1          B2         B3         B4         B5        B6         B7         label      
      │ Float32     Float32    Float32    Float32    Float32   Float32    Float32    String     
──────┼─────────────────────────────────────────────────────────────────────────────────────────
    1 │  0.05102    0.0891075  0.156317   0.198558   0.482055  0.267197   0.139103   hail scar
    2 │  0.054815   0.09238    0.16333    0.207742   0.481203  0.270415   0.140973   hail scar
    3 │  0.0561625  0.0942225  0.16564    0.208787   0.477875  0.273082   0.14353    hail scar
    4 │  0.057015   0.0941125  0.16146    0.20425    0.47991   0.271267   0.141715   hail scar
    5 │  0.044695   0.0839375  0.152852   0.193525   0.465198  0.258012   0.133217   hail scar
  ⋮   │     ⋮           ⋮          ⋮          ⋮         ⋮          ⋮          ⋮          ⋮
 3192 │ -0.0024675  0.011475   0.0757425  0.0416975  0.540658  0.0856975  0.035785   vegetation
 3193 │ -0.001945   0.0115575  0.0766225  0.0419725  0.535488  0.08567    0.036005   vegetation
 3194 │ -0.0023025  0.012135   0.0773925  0.0427975  0.523745  0.08556    0.0364175  vegetation
 3195 │ -0.0019725  0.0119425  0.0767875  0.04211    0.523745  0.085065   0.0360325  vegetation
                                                                               3186 rows omitted
```
"""
function extract_signatures(rs::RasterStack, shp::DataFrame, label::Symbol)
    # Extract Signatures
    sigs = with_logger(NullLogger()) do
        Tuple( reduce(hcat, _extract_signatures(rs[layer], shp, row) for layer in keys(rs)) for row in 1:nrow(shp))
    end

    # Construct DataFrame
    cols = [x for x in names(rs)]
    df = DataFrame(vcat(sigs...), cols)
    
    # Add Labels
    labels = reduce(vcat, repeat([shp[i,label]], size(sigs[i], 1)) for i in 1:nrow(shp))
    df.label = labels
    return df
end

function extract_signatures(rs::AbstractSensor, shp::DataFrame, label::Symbol)
    return extract_signatures(rs.stack, shp, label)
end

"""
    plot_signatures(rs::AbstractSensor, shp::DataFrame, dst::String, label=:label)
    plot_signatures(rs::RasterStack, shp::DataFrame, bandset::BandSet, label::Symbol, dst::String)

Plot spectral signatures for each land cover type specified in a given shapefile.

# Parameters
- `rs`: The `RasterStack` or `AbstractSensor` from which to extract spectral signatures.
- `shp`: A shapefile stored as a `DataFrame` with a :geometry column storing a `GeoInterface.jl` compatible geometry and a label column indicating the land cover type.
- `bandset`: The `BandSet` for the provided sensor specifying the available bands and associated wavelengths in nm. Inferred for `AbstractSensor`.
- `label`: The column in `shp` in which the land cover class is stored.
- `dst`: The destination at which to save the plot. Supports all file extensions supported by `CairoMakie`.

# Example
```julia
# Read Landsat And Convert DNs To Reflectance
landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance

# Load Shapefile
shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

# Plot Signatures
plot_signatures(landsat, shp, :cover, "landsat_sigs.png")
```
"""
function plot_signatures(rs::RasterStack, shp::DataFrame, bandset::BandSet, label::Symbol, dst::String)
    # Extract Signatures
    sigs = extract_signatures(rs, shp, label)

    # Average Bands For Each Land Cover Type
    df = summarize_signatures(mean, sigs, :label)

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
    x = @pipe sigs[:,Not(:label)] |> names |> [bandset(b) for b in _]
    for i in 1:DataFrames.nrow(df)
        lines!(ax, x, df[i,Not(:label)] |> Vector, label=df[i,:label])
    end

    # Add Legend
    Legend(fig[1,2], ax, "Classification")

    # Save Plot
    save(dst, fig)
end

function plot_signatures(rs::T, shp::DataFrame, label::Symbol, dst::String) where {T <: AbstractSensor}
    plot_signatures(rs.stack, shp, BandSet(T), label, dst)
end

function summarize_signatures(f, sigs::DataFrame, label::Symbol)
    @pipe DataFrames.groupby(sigs, label) |> DataFrames.combine(_, DataFrames.Not(label) .=> f)
end

_extract_signatures(layer, shp, row) = [x[2] for x in extract(layer, shp[row,:geometry])]