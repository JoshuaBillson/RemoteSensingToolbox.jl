module Spectral

using Rasters
using DocStringExtensions
using DataFrames
using Statistics
using Logging
using Pipe: @pipe

import CairoMakie: Figure, Axis, lines!, Legend, save, Makie.wong_colors, cgrad
import RemoteSensingToolbox: align_rasters, efficient_read
import ..Sensors: AbstractSensor, BandSet, Landsat8

include("utils.jl")
include("analysis.jl")

export extract_signatures, plot_signatures, plot_signatures!

end