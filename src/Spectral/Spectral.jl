module Spectral

using Rasters
using DocStringExtensions
using DataFrames
using Statistics
using Logging
using Pipe: @pipe

import CairoMakie: Figure, Axis, lines!, Legend, save, Makie.wong_colors, cgrad
import RemoteSensingToolbox: align_rasters, efficient_read, _raster_to_df
import ..Bandsets: AbstractBandset, wavelength, bands, wavelengths

include("utils.jl")
include("analysis.jl")

export extract_signatures, summarize_signatures, plot_signatures, plot_signatures!

end