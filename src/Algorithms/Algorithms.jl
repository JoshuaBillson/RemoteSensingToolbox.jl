module Algorithms

using Rasters
using DocStringExtensions
using Pipe: @pipe

import RemoteSensingToolbox: align_rasters, efficient_read
import ..Sensors: AbstractSensor, blue, green, red, nir, swir1, swir2

include("indices.jl")

export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi

end