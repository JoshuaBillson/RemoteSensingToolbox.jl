module RSToolbox

import Images
using Rasters
using Statistics
using DocStringExtensions
using Pipe: @pipe

include("utils.jl")

include("Sensors/Sensors.jl")

using .Sensors

include("visualization.jl")


export AbstractSensor, Landsat8, Landsat7, Sentinel2A, red, green, blue, nir, swir1, swir2
export visualize, TrueColor, ColorInfrared, SWIR, Agriculture, Geology

end
