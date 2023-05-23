module Spectral

using Rasters
using DocStringExtensions
using DataFrames
using Statistics
using Logging
using Pipe: @pipe

import CairoMakie: Figure, Axis, lines!, Legend, save
import RemoteSensingToolbox: align_rasters, efficient_read
import ..Sensors: AbstractSensor, BandSet, Landsat8

include("analysis.jl")

export extract_signatures, plot_signatures

end