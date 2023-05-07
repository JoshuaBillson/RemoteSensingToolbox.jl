module Sensors

using Rasters
using DocStringExtensions
using Pipe: @pipe

import RSToolbox: align_rasters, efficient_read

abstract type AbstractSensor end

blue(X::AbstractSensor) = error("Error: Band 'blue' not defined for $(typeof(X))!")

green(X::AbstractSensor) = error("Error: Band 'green' not defined for $(typeof(X))!")

red(X::AbstractSensor) = error("Error: Band 'red' not defined for $(typeof(X))!")

nir(X::AbstractSensor) = error("Error: Band 'nir' not defined for $(typeof(X))!")

swir1(X::AbstractSensor) = error("Error: Band 'swir1' not defined for $(typeof(X))!")

swir2(X::AbstractSensor) = error("Error: Band 'swir2' not defined for $(typeof(X))!")

include("landsat8.jl")
include("landsat7.jl")
include("sentinel2a.jl")

export AbstractSensor, Landsat8, Landsat7, Sentinel2A, red, green, blue, nir, swir1, swir2

end