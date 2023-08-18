module Spectral

import Tables
using Rasters
using DocStringExtensions
using Statistics
using Logging
using LinearAlgebra
using Pipe: @pipe

import RemoteSensingToolbox: align_rasters, efficient_read, RasterTable, transform_column, dropmissing, fold_rows
import ..Bandsets: AbstractBandset, wavelength, bands, wavelengths

include("utils.jl")
include("distances.jl")
include("analysis.jl")

export extract_signatures, plot_signatures, plot_signatures!

end