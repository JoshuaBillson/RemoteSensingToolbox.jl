module RSToolbox

import Images
using Rasters
using Statistics
using DocStringExtensions
using Pipe: @pipe

include("utils.jl")

include("Sensors/Sensors.jl")

using .Sensors

include("Algorithms/Algorithms.jl")

using .Algorithms

include("visualization.jl")


export AbstractSensor, Landsat8, Landsat7, Sentinel2A, red, green, blue, nir, swir1, swir2, dn_to_reflectance
export visualize, TrueColor, ColorInfrared, SWIR, Agriculture, Geology
export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi

end
