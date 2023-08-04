function _rasterize(shp, to, fill)
    Rasters.rasterize(last, shp, to=to, fill=fill, verbose=false, progress=false)
end

function _sort_signature(bandset::Type{<:AbstractBandset}, reflectances::Vector{<:Number}, bands::Vector{Symbol})
    sorted = @pipe zip(wavelength.(bandset, bands), reflectances) |> collect |> sort(_, by=first)
    return (first.(sorted), last.(sorted))
end

function _plot_signatures!(ax, bandset::Type{<:AbstractBandset}, sigs::Matrix{<:AbstractFloat}, bands::Vector{Symbol}, labels; colors=wong_colors(), kwargs...)
    # Check Arguments
    (size(sigs, 2) != length(bands)) && ArgumentError("Length of signatures ($(size(sigs, 2))) must be equal to number of bands ($(length(bands)))!")
    (size(sigs, 1) != length(labels)) && ArgumentError("Number of signatures ($(size(sigs, 1))) must be equal to number of labels ($(length(labels)))")

    # Plot Signatures
    for i in 1:size(sigs,1)
        _plot_signature!(ax, bandset, sigs[i,:], bands, label=labels[i]; color=colors[i], kwargs...)
    end
end

function _plot_signature!(ax, bandset::Type{<:AbstractBandset}, signature::Vector{<:AbstractFloat}, bands::Vector{Symbol}; kwargs...)
    # Check Arguments
    (length(signature) != length(bands)) && ArgumentError("Length of signatures ($(length(sigs))) must be equal to number of bands ($(length(bands)))!")

    # Sort Bands In Ascending Order
    x, y = _sort_signature(bandset, signature, bands)

    # Plot Signature
    lines!(ax, x, y; kwargs...)
end