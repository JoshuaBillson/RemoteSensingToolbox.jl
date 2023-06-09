module RemoteSensingToolbox

import Images
import CairoMakie
using Rasters
using Statistics
using DocStringExtensions
using StructArrays
using Pipe: @pipe

include("utils.jl")

include("skipmissing.jl")

include("Sensors/Sensors.jl")

using .Sensors

include("Algorithms/Algorithms.jl")

using .Algorithms

include("Preprocessing/Preprocessing.jl")

using .Preprocessing

include("Spectral/Spectral.jl")

using .Spectral

include("visualization.jl")


export AbstractSensor, Landsat8, Landsat7, Sentinel2A, DESIS, BandSet, red, green, blue, nir, swir1, swir2, dn2rs, asraster
export visualize, TrueColor, ColorInfrared, SWIR, Agriculture, Geology
export mndwi, ndwi, ndvi, savi, ndmi, nbri, ndbi
export extract_signatures, plot_signatures, plot_signatures!
export tocube, dn_to_reflectance, create_tiles, mask_pixels, landsat_qa

end
