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

function summarize_signatures(f, sigs::DataFrame, label::Symbol=:label)
    band_columns = @pipe DataFrames.names(sigs) |> filter(x -> x != string(label), _)
    @pipe DataFrames.groupby(sigs, label) |> DataFrames.combine(_, band_columns .=> f)
end

function plot_signatures(sigs::DataFrame, bandset::BandSet, dst::String, label=:label)
    # Average Bands For Each Land Cover Type
    df = summarize_signatures(mean, sigs, label)

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
        lines!(ax, x, df[i,Not(label)] |> Vector, label=df[i,label])
    end

    # Add Legend
    Legend(fig[1,2], ax, "Classification")

    # Save Plot
    save(dst, fig)
end

function plot_signatures(rs::T, shp::DataFrame, dst::String, label=:label) where {T <: AbstractSensor}
    plot_signatures(extract_signatures(rs, shp, label), BandSet(T), dst)
end

_extract_signatures(layer, shp, row) = [x[2] for x in extract(layer, shp[row,:geometry])]