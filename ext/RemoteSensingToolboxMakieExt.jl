module RemoteSensingToolboxMakieExt

using RemoteSensingToolbox, CairoMakie, DataFrames
using Pipe: @pipe
import Tables

const RST = RemoteSensingToolbox

function RST.plot_signatures(satellite::Type{<:AbstractSatellite}, sigs; kwargs...)
    # Construct Bandset
    bandset = [b => w for (b, w) in zip(bands(satellite), wavelengths(satellite))]

    # Plot Signatures
    RST.plot_signatures(bandset, sigs; kwargs...)
end

function RST.plot_signatures(bandset::Vector{Pair{Symbol, Int}}, sigs; kwargs...)
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
    RST.plot_signatures!(ax, bandset, sigs; kwargs...)

    # Add Legend
    Legend(fig[1,2], ax, "Classification")

    # Return Figure
    return fig
end

function RST.plot_signatures!(ax, satellite::Type{<:AbstractSatellite}, sigs; kwargs...)
    # Construct Bandset
    bandset = [b => w for (b, w) in zip(bands(satellite), wavelengths(satellite))]

    # Plot Signatures
    RST.plot_signatures!(ax, bandset, sigs; kwargs...)
end

function RST.plot_signatures!(ax, bandset::Vector{Pair{Symbol, Int}}, sigs; colors=Makie.wong_colors(), label=:label)
    # Extract Signatures
    x, y = _sigs_to_xy(bandset, sigs)

    # Plot Signatures
    series!(ax, x, y, color=colors, labels=Tables.getcolumn(sigs, label))
end

function _sigs_to_xy(bandset::Vector{<:Pair}, sigs)
    return _sigs_to_xy(bandset, DataFrame(sigs))
end

function _sigs_to_xy(bandset::Vector{<:Pair}, sigs::DataFrame)
    bands = map(first, bandset)
    columns = Tables.columnnames(sigs)
    x = [wavelength for (band, wavelength) in bandset if band in columns]
    y = reduce(hcat, Vector(sigs[:,band]) for band in bands if band in columns)
    return x, y
end
end