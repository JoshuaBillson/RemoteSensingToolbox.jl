module RemoteSensingToolboxMakieExt

using RemoteSensingToolbox, CairoMakie, Rasters, Statistics
using Pipe: @pipe
import Tables

function RemoteSensingToolbox.plot_signatures(bandset::Type{<:AbstractBandset}, raster::AbstractRasterStack, shp, label::Symbol; colors=Makie.wong_colors())
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
    RemoteSensingToolbox.plot_signatures!(ax, bandset, raster, shp, label; colors=colors)

    # Add Legend
    Legend(fig[1,2], ax, "Classification")

    # Return Figure
    return fig
end

function RemoteSensingToolbox.plot_signatures!(ax, bandset::Type{<:AbstractBandset}, raster::AbstractRasterStack, shp, label::Symbol; colors=Makie.wong_colors())
    # Extract Signatures
    extracted = @pipe RemoteSensingToolbox.extract_signatures(raster, shp, label) |> RemoteSensingToolbox.fold_rows(mean, _, :label)

    # Plot Signatures
    RemoteSensingToolbox.plot_signatures!(ax, bandset, extracted, :label, colors)
end

function RemoteSensingToolbox.plot_signatures!(ax, bandset::Type{<:AbstractBandset}, sigs, labelcolumn::Symbol, colors)
    # Extract Signatures
    cols = Tables.columnnames(sigs)
    bs = filter(x -> x in cols, bands(bandset))
    sig_matrix = hcat([Tables.getcolumn(sigs, b) for b in bs]...)

    # Plot Signatures
    xs = [wavelength(bandset, b) for b in bs]
    labels = Tables.getcolumn(sigs, labelcolumn)
    for i in 1:size(sig_matrix,1)
        lines!(ax, xs, sig_matrix[i,:], label=labels[i]; color=colors[i])
    end
end

end