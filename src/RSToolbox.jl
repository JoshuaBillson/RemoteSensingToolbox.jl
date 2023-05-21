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

include("Spectral/Spectral.jl")

using .Spectral

include("visualization.jl")


export AbstractSensor, Landsat8, Landsat7, Sentinel2A, DESIS, BandSet, red, green, blue, nir, swir1, swir2, dn_to_reflectance, dn2rs, asraster
export visualize, TrueColor, ColorInfrared, SWIR, Agriculture, Geology
export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi
export extract_signatures, plot_signatures

end
